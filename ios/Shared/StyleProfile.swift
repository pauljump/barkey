import Foundation

/// The statistical fingerprint of someone's writing style.
/// Stores only aggregate counters — never raw text.
/// Shared between keyboard extension and containing app via App Groups.
struct StyleProfile: Codable {
    var messageCount: Int = 0
    var totalWords: Int = 0
    var totalCharacters: Int = 0

    // Message length distribution
    var onWordMessages: Int = 0      // exactly 1 word
    var shortMessages: Int = 0       // 2-3 words
    var mediumMessages: Int = 0      // 4-15 words
    var longMessages: Int = 0        // 16+ words

    // Punctuation habits
    var exclamationMessages: Int = 0
    var questionMessages: Int = 0
    var ellipsisMessages: Int = 0
    var commaCount: Int = 0
    var dashCount: Int = 0

    // Capitalization
    var startsLowercase: Int = 0
    var allLowercaseMessages: Int = 0
    var allCapsMessages: Int = 0

    // Tone markers
    var emojiMessages: Int = 0
    var hahaMessages: Int = 0        // haha, lol, lmao, etc.
    var slangMessages: Int = 0       // gonna, wanna, idk, etc.

    // Top vocabulary (word -> count)
    var wordFrequency: [String: Int] = [:]

    // Bigrams (two-word pairs)
    var bigramFrequency: [String: Int] = [:]

    // Opening patterns (first 1-3 words of messages)
    var openerFrequency: [String: Int] = [:]

    // Closing patterns (last 1-3 words of messages)
    var closerFrequency: [String: Int] = [:]

    static let targetMessageCount = 10 // TODO: restore to 500 after testing

    var progress: Double {
        min(Double(messageCount) / Double(Self.targetMessageCount), 1.0)
    }

    var isReady: Bool {
        messageCount >= Self.targetMessageCount
    }

    var avgWordsPerMessage: Double {
        messageCount > 0 ? Double(totalWords) / Double(messageCount) : 0
    }

    var exclamationRate: Double {
        messageCount > 0 ? Double(exclamationMessages) / Double(messageCount) : 0
    }

    var questionRate: Double {
        messageCount > 0 ? Double(questionMessages) / Double(messageCount) : 0
    }

    var emojiRate: Double {
        messageCount > 0 ? Double(emojiMessages) / Double(messageCount) : 0
    }

    var slangRate: Double {
        messageCount > 0 ? Double(slangMessages) / Double(messageCount) : 0
    }

    var lowercaseStartRate: Double {
        messageCount > 0 ? Double(startsLowercase) / Double(messageCount) : 0
    }

    var shortMessageRate: Double {
        messageCount > 0 ? Double(onWordMessages + shortMessages) / Double(messageCount) : 0
    }

    var topWords: [(String, Int)] {
        wordFrequency.sorted { $0.value > $1.value }.prefix(30).map { ($0.key, $0.value) }
    }

    var topBigrams: [(String, Int)] {
        bigramFrequency.sorted { $0.value > $1.value }.prefix(15).map { ($0.key, $0.value) }
    }

    var topOpeners: [(String, Int)] {
        openerFrequency.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
    }

    var topClosers: [(String, Int)] {
        closerFrequency.sorted { $0.value > $1.value }.prefix(10).map { ($0.key, $0.value) }
    }
}
