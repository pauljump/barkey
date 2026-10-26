import Foundation

/// Where each letter sits on a QWERTY phone keyboard, in key widths, and how likely a tap meant for one letter
/// is to land on another. Fat fingers hit neighbours; they rarely hit the far side of the keyboard.
public struct KeyGeometry: Sendable {
    /// Key centres indexed like `Lexicon` (a–z, then the apostrophe, which has no key on the letters layer).
    let centers: [(x: Double, y: Double)?]
    /// Spread of taps around a key centre, in key widths. Apple's keys are about 1 unit wide, 1.3 tall.
    public var sigma: Double
    /// Floor for a substitution the geometry can't explain (a slip to the far side of the keyboard).
    public var randomSubstitution: Double

    /// Log likelihood of landing on `typed` when `intended` was meant, relative to a dead-centre hit (0).
    let confusion: [[Double]]

    public static let qwerty = KeyGeometry(rows: ["qwertyuiop", "asdfghjkl", "zxcvbnm"], offsets: [0, 0.5, 1.5])

    public init(rows: [String], offsets: [Double], sigma: Double = 0.55, randomSubstitution: Double = -9) {
        var centers = [(x: Double, y: Double)?](repeating: nil, count: Lexicon.alphabet)
        for (r, row) in rows.enumerated() {
            for (c, letter) in row.utf8.enumerated() {
                if let i = Lexicon.index(of: letter) { centers[i] = (Double(c) + offsets[r], Double(r) * 1.3) }
            }
        }
        self.centers = centers
        self.sigma = sigma
        self.randomSubstitution = randomSubstitution
        var confusion = [[Double]](repeating: [Double](repeating: randomSubstitution, count: Lexicon.alphabet), count: Lexicon.alphabet)
        for typed in 0..<Lexicon.alphabet {
            for intended in 0..<Lexicon.alphabet {
                if typed == intended { confusion[typed][intended] = 0; continue }
                guard let a = centers[typed], let b = centers[intended] else { continue }
                let d2 = (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y)
                confusion[typed][intended] = max(-d2 / (2 * sigma * sigma), randomSubstitution)
            }
        }
        self.confusion = confusion
    }

    /// For each letter the person could have meant, the log likelihood of the key they actually hit.
    func evidence(forTyped letter: UInt8) -> TapEvidence {
        guard let typed = Lexicon.index(of: letter) else { return .exact(letter) }
        // A stray key is explained by the edit penalty alone, so it costs nothing extra here.
        return TapEvidence(letters: confusion[typed], stray: 0)
    }

    /// Letters whose keys touch `letter`'s key (for tests and typo simulation).
    public func neighbors(of letter: Character) -> [Character] {
        guard let byte = letter.lowercased().utf8.first, let i = Lexicon.index(of: byte), let c = centers[i] else { return [] }
        return (0..<26).compactMap { j in
            guard j != i, let d = centers[j] else { return nil }
            let d2 = (c.x - d.x) * (c.x - d.x) + (c.y - d.y) * (c.y - d.y)
            return d2 <= 1.8 ? Character(UnicodeScalar(Lexicon.letter(at: j))) : nil
        }
    }
}

/// How well one tap fits each letter: log likelihoods indexed a–z then the apostrophe, plus the likelihood that the
/// tap meant no letter at all (a stray key).
struct TapEvidence: Hashable, Sendable {
    var letters: [Double]
    var stray: Double

    static func exact(_ letter: UInt8) -> TapEvidence {
        var letters = [Double](repeating: -.infinity, count: Lexicon.alphabet)
        if let index = Lexicon.index(of: letter) { letters[index] = 0 }
        return TapEvidence(letters: letters, stray: -.infinity)
    }

    var best: Double { letters.max() ?? 0 }
}
