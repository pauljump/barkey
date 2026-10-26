import Foundation

/// What this person actually writes: word and next-word counts from their own sent messages, words they taught the
/// keyboard, and words they kept after undoing a correction. Nothing here is ever "fixed".
public struct PersonalVocabulary: Sendable, Equatable {
    public private(set) var counts: [String: Int] = [:]
    public private(set) var bigrams: [String: [String: Int]] = [:]
    public private(set) var total = 0
    /// How the person most often spells each word (lowercase key → their casing).
    public private(set) var spellings: [String: [String: Int]] = [:]
    /// Words the person added deliberately (tapped the typed word, or reverted a correction).
    public private(set) var kept: Set<String> = []

    public init() {}

    public init(messages: [String], kept: Set<String> = []) {
        self.kept = Set(kept.map { $0.lowercased() })
        for message in messages { add(message: message) }
    }

    /// Learns one sent message.
    public mutating func add(message: String) {
        var previous = ""
        for token in Words.tokens(in: message) {
            switch token {
            case .boundary:
                previous = ""
            case .word(let word):
                let lower = word.lowercased()
                guard Lexicon.isSpellable(lower) else { previous = ""; continue }
                counts[lower, default: 0] += 1
                spellings[lower, default: [:]][String(word), default: 0] += 1
                total += 1
                bigrams[previous, default: [:]][lower, default: 0] += 1
                previous = lower
            }
        }
    }

    public mutating func keep(_ word: String) { kept.insert(word.lowercased()) }
    public mutating func unkeep(_ word: String) { kept.remove(word.lowercased()) }
    public func isKept(_ word: String) -> Bool { kept.contains(word.lowercased()) }

    public func count(of word: String) -> Int { counts[word.lowercased()] ?? 0 }

    /// The casing the person uses most for a word ("Jenna", "iPhone"), or the word itself.
    public func spelling(of word: String) -> String {
        spellings[word.lowercased()]?.max { $0.value < $1.value || ($0.value == $1.value && $0.key > $1.key) }?.key ?? word
    }

    /// A word the person has sent at least twice, or kept on purpose: theirs, never to be corrected.
    public func owns(_ word: String) -> Bool {
        let lower = word.lowercased()
        return kept.contains(lower) || (counts[lower] ?? 0) >= 2
    }

    /// (count of `word` after `previous`, total after `previous`, distinct followers of `previous`).
    func count(of word: String, after previous: String) -> (count: Int, total: Int, types: Int) {
        guard let next = bigrams[previous.lowercased()] else { return (0, 0, 0) }
        return (next[word.lowercased()] ?? 0, next.values.reduce(0, +), next.count)
    }

    /// The person's own likeliest next words after `previous` ("" for a sentence start).
    public func next(after previous: String, limit: Int = 5) -> [String] {
        guard let followers = bigrams[previous.lowercased()] else { return [] }
        return followers.sorted { $0.value > $1.value || ($0.value == $1.value && $0.key < $1.key) }.prefix(limit).map(\.key)
    }

    /// Words the person uses that the lexicon doesn't know (names, slang, their spellings).
    public func novelWords(against lexicon: Lexicon) -> [String] {
        counts.keys.filter { !lexicon.isWord($0) }.sorted()
    }
}
