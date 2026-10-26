import Foundation
import KeyboardKit
import BARkeyEngine

/// KeyboardKit's autocomplete, backed by BARkey's own corrector: the English lexicon, the corpus phrases, and the
/// person's own sent messages as vocabulary. Suggestions read like Apple's: the typed word on the left, the
/// correction (highlighted, applied on space) in the middle, one more reading on the right.
final class BARkeyAutocompleteService: AutocompleteService {

    var locale: Locale = .current

    let corrector: Corrector

    init() {
        corrector = Corrector(personal: Self.loadPersonal())
    }

    /// Rebuilds the personal vocabulary from the saved messages and kept words.
    func reloadPersonal() {
        corrector.personal = Self.loadPersonal()
        corrector.invalidate()
    }

    private static func loadPersonal() -> PersonalVocabulary {
        PersonalVocabulary(messages: MessageStore.loadMessages(), kept: KeptWords.load())
    }

    // MARK: - AutocompleteService

    func autocomplete(_ text: String) async throws -> AutocompleteResult {
        let s = corrector.suggestions(for: text)
        var out: [AutocompleteSuggestion] = []
        if let literal = s.literal {
            out.append(AutocompleteSuggestion(text: literal, type: .regular))
            if let fix = s.autocorrect {
                out.append(AutocompleteSuggestion(text: fix, type: .autocorrect))
                if let alt = s.alternatives.first(where: { $0.lowercased() != fix.lowercased() }) {
                    out.append(AutocompleteSuggestion(text: alt, type: .regular))
                }
            } else {
                for alt in s.alternatives.prefix(2) { out.append(AutocompleteSuggestion(text: alt, type: .regular)) }
            }
        } else {
            out = s.predictions.prefix(3).map { AutocompleteSuggestion(text: $0, type: .regular) }
        }
        return AutocompleteResult(inputText: text, suggestions: out)
    }

    // MARK: - Word learning (kept words, shared with the app)

    private var _ignoredWords: [String] = []

    var canIgnoreWords: Bool { true }
    var canLearnWords: Bool { true }
    var ignoredWords: [String] { _ignoredWords }
    var learnedWords: [String] { Array(corrector.personal.kept).sorted() }

    func hasIgnoredWord(_ word: String) -> Bool { _ignoredWords.contains(word.lowercased()) }
    func hasLearnedWord(_ word: String) -> Bool { corrector.personal.isKept(word) }

    func ignoreWord(_ word: String) {
        let lower = word.lowercased()
        if !_ignoredWords.contains(lower) { _ignoredWords.append(lower) }
        // Ignoring a word for this session means: don't correct it.
        corrector.personal.keep(lower)
        corrector.invalidate()
    }

    func learnWord(_ word: String) {
        KeptWords.add(word)
        corrector.personal.keep(word)
        corrector.invalidate()
    }

    func removeIgnoredWord(_ word: String) {
        _ignoredWords.removeAll { $0 == word.lowercased() }
    }

    func unlearnWord(_ word: String) {
        KeptWords.remove(word)
        corrector.personal.unkeep(word)
        corrector.invalidate()
    }
}
