import UIKit
import KeyboardKit

class KeyboardViewController: KeyboardInputViewController {

    /// Last non-empty text we saw in the text field.
    private var lastKnownText = ""

    /// Timer that polls the text proxy to detect sent messages.
    private var pollTimer: Timer?

    /// Track previous text length to detect space presses.
    private var previousTextLength = 0

    private let inlineChecker = UITextChecker()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupKeyboardKit(for: .barkey) { [weak self] _ in
            guard let self else { return }
            self.services.autocompleteService = AppleAutocompleteService()
        }
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startPolling()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopPolling()
    }

    // MARK: - Text change observation

    override func textDidChange(_ textInput: (any UITextInput)?) {
        super.textDidChange(textInput)

        let currentText = textDocumentProxy.documentContextBeforeInput ?? ""

        // Detect if a space was just typed → retroactively fix previous words
        if currentText.hasSuffix(" ") && currentText.count > previousTextLength {
            fixPreviousWords(in: currentText)
        }

        previousTextLength = currentText.count
    }

    // MARK: - Retroactive word fixing

    /// After each space, check the last 3 completed words for misspellings and fix them.
    private func fixPreviousWords(in text: String) {
        let language = getLanguage()

        // Split into words, keeping track of their ranges in the full text
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard words.count >= 1 else { return }

        // Check the last 3 completed words (the ones before the cursor)
        let wordsToCheck = Array(words.suffix(3))

        for word in wordsToCheck {
            let lower = word.lowercased()

            // Skip very short words (a, I, an, etc.)
            guard word.count >= 2 else { continue }

            // Check our contraction table first
            if let contraction = contractionFix(for: lower) {
                replaceWord(word, with: contraction, in: text)
                return // One fix at a time to avoid cursor confusion
            }

            // Check our typo table
            if let typoFix = typoFix(for: lower) {
                let corrected = matchCapitalization(typoFix, to: word)
                replaceWord(word, with: corrected, in: text)
                return
            }

            // UITextChecker spell check
            let wordRange = NSRange(location: 0, length: word.utf16.count)
            let misspelled = inlineChecker.rangeOfMisspelledWord(
                in: word,
                range: wordRange,
                startingAt: 0,
                wrap: false,
                language: language
            )

            if misspelled.location != NSNotFound {
                if let guesses = inlineChecker.guesses(
                    forWordRange: wordRange,
                    in: word,
                    language: language
                ), let topGuess = guesses.first {
                    replaceWord(word, with: topGuess, in: text)
                    return
                }
            }
        }
    }

    /// Replace a word in the text field by moving the cursor, deleting, and inserting.
    private func replaceWord(_ oldWord: String, with newWord: String, in text: String) {
        // Find the last occurrence of the word in the text
        guard let range = text.range(of: oldWord, options: .backwards) else { return }

        // Calculate how far back the end of the word is from the cursor (end of text)
        let distanceFromEnd = text.distance(from: range.upperBound, to: text.endIndex)

        // Move cursor to end of the word
        if distanceFromEnd > 0 {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: -distanceFromEnd)
        }

        // Delete the old word
        for _ in 0..<oldWord.utf16.count {
            textDocumentProxy.deleteBackward()
        }

        // Insert the correction
        textDocumentProxy.insertText(newWord)

        // Move cursor back to where it was (end of text)
        if distanceFromEnd > 0 {
            textDocumentProxy.adjustTextPosition(byCharacterOffset: distanceFromEnd)
        }
    }

    private func getLanguage() -> String {
        let id = Locale.current.identifier.replacingOccurrences(of: "_", with: "-")
        return UITextChecker.availableLanguages.contains(id) ? id : "en-US"
    }

    private func matchCapitalization(_ correction: String, to original: String) -> String {
        if original == original.uppercased() && original.count > 1 {
            return correction.uppercased()
        } else if original.first?.isUppercase == true {
            return correction.prefix(1).uppercased() + correction.dropFirst()
        }
        return correction
    }

    // MARK: - Quick lookup tables (duplicated from service for inline fixing)

    private func contractionFix(for word: String) -> String? {
        let table: [String: String] = [
            "im": "I'm", "ive": "I've", "ill": "I'll", "id": "I'd",
            "youre": "you're", "youve": "you've", "youll": "you'll", "youd": "you'd",
            "theyre": "they're", "theyve": "they've", "theyll": "they'll", "theyd": "they'd",
            "were": "we're", "weve": "we've",
            "hes": "he's", "hed": "he'd",
            "shes": "she's", "shed": "she'd",
            "its": "it's", "itll": "it'll",
            "dont": "don't", "doesnt": "doesn't", "didnt": "didn't",
            "cant": "can't", "couldnt": "couldn't",
            "wont": "won't", "wouldnt": "wouldn't",
            "shouldnt": "shouldn't",
            "isnt": "isn't", "wasnt": "wasn't", "werent": "weren't", "arent": "aren't",
            "hasnt": "hasn't", "havent": "haven't", "hadnt": "hadn't",
            "couldve": "could've", "wouldve": "would've", "shouldve": "should've",
            "thats": "that's", "whats": "what's", "whos": "who's",
            "wheres": "where's", "heres": "here's", "theres": "there's",
            "lets": "let's", "whens": "when's", "hows": "how's",
        ]
        return table[word]
    }

    private func typoFix(for word: String) -> String? {
        let table: [String: String] = [
            "teh": "the", "hte": "the", "tge": "the",
            "adn": "and", "nad": "and", "anf": "and",
            "taht": "that", "htat": "that",
            "wiht": "with", "iwth": "with",
            "yuo": "you", "yoi": "you",
            "jsut": "just", "juts": "just",
            "knwo": "know", "konw": "know",
            "liek": "like", "lkie": "like",
            "ahve": "have", "hvae": "have",
            "waht": "what", "hwat": "what",
            "thier": "their",
            "becuase": "because", "becasue": "because", "beacuse": "because",
            "definately": "definitely", "definatly": "definitely",
            "seperate": "separate",
            "untill": "until",
            "woudl": "would", "shoudl": "should", "coudl": "could",
            "nto": "not",
            "abuot": "about",
            "tihs": "this", "htis": "this",
            "tommorow": "tomorrow", "tomorow": "tomorrow",
        ]
        return table[word]
    }

    // MARK: - Message capture polling

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

    private func checkProxy() {
        let currentText = textDocumentProxy.documentContextBeforeInput ?? ""
        let trimmed = currentText.trimmingCharacters(in: .whitespacesAndNewlines)

        if trimmed.isEmpty {
            let message = lastKnownText.trimmingCharacters(in: .whitespacesAndNewlines)
            if !message.isEmpty {
                MessageStore.appendMessage(message)
            }
            lastKnownText = ""
        } else {
            lastKnownText = currentText
        }
    }
}
