import Foundation

/// Decides what a captured message becomes before it is ever written to disk.
/// Contact details, links and long numbers are replaced with placeholders, so
/// they never reach storage, the review screen, or an exported prompt.
enum CaptureFilter {

    private static let replacements: [(NSRegularExpression, String)] = {
        let patterns: [(String, String)] = [
            ("[A-Z0-9._%+-]+@[A-Z0-9.-]+\\.[A-Z]{2,}", "[email]"),
            ("(https?://|www\\.)\\S+", "[link]"),
            ("\\b[a-z0-9-]+\\.(com|net|org|io|co|app|dev|ai|me|ly|gg)(/\\S*)?\\b", "[link]"),
            ("\\+?\\d[\\d\\s().-]{7,}\\d", "[number]"),
            ("\\b\\d{5,}\\b", "[number]"),
        ]
        return patterns.compactMap { pattern, token in
            (try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])).map { ($0, token) }
        }
    }()

    /// Returns the text to store, or nil if the message should be dropped.
    static func clean(_ raw: String) -> String? {
        var text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return nil }

        for (regex, token) in replacements {
            let range = NSRange(text.startIndex..., in: text)
            text = regex.stringByReplacingMatches(in: text, range: range, withTemplate: token)
        }

        // Nothing left but placeholders and punctuation: not a sample of anyone's voice.
        let stripped = text
            .replacingOccurrences(of: "\\[(email|link|number)\\]", with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        guard stripped.rangeOfCharacter(from: .letters) != nil else { return nil }

        return text
    }
}
