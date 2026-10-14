import UIKit
import KeyboardKit

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

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardKit(for: .barkey) { [weak self] _ in
            guard let self else { return }
            let autocomplete = AppleAutocompleteService()
            self.services.autocompleteService = autocomplete
            self.services.actionHandler = BARkeyActionHandler(controller: self)
        }
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
            MessageStore.appendMessage(message)
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

/// Notes backspace presses so a field emptied by hand is not taken as sent.
private final class BARkeyActionHandler: KeyboardAction.StandardActionHandler {
    weak var barkeyController: KeyboardViewController?

    convenience init(controller: KeyboardViewController) {
        self.init(controller: controller as any KeyboardController)
        barkeyController = controller
    }

    override func handle(_ gesture: Keyboard.Gesture, on action: KeyboardAction) {
        if case .backspace = action {
            barkeyController?.lastBackspaceAt = Date()
        }
        super.handle(gesture, on: action)
    }
}
