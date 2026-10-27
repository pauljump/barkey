import UIKit
import os
import KeyboardKit
import BARkeyEngine

/// Debug trail in the extension's own temp folder (readable from the simulator's data container).
enum KeyboardDebug {
    static func log(_ line: String) {
        #if DEBUG
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("barkey-debug.log")
        let data = Data((Date().formatted(date: .omitted, time: .standard) + " " + line + "\n").utf8)
        if let h = try? FileHandle(forWritingTo: url) { h.seekToEndOfFile(); h.write(data); try? h.close() } else { try? data.write(to: url) }
        let d = UserDefaults(suiteName: "group.com.barkey.app")
        var lines = d?.stringArray(forKey: "kb_debug") ?? []
        lines.append(line); if lines.count > 300 { lines.removeFirst(lines.count - 300) }
        d?.set(lines, forKey: "kb_debug")
        #endif
    }
}

class KeyboardViewController: KeyboardInputViewController {

    /// Text in the current field at the last poll.
    private var lastKnownText = ""

    /// Which text field the last poll saw. A new field means the old draft was
    /// abandoned, not sent.
    private var lastDocumentId: UUID?

    /// When the person last pressed backspace. A field that empties right after
    /// backspacing was cleared by hand, not sent.
    fileprivate var lastBackspaceAt = Date.distantPast

    /// Timer that polls the text proxy to detect sent messages.
    private var pollTimer: Timer?

    fileprivate let autocomplete = BARkeyAutocompleteService()

    override func viewDidLoad() {
        super.viewDidLoad()
        KeyboardDebug.log("viewDidLoad")
        setupKeyboardKit(for: .barkey) { [weak self] result in
            guard let self else { return }
            KeyboardDebug.log("setup completion \(result)")
            self.services.autocompleteService = self.autocomplete
            self.services.actionHandler = BARkeyActionHandler(controller: self)
            self.applyFeelSettings()
        }
    }

    /// The parts of Apple's keyboard people notice: pop-ups, haptics, sentence caps, double-space period,
    /// hold-space to move the cursor, and corrections applied as you go.
    private func applyFeelSettings() {
        let keyboard = state.keyboardContext.settings
        keyboard.isAutocapitalizationEnabled = true
        keyboard.isPeriodShortcutEnabled = true
        keyboard.isCharacterPreviewEnabled = true
        keyboard.spacebarLongPressBehavior = .moveInputCursor
        keyboard.isUndoManagerEnabled = false

        let autocompleteSettings = state.autocompleteContext.settings
        autocompleteSettings.isAutocompleteEnabled = true
        autocompleteSettings.isAutocorrectEnabled = true
        autocompleteSettings.isNextWordPredictionEnabled = false // predictions come from BARkey's own corrector
        autocompleteSettings.isEmojiAutocompleteEnabled = false

        let feedback = state.feedbackContext.settings
        if !UserDefaults.standard.bool(forKey: "barkey_feedback_defaults_applied") {
            feedback.isHapticFeedbackEnabled = true
            feedback.isAudioFeedbackEnabled = true
            UserDefaults.standard.set(true, forKey: "barkey_feedback_defaults_applied")
        }
    }

    override func viewWillSetupKeyboardView() {
        KeyboardDebug.log("viewWillSetupKeyboardView handler=\(type(of: services.actionHandler)) service=\(type(of: services.autocompleteService))")
        super.viewWillSetupKeyboardView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Whatever is already in the field was not typed in this session.
        lastKnownText = currentFieldText()
        lastDocumentId = textDocumentProxy.documentIdentifier
        startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPolling()
        lastKnownText = ""
    }

    // MARK: - Message capture

    private func startPolling() {
        pollTimer?.invalidate()
        pollTimer = Timer.scheduledTimer(withTimeInterval: 0.3, repeats: true) { [weak self] _ in
            self?.checkProxy()
        }
    }

    private func stopPolling() {
        pollTimer?.invalidate()
        pollTimer = nil
    }

    private func currentFieldText() -> String {
        let before = textDocumentProxy.documentContextBeforeInput ?? ""
        let after = textDocumentProxy.documentContextAfterInput ?? ""
        return before + after
    }

    /// A message counts as sent when a field we are typing in goes from text to
    /// empty without the person deleting it, in the same field.
    private func checkProxy() {
        let documentId = textDocumentProxy.documentIdentifier
        let currentText = currentFieldText()

        if documentId != lastDocumentId {
            lastDocumentId = documentId
            lastKnownText = currentText
            return
        }

        if currentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            let message = lastKnownText
            lastKnownText = ""
            let clearedByHand = Date().timeIntervalSince(lastBackspaceAt) < 1.0
            guard !message.isEmpty, !clearedByHand, shouldCapture() else { return }
            if MessageStore.appendMessage(message) {
                // The person's own words feed the corrector right away.
                autocomplete.corrector.personal.add(message: message)
                autocomplete.corrector.invalidate()
            }
        } else {
            lastKnownText = currentText
        }
    }

    /// Only conversational text fields. Never search bars, address bars,
    /// logins, codes, card numbers or addresses.
    private func shouldCapture() -> Bool {
        guard hasFullAccess, !CaptureSettings.isPaused else { return false }
        let proxy = textDocumentProxy

        let skippedKeyboards: Set<UIKeyboardType> = [
            .URL, .emailAddress, .webSearch, .numberPad, .phonePad, .decimalPad,
            .numbersAndPunctuation, .namePhonePad, .asciiCapableNumberPad,
        ]
        if let type = proxy.keyboardType, skippedKeyboards.contains(type) { return false }

        let skippedReturnKeys: Set<UIReturnKeyType> = [.search, .google, .yahoo, .go, .route, .join, .emergencyCall]
        if let key = proxy.returnKeyType, skippedReturnKeys.contains(key) { return false }

        if let content = proxy.textContentType ?? nil {
            let skippedContent: Set<UITextContentType> = [
                .username, .password, .newPassword, .oneTimeCode, .emailAddress, .URL,
                .telephoneNumber, .creditCardNumber, .fullStreetAddress, .streetAddressLine1,
                .streetAddressLine2, .postalCode, .addressCity, .addressState, .location,
                .name, .givenName, .familyName, .nickname, .organizationName,
            ]
            if skippedContent.contains(content) { return false }
        }
        return true
    }
}

/// Apple's two autocorrect manners, on top of KeyboardKit's: backspace right after a correction puts the typed word
/// back (and the keyboard stops correcting it), and tapping the typed word in the bar teaches it too. Also notes
/// backspace presses so a field emptied by hand is not taken as sent.
private final class BARkeyActionHandler: StandardKeyboardActionHandler {
    weak var barkeyController: KeyboardViewController?

    private let log = Logger(subsystem: "com.barkey.keyboard", category: "actions")
    private func debugLog(_ line: String) { KeyboardDebug.log(line) }

    /// The last correction applied: what was typed, what replaced it, and the character that triggered it.
    private var lastCorrection: (typed: String, corrected: String, trigger: String)?

    convenience init(controller: KeyboardViewController) {
        self.init(controller: controller as any KeyboardController)
        barkeyController = controller
    }

    override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction) {
        debugLog("handle \(gesture) \(action) word=\(keyboardContext.textDocumentProxy.currentWordPreCursorPart ?? "nil") before=\(barkeyController?.textDocumentProxy.documentContextBeforeInput ?? "nil") ac=\(autocompleteContext.suggestions.map { "\($0.text):\($0.type)" }) last=\(lastCorrection.map { "\($0.typed)>\($0.corrected)" } ?? "nil")")
        if case .space = action, gesture == .release, expandVoiceShortcut() { return }
        if case .backspace = action, gesture == .press || gesture == .repeatPress {
            barkeyController?.lastBackspaceAt = Date()
            if gesture == .press, revertLastCorrection() { return }
        }
        if case .character = action { /* a new word is under way; the old correction stands */ } else if case .space = action {} else {
            if case .backspace = action {} else { lastCorrection = nil }
        }
        super.handle(gesture, on: action)
    }

    override func handle(_ suggestion: AutocompleteSuggestion) {
        // Choosing the typed word over a correction teaches the keyboard that word.
        if suggestion.isRegular, let typed = keyboardContext.textDocumentProxy.currentWordPreCursorPart,
           suggestion.text == typed, autocompleteContext.suggestions.contains(where: \.isAutocorrect) {
            barkeyController?.autocomplete.learnWord(typed)
        }
        super.handle(suggestion)
    }

    /// Applies the correction at the moment the space or punctuation is typed, computed right now from the text,
    /// so a fast thumb never outruns the suggestion bar. Falls back to KeyboardKit's own path otherwise.
    override func tryApplyAutocorrectSuggestion(before gesture: Keyboard.Gesture, on action: KeyboardAction) {
        guard gesture == .release, let trigger = action.triggerText, autocompleteContext.settings.isAutocorrectEnabled,
              let corrector = barkeyController?.autocomplete.corrector else {
            return super.tryApplyAutocorrectSuggestion(before: gesture, on: action)
        }
        let proxy = keyboardContext.textDocumentProxy
        guard let typed = proxy.currentWordPreCursorPart, !typed.isEmpty, proxy.currentWordPostCursorPart?.isEmpty ?? true else {
            return super.tryApplyAutocorrectSuggestion(before: gesture, on: action)
        }
        let before = proxy.documentContextBeforeInput ?? ""
        let fix = corrector.suggestions(for: before).autocorrect
        debugLog("space-fix typed=\(typed) fix=\(fix ?? "nil")")
        guard let fix, fix != typed else { return }
        proxy.replaceCurrentWordPreCursorPart(with: fix)
        lastCorrection = (typed, fix, trigger)
    }

    /// "myvoice" + space, in any app, becomes the short voice brief (so Dot, Muse or anyone writes like you).
    private func expandVoiceShortcut() -> Bool {
        guard VoiceBrief.isEnabled, let brief = VoiceBrief.brief, let proxy = barkeyController?.textDocumentProxy,
              let word = proxy.currentWordPreCursorPart, word.lowercased() == VoiceBrief.shortcut else { return false }
        for _ in 0..<word.count { proxy.deleteBackward() }
        proxy.insertText(brief + "\n\n")
        lastCorrection = nil
        return true
    }

    /// If the text before the cursor ends with the last correction plus its trigger, put the typed word back.
    private func revertLastCorrection() -> Bool {
        guard let last = lastCorrection, let proxy = barkeyController?.textDocumentProxy else { return false }
        lastCorrection = nil
        let tail = last.corrected + last.trigger
        guard let before = proxy.documentContextBeforeInput, before.hasSuffix(tail) else { return false }
        for _ in 0..<tail.count { proxy.deleteBackward() }
        proxy.insertText(last.typed + last.trigger)
        barkeyController?.autocomplete.learnWord(last.typed)
        return true
    }
}

private extension KeyboardAction {
    /// The text a space or end-of-word punctuation key inserts, when it is one. Letters are not triggers.
    var triggerText: String? {
        switch self {
        case .space: return " "
        case .character(let c) where c.count == 1 && ".,!?;:)\n".contains(c): return c
        case .primary: return "\n"
        default: return nil
        }
    }
}
