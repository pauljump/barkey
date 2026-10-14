import Foundation

/// Converts a StyleProfile into a portable LLM system prompt.
/// This is the product — the prompt that makes any LLM write like you.
enum PromptGenerator {

    static func generate(from profile: StyleProfile) -> String {
        guard profile.messageCount >= 50 else {
            return "Not enough data yet. Keep typing!"
        }

        var lines: [String] = []

        lines.append("Write all responses in the following personal writing style. Match this voice exactly:\n")

        // Message length character
        lines.append("## Length & Structure")
        let avgWords = profile.avgWordsPerMessage
        if avgWords < 6 {
            lines.append("- Very concise writer. Average message is \(Int(avgWords)) words. Keeps things short and punchy.")
        } else if avgWords < 12 {
            lines.append("- Moderately concise. Average message is \(Int(avgWords)) words. Direct but not terse.")
        } else {
            lines.append("- Tends toward longer messages. Average \(Int(avgWords)) words. Comfortable with detail.")
        }

        let shortRate = profile.shortMessageRate
        if shortRate > 0.3 {
            lines.append("- Frequently uses very short responses (1-3 words) — \(pct(shortRate)) of messages. Comfortable with \"yeah\", \"ok\", \"got it\" style replies.")
        }

        // Punctuation personality
        lines.append("\n## Punctuation & Formatting")
        if profile.exclamationRate < 0.05 {
            lines.append("- Rarely uses exclamation marks (\(pct(profile.exclamationRate))). Understated tone — lets words carry the energy, not punctuation.")
        } else if profile.exclamationRate > 0.2 {
            lines.append("- Frequently uses exclamation marks (\(pct(profile.exclamationRate))). Energetic, enthusiastic punctuation.")
        }

        if profile.questionRate > 0.15 {
            lines.append("- Asks a lot of questions (\(pct(profile.questionRate)) of messages). Curious, engaged, invites dialogue.")
        }

        let ellipsisRate = Double(profile.ellipsisMessages) / Double(max(profile.messageCount, 1))
        if ellipsisRate > 0.05 {
            lines.append("- Uses ellipsis frequently (\(pct(ellipsisRate))). Creates trailing, thoughtful pauses.")
        } else {
            lines.append("- Almost never uses ellipsis. Sentences end decisively.")
        }

        if profile.lowercaseStartRate > 0.3 {
            lines.append("- Often starts messages lowercase (\(pct(profile.lowercaseStartRate))). Casual, stream-of-consciousness feel.")
        } else {
            lines.append("- Uses proper capitalization. Messages start with uppercase letters.")
        }

        // Tone & voice
        lines.append("\n## Tone & Voice")
        if profile.emojiRate < 0.05 {
            lines.append("- Almost never uses emoji (\(pct(profile.emojiRate))). Communicates entirely through words.")
        } else if profile.emojiRate > 0.2 {
            lines.append("- Frequently uses emoji (\(pct(profile.emojiRate))). Expressive, visual communicator.")
        } else {
            lines.append("- Occasional emoji use (\(pct(profile.emojiRate))). Sparing but present.")
        }

        let hahaRate = Double(profile.hahaMessages) / Double(max(profile.messageCount, 1))
        if hahaRate > 0.05 {
            lines.append("- Expresses amusement with words like haha/lol (\(pct(hahaRate)) of messages).")
        } else {
            lines.append("- Rarely uses haha/lol. Humor is dry or expressed through content, not markers.")
        }

        if profile.slangRate > 0.3 {
            lines.append("- Heavy use of casual language and slang (\(pct(profile.slangRate))). Words like gonna, wanna, idk, tbh, ngl.")
        } else if profile.slangRate > 0.1 {
            lines.append("- Moderate slang usage (\(pct(profile.slangRate))). Casual but not sloppy.")
        } else {
            lines.append("- Minimal slang. Writes in standard English even in casual contexts.")
        }

        // Signature phrases
        lines.append("\n## Signature Patterns")

        let topBigrams = profile.topBigrams.prefix(8)
        if !topBigrams.isEmpty {
            lines.append("- Frequently used phrases: " + topBigrams.map { "\"\($0.0)\"" }.joined(separator: ", "))
        }

        let topOpeners = profile.topOpeners.prefix(5)
        if !topOpeners.isEmpty {
            lines.append("- Often starts messages with: " + topOpeners.map { "\"\($0.0)\"" }.joined(separator: ", "))
        }

        // Key vocabulary
        let meaningfulWords = profile.topWords
            .filter { $0.1 >= 3 } // appeared at least 3 times
            .prefix(20)
        if !meaningfulWords.isEmpty {
            lines.append("- Core vocabulary includes: " + meaningfulWords.map { $0.0 }.joined(separator: ", "))
        }

        // Overall summary
        lines.append("\n## Overall")
        var traits: [String] = []
        if avgWords < 8 { traits.append("concise") }
        if profile.exclamationRate < 0.05 { traits.append("understated") }
        if profile.slangRate > 0.2 { traits.append("casual") }
        if profile.questionRate > 0.12 { traits.append("curious") }
        if profile.emojiRate < 0.05 { traits.append("words-over-emoji") }
        if shortRate > 0.25 { traits.append("comfortable with terse replies") }

        if !traits.isEmpty {
            lines.append("- This person's writing is: " + traits.joined(separator: ", ") + ".")
        }

        lines.append("\nIMPORTANT: Match this style precisely. Do not add emoji if the style doesn't use them. Do not add exclamation marks if the style is understated. Mirror the vocabulary, sentence length, and tone exactly.")

        return lines.joined(separator: "\n")
    }

    /// Generate a brief, human-readable style summary for the free tier.
    static func generateSummary(from profile: StyleProfile) -> String {
        var traits: [String] = []

        // Length
        if profile.avgWordsPerMessage < 6 { traits.append("Very concise") }
        else if profile.avgWordsPerMessage < 12 { traits.append("Direct") }
        else { traits.append("Detail-oriented") }

        // Tone
        if profile.exclamationRate < 0.05 { traits.append("understated") }
        else if profile.exclamationRate > 0.2 { traits.append("enthusiastic") }

        if profile.slangRate > 0.3 { traits.append("casual") }
        else if profile.slangRate < 0.1 { traits.append("proper") }

        if profile.emojiRate < 0.03 { traits.append("no emoji") }
        else if profile.emojiRate > 0.15 { traits.append("emoji-forward") }

        if profile.questionRate > 0.15 { traits.append("inquisitive") }

        // Opener
        if let topOpener = profile.topOpeners.first {
            traits.append("opens with \"\(topOpener.0)...\"")
        }

        return traits.joined(separator: " · ")
    }

    /// Generate a voice prompt using real message examples (few-shot) + statistical summary.
    /// This is the actual exported product — much more accurate than stats alone.
    static func generateFromMessages(_ messages: [String], profile: StyleProfile) -> String {
        var lines: [String] = []

        lines.append("Write all responses in this person's exact writing style. Study the examples below carefully and match their voice precisely.\n")

        // Select representative examples — varied lengths, different patterns
        let examples = selectRepresentativeMessages(from: messages, count: 40)

        lines.append("## Real Examples of Their Writing")
        lines.append("These are actual messages from this person. Match the tone, vocabulary, sentence structure, capitalization, punctuation, and formatting exactly.\n")

        for example in examples {
            lines.append("- \"\(example)\"")
        }

        // Add statistical reinforcement
        lines.append("\n## Style Profile (quantified)")

        let avgWords = profile.avgWordsPerMessage
        lines.append("- Average message length: \(Int(avgWords)) words")

        if profile.shortMessageRate > 0.2 {
            lines.append("- \(pct(profile.shortMessageRate)) of messages are 1-3 words (comfortable with terse replies)")
        }

        if profile.exclamationRate < 0.05 {
            lines.append("- Exclamation marks: \(pct(profile.exclamationRate)) (understated, avoids exclamation)")
        } else if profile.exclamationRate > 0.15 {
            lines.append("- Exclamation marks: \(pct(profile.exclamationRate)) (enthusiastic, energetic)")
        }

        if profile.emojiRate < 0.05 {
            lines.append("- Emoji usage: \(pct(profile.emojiRate)) (rarely uses emoji)")
        } else if profile.emojiRate > 0.15 {
            lines.append("- Emoji usage: \(pct(profile.emojiRate)) (frequently uses emoji)")
        }

        if profile.lowercaseStartRate > 0.3 {
            lines.append("- Starts messages lowercase \(pct(profile.lowercaseStartRate)) of the time")
        }

        if profile.slangRate > 0.1 {
            lines.append("- Uses casual language/slang \(pct(profile.slangRate)) of the time")
        }

        // Top phrases and openers
        let topBigrams = profile.topBigrams.prefix(5)
        if !topBigrams.isEmpty {
            lines.append("- Frequent phrases: " + topBigrams.map { "\"\($0.0)\"" }.joined(separator: ", "))
        }

        let topOpeners = profile.topOpeners.prefix(5)
        if !topOpeners.isEmpty {
            lines.append("- Common message starters: " + topOpeners.map { "\"\($0.0)\"" }.joined(separator: ", "))
        }

        lines.append("\n## Rules")
        lines.append("- Match the examples above precisely — they ARE this person's voice")
        lines.append("- If the examples don't use emoji, do NOT add emoji")
        lines.append("- If the examples don't use exclamation marks, do NOT add them")
        lines.append("- Match their capitalization style (lowercase starts, proper caps, etc.)")
        lines.append("- Match their typical message length — don't write paragraphs if they write sentences")
        lines.append("- Use their vocabulary and phrasing, not formal/generic alternatives")

        return lines.joined(separator: "\n")
    }

    /// Select a diverse set of representative messages.
    /// Picks across different length buckets and avoids near-duplicates.
    private static func selectRepresentativeMessages(from messages: [String], count: Int) -> [String] {
        guard !messages.isEmpty else { return [] }

        // Deduplicate (case-insensitive)
        var seen = Set<String>()
        let unique = messages.filter { msg in
            let lower = msg.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !lower.isEmpty, !seen.contains(lower) else { return false }
            seen.insert(lower)
            return true
        }

        guard !unique.isEmpty else { return [] }
        if unique.count <= count { return unique }

        // Bucket by length to ensure variety
        let short = unique.filter { $0.split(separator: " ").count <= 3 }
        let medium = unique.filter { let c = $0.split(separator: " ").count; return c >= 4 && c <= 15 }
        let long = unique.filter { $0.split(separator: " ").count > 15 }

        var selected: [String] = []

        // Take proportionally from each bucket
        let total = unique.count
        let shortRatio = Double(short.count) / Double(total)
        let mediumRatio = Double(medium.count) / Double(total)
        let longRatio = Double(long.count) / Double(total)

        let shortCount = max(1, Int(Double(count) * shortRatio))
        let mediumCount = max(1, Int(Double(count) * mediumRatio))
        let longCount = max(1, Int(Double(count) * longRatio))

        // Sample evenly across each bucket
        selected.append(contentsOf: evenSample(from: short, count: shortCount))
        selected.append(contentsOf: evenSample(from: medium, count: mediumCount))
        selected.append(contentsOf: evenSample(from: long, count: longCount))

        return Array(selected.prefix(count))
    }

    /// Sample evenly spaced items from an array.
    private static func evenSample(from array: [String], count: Int) -> [String] {
        guard !array.isEmpty else { return [] }
        if array.count <= count { return array }

        var result: [String] = []
        let step = Double(array.count) / Double(count)
        for i in 0..<count {
            let index = Int(Double(i) * step)
            result.append(array[index])
        }
        return result
    }

    private static func pct(_ value: Double) -> String {
        "\(Int(value * 100))%"
    }
}
