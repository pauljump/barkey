import Foundation

/// Processes raw text into StyleProfile updates.
/// Text is analyzed in memory and immediately discarded — only counters persist.
enum StyleAnalyzer {

    private static let slangWords: Set<String> = [
        "gonna", "wanna", "gotta", "idk", "tbh", "nah", "yea", "yeah", "ya",
        "ur", "rn", "omg", "btw", "lmk", "ngl", "imo", "smh", "bruh", "nope",
        "yep", "kinda", "sorta", "dunno", "cuz", "tho", "thx", "pls", "w/",
        "w/o", "bc", "def", "prob", "obvi", "lowkey", "highkey", "fr", "ong"
    ]

    private static let laughWords: Set<String> = [
        "haha", "hahaha", "lol", "lmao", "lmfao", "rofl", "😂", "🤣", "😆"
    ]

    private static let stopWords: Set<String> = [
        "the", "a", "an", "is", "are", "was", "were", "be", "been", "being",
        "have", "has", "had", "do", "does", "did", "will", "would", "could",
        "should", "may", "might", "shall", "can", "to", "of", "in", "for",
        "on", "with", "at", "by", "from", "as", "into", "through", "during",
        "before", "after", "above", "below", "between", "and", "or", "not",
        "no", "so", "if", "then", "than", "that", "this", "these", "those",
        "it", "its", "he", "she", "they", "we", "you", "me", "him", "her",
        "them", "us", "my", "your", "his", "our", "their"
    ]

    private static let emojiPattern: NSRegularExpression? = {
        try? NSRegularExpression(
            pattern: "[\\u{1F600}-\\u{1F9FF}\\u{1FA00}-\\u{1FA6F}\\u{1FA70}-\\u{1FAFF}\\u{2702}-\\u{27B0}\\u{FE00}-\\u{FE0F}\\u{1F000}-\\u{1F02F}\\u{2600}-\\u{26FF}\\u{2700}-\\u{27BF}]",
            options: []
        )
    }()

    /// Process a completed message and update the profile.
    /// The message text is not stored — only statistical counters are updated.
    static func processMessage(_ text: String, into profile: inout StyleProfile) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let words = trimmed.components(separatedBy: .whitespaces).filter { !$0.isEmpty }
        guard !words.isEmpty else { return }

        profile.messageCount += 1
        profile.totalWords += words.count
        profile.totalCharacters += trimmed.count

        // Message length bucket
        switch words.count {
        case 1: profile.onWordMessages += 1
        case 2...3: profile.shortMessages += 1
        case 4...15: profile.mediumMessages += 1
        default: profile.longMessages += 1
        }

        // Punctuation
        if trimmed.contains("!") { profile.exclamationMessages += 1 }
        if trimmed.contains("?") { profile.questionMessages += 1 }
        if trimmed.contains("...") || trimmed.contains("…") { profile.ellipsisMessages += 1 }
        profile.commaCount += trimmed.filter { $0 == "," }.count
        profile.dashCount += trimmed.filter { $0 == "-" || $0 == "—" }.count

        // Capitalization
        if let first = trimmed.first, first.isLowercase { profile.startsLowercase += 1 }
        if trimmed == trimmed.lowercased() { profile.allLowercaseMessages += 1 }
        if trimmed == trimmed.uppercased() && trimmed.count > 2 { profile.allCapsMessages += 1 }

        // Emoji
        let range = NSRange(trimmed.startIndex..., in: trimmed)
        if let regex = emojiPattern, regex.firstMatch(in: trimmed, range: range) != nil {
            profile.emojiMessages += 1
        }

        // Tone markers
        let lowerWords = words.map { $0.lowercased() }

        if lowerWords.contains(where: { laughWords.contains($0) }) {
            profile.hahaMessages += 1
        }
        if lowerWords.contains(where: { slangWords.contains($0) }) {
            profile.slangMessages += 1
        }

        // Word frequency (skip stop words, keep meaningful vocabulary)
        for word in lowerWords {
            let cleaned = word.trimmingCharacters(in: .punctuationCharacters)
            guard cleaned.count > 1, !stopWords.contains(cleaned) else { continue }
            profile.wordFrequency[cleaned, default: 0] += 1
        }

        // Cap vocabulary to top 500 to stay within memory limits
        if profile.wordFrequency.count > 600 {
            let sorted = profile.wordFrequency.sorted { $0.value > $1.value }
            profile.wordFrequency = Dictionary(uniqueKeysWithValues: Array(sorted.prefix(500)))
        }

        // Bigrams
        if lowerWords.count >= 2 {
            for i in 0..<(lowerWords.count - 1) {
                let bigram = "\(lowerWords[i]) \(lowerWords[i+1])"
                profile.bigramFrequency[bigram, default: 0] += 1
            }
        }

        // Cap bigrams
        if profile.bigramFrequency.count > 400 {
            let sorted = profile.bigramFrequency.sorted { $0.value > $1.value }
            profile.bigramFrequency = Dictionary(uniqueKeysWithValues: Array(sorted.prefix(300)))
        }

        // Opener (first 1-3 words)
        let openerCount = min(3, lowerWords.count)
        let opener = lowerWords.prefix(openerCount).joined(separator: " ")
        profile.openerFrequency[opener, default: 0] += 1

        // Cap openers
        if profile.openerFrequency.count > 200 {
            let sorted = profile.openerFrequency.sorted { $0.value > $1.value }
            profile.openerFrequency = Dictionary(uniqueKeysWithValues: Array(sorted.prefix(150)))
        }

        // Closer (last 1-3 words)
        let closerCount = min(3, lowerWords.count)
        let closer = lowerWords.suffix(closerCount).joined(separator: " ")
        profile.closerFrequency[closer, default: 0] += 1

        // Cap closers
        if profile.closerFrequency.count > 200 {
            let sorted = profile.closerFrequency.sorted { $0.value > $1.value }
            profile.closerFrequency = Dictionary(uniqueKeysWithValues: Array(sorted.prefix(150)))
        }
    }
}
