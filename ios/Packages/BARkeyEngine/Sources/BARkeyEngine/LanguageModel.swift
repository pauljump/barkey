import Foundation

/// P(word | previous word), from the lexicon and what this person writes.
///
/// Every level backs off to the next with Witten-Bell weights, which come from the counts themselves (a context
/// seen N times with T different words trusts itself N / (N + T)): the person's next-word counts → their word
/// counts → the lexicon → a word nobody knows, spelled letter by letter. How often the person types such new words is
/// itself learned: (new + 1) / (all + 2), Laplace's rule of succession.
public struct LanguageModel {
    let lexicon: Lexicon
    let personal: PersonalVocabulary
    let phrases: Phrases?
    let novelty: Double
    /// How much the corpus phrases count when ranking corrections (0 = ignore context, 1 = full strength).
    public static var phraseBlend = 0.5

    static let spellingLogProbability = -Math.log(Double(Lexicon.alphabet))

    init(lexicon: Lexicon, personal: PersonalVocabulary, phrases: Phrases? = nil) {
        self.lexicon = lexicon
        self.personal = personal
        self.phrases = phrases
        let novel = personal.counts.reduce(0) { $0 + (lexicon.isWord($1.key) ? 0 : $1.value) }
        novelty = (Double(novel) + 1) / (Double(personal.total) + 2)
    }

    /// For ranking corrections. Corpus phrases are blended in at half strength: the phrase table keeps only each
    /// context's likeliest words, so at full strength it would bury every other word.
    func logProbability(_ word: String, after previous: String?, earlier: String?) -> Double {
        let plain = probability(word, after: previous, earlier: earlier, phrased: false)
        guard phrases != nil, previous != nil else { return Math.log(plain) }
        let phrased = probability(word, after: previous, earlier: earlier, phrased: true)
        return Math.log((1 - Self.phraseBlend) * plain + Self.phraseBlend * phrased)
    }

    /// For predicting the next word, with the corpus phrases at full strength.
    func logPrediction(_ word: String, after previous: String?, earlier: String?) -> Double {
        Math.log(probability(word, after: previous, earlier: earlier, phrased: true))
    }

    private func probability(_ word: String, after previous: String?, earlier: String?, phrased: Bool) -> Double {
        var p = lexical(word)
        if personal.total > 0 {
            let types = Double(personal.counts.count)
            p = (Double(personal.count(of: word)) + types * p) / (Double(personal.total) + types)
        }
        if phrased, let phrases { p = phrases.probability(of: word, after: previous, earlier: earlier, below: p) }
        if let previous {
            let (count, total, types) = personal.count(of: word, after: previous)
            if total > 0 { p = (Double(count) + Double(types) * p) / Double(total + types) }
        }
        return p
    }

    func lexical(_ word: String) -> Double {
        let known = lexicon.logProbability(of: word).map(Math.exp) ?? 0
        return (1 - novelty) * known + novelty * Math.exp(Self.spellingLogProbability * Double(word.utf8.count + 1))
    }
}
