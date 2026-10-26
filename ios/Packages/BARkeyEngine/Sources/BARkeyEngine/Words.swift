import Foundation

public enum Words {
    public static let apostrophes: Set<Character> = ["'", "’"]
    static let openers: Set<Character> = ["(", "[", "{", "\"", "“", "'", "‘"]
    public static let sentenceEnders: Set<Character> = [".", "!", "?"]

    enum Token { case word(Substring), boundary }

    static func isWordCharacter(_ character: Character) -> Bool {
        character.isLetter || character.isNumber || apostrophes.contains(character)
    }

    /// Words and sentence boundaries, in order. Punctuation and newlines end a sentence; spaces don't.
    static func tokens(in text: String) -> [Token] {
        var tokens: [Token] = [.boundary]
        var current = text.startIndex
        var index = text.startIndex
        var inWord = false
        func flush(_ end: String.Index) {
            if inWord {
                let word = text[current..<end].drop { apostrophes.contains($0) }
                if !word.isEmpty { tokens.append(.word(word)) }
                inWord = false
            }
        }
        while index < text.endIndex {
            let c = text[index]
            if isWordCharacter(c) {
                if !inWord { current = index; inWord = true }
            } else {
                flush(index)
                if sentenceEnders.contains(c) || c.isNewline || c == "," || c == ";" || c == ":" { tokens.append(.boundary) }
            }
            index = text.index(after: index)
        }
        flush(text.endIndex)
        return tokens
    }

    /// The word being typed at the end of `text` (empty if the text ends in a space or punctuation).
    public static func current(in text: String) -> Substring {
        let start = text.lastIndex { !isWordCharacter($0) }.map(text.index(after:)) ?? text.startIndex
        return text[start...].drop { apostrophes.contains($0) }
    }

    /// A word autocorrect may touch: letters only, not glued to a URL, handle, hashtag or number.
    public static func isCorrectable(_ word: Substring, in text: String) -> Bool {
        guard !word.isEmpty, !word.contains(where: \.isNumber) else { return false }
        guard word.startIndex > text.startIndex else { return true }
        let before = text[text.index(before: word.startIndex)]
        guard before.isWhitespace || openers.contains(before) || apostrophes.contains(before) else { return false }
        // Inside a URL or email, nothing is a word.
        let head = text[..<word.startIndex]
        if let lastSpace = head.lastIndex(where: \.isWhitespace) {
            let chunk = head[head.index(after: lastSpace)...]
            if chunk.contains("@") || chunk.contains("/") || chunk.contains("#") { return false }
        } else if head.contains("@") || head.contains("/") || head.contains("#") { return false }
        return true
    }

    /// The word before `word`, lowercased; "" at a sentence start; nil when unknown (no space separates them).
    public static func previous(before word: Substring, in text: String) -> String? {
        let head = text[..<word.startIndex]
        guard let last = head.last, last == " " else { return head.isEmpty ? "" : nil }
        let trimmed = head.dropLast { $0 == " " }
        guard let character = trimmed.last else { return "" }
        if sentenceEnders.contains(character) || character.isNewline { return "" }
        let previous = current(in: String(trimmed))
        return previous.isEmpty ? nil : previous.lowercased()
    }

    /// The two words before a word, each read like `previous`.
    public static func context(before word: Substring, in text: String) -> (previous: String?, earlier: String?) {
        let previous = previous(before: word, in: text)
        guard let previous, !previous.isEmpty else { return (previous, nil) }
        let head = String(text[..<word.startIndex].dropLast { $0 == " " })
        return (previous, Self.previous(before: current(in: head), in: head))
    }

    /// Carries the typed word's casing onto a candidate: "Teh" → "The", "TEH" → "THE".
    public static func matchCase(_ candidate: String, to typed: Substring) -> String {
        guard let first = typed.first, first.isUppercase else { return candidate }
        if typed.count > 1, typed.allSatisfy({ !$0.isLetter || $0.isUppercase }) { return candidate.uppercased() }
        guard candidate.first?.isUppercase != true else { return candidate }
        return candidate.prefix(1).uppercased() + candidate.dropFirst()
    }

    /// "iPhone", "McDonald", "OPWDD": casing the person chose, not a slip.
    public static func hasDeliberateCasing(_ word: Substring) -> Bool {
        let letters = word.filter(\.isLetter)
        guard letters.count > 1 else { return false }
        let uppers = letters.filter(\.isUppercase).count
        if uppers == letters.count { return true }
        return uppers > 0 && !(uppers == 1 && letters.first!.isUppercase)
    }
}

extension Substring {
    func dropLast(while predicate: (Character) -> Bool) -> Substring {
        var result = self
        while let last = result.last, predicate(last) { result.removeLast() }
        return result
    }
}
