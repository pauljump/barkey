import Foundation

/// One thing the keyboard can offer for the word being typed.
public struct Suggestion: Equatable, Sendable {
    public enum Kind: Sendable { case literal, autocorrect, candidate, completion, prediction }
    public var text: String
    public var kind: Kind
    public init(_ text: String, _ kind: Kind) { self.text = text; self.kind = kind }
}

/// What to show and what to apply for the text typed so far.
public struct Suggestions: Equatable, Sendable {
    /// The word as typed (nil when the text ends in a space).
    public var literal: String?
    /// Replace the typed word with this when the person types a space or punctuation.
    public var autocorrect: String?
    /// Alternatives to show beside the typed word.
    public var alternatives: [String]
    /// What the person is likely to type next (after a space).
    public var predictions: [String]

    public static let none = Suggestions(literal: nil, autocorrect: nil, alternatives: [], predictions: [])
}

/// BARkey's autocorrect. Decides, for the word being typed, whether it was a slip and what was meant.
///
/// The model is a noisy channel: P(word) from the lexicon, the corpus phrases and this person's own messages, times
/// P(keys | word) from where the keys sit on the keyboard. A word is corrected only when (1) nobody would type it on
/// purpose (not in the lexicon, not something this person has sent, not a name, handle, number or deliberate casing)
/// and (2) the best reading beats the literal by a clear margin. Known words are never changed, with one exception:
/// a contraction missing its apostrophe when the apostrophe form is overwhelmingly more common ("dont", "cant").
public final class Corrector: @unchecked Sendable {
    public let lexicon: Lexicon
    public let phrases: Phrases?
    public let geometry: KeyGeometry
    public var personal: PersonalVocabulary { didSet { model = LanguageModel(lexicon: lexicon, personal: personal, phrases: phrases) } }

    /// How much likelier (in nats) the correction must be than the typed word to replace an unknown word.
    public var margin = 2.0
    /// How much likelier the apostrophe form must be to replace a real word ("cant" → "can't", but not "its" → "it's").
    public var apostropheMargin = 5.0
    /// Below this log-probability a word-list entry is treated as junk ("rhe", "hom"): corrected when a reading beats it by `rareMargin`.
    public var rareThreshold = -12.0
    public var rareMargin = 3.0
    /// Shortest typed word autocorrect will replace (single letters are left alone, except "i").
    public var minimumLength = 2
    /// Words never corrected and never offered as corrections: how people text.
    public var protected: Set<String> = Corrector.textingWords
    /// Spellings the keyboard replaces outright before any modelling ("teh" → "the").
    public var replacements: [String: String] = Corrector.commonTypos

    private var model: LanguageModel
    private let decoder: Decoder
    private var cache: [CacheKey: Suggestions] = [:]
    private var cacheGeneration = 0

    private struct CacheKey: Hashable { let text: String; let generation: Int }

    public init(lexicon: Lexicon = .english, phrases: Phrases? = .english, geometry: KeyGeometry = .qwerty, personal: PersonalVocabulary = PersonalVocabulary()) {
        self.lexicon = lexicon
        self.phrases = phrases
        self.geometry = geometry
        self.personal = personal
        self.model = LanguageModel(lexicon: lexicon, personal: personal, phrases: phrases)
        self.decoder = Decoder(lexicon: lexicon)
    }

    /// Suggestions for everything typed before the cursor.
    public func suggestions(for text: String) -> Suggestions {
        if cache.count > 500 { cache.removeAll(keepingCapacity: true) }
        let key = CacheKey(text: text, generation: cacheGeneration)
        if let cached = cache[key] { return cached }
        let result = compute(for: text)
        cache[key] = result
        return result
    }

    /// Forget cached results (after the personal vocabulary changes).
    public func invalidate() { cacheGeneration += 1 }

    private func compute(for text: String) -> Suggestions {
        let word = Words.current(in: text)
        if word.isEmpty {
            // Between words: predict the next one.
            let (previous, earlier) = contextAfterSpace(in: text)
            return Suggestions(literal: nil, autocorrect: nil, alternatives: [], predictions: predictions(after: previous, earlier: earlier))
        }
        let typed = String(word)
        var result = Suggestions(literal: typed, autocorrect: nil, alternatives: [], predictions: [])
        guard Words.isCorrectable(word, in: text) else { return result }
        let (previous, earlier) = Words.context(before: word, in: text)
        let lower = Lexicon.normalize(typed).lowercased()

        // 1. Outright replacements and the lone "i".
        if lower == "i" && typed == "i" { result.autocorrect = "I"; return result }
        if let fixed = replacements[lower] {
            result.autocorrect = Words.matchCase(fixed, to: word)
            return result
        }

        let owned = personal.owns(typed) || personal.isKept(typed)
        let isProtected = protected.contains(lower)
        let deliberate = Words.hasDeliberateCasing(word) || isMidSentenceName(word, previous: previous)
        let spellable = Lexicon.isSpellable(lower)

        // 2. Rank readings of the keys.
        let ranked = spellable ? rank(typed, previous: previous, earlier: earlier) : []
        let literalScore = ranked.first { $0.isLiteral }?.posterior ?? -.infinity
        let exact = ranked.filter { !$0.isCompletion && !$0.isLiteral }
        let completions = ranked.filter { $0.isCompletion }

        // 3. Decide the correction.
        if spellable, !owned, !isProtected, !deliberate, typed.count >= minimumLength, let best = exact.first, !protected.contains(best.word.lowercased()) {
            let known = lexicon.isWord(lower) || personal.count(of: lower) > 0
            let rare = personal.count(of: lower) == 0 && (lexicon.logProbability(of: lower) ?? 0) < rareThreshold
            if known && !rare {
                // Real word. Only an apostrophe-less contraction, and only when the contraction dwarfs it.
                if isApostropheVariant(best.word, of: lower), best.posterior - literalScore >= apostropheMargin, best.word.count >= 3 {
                    result.autocorrect = Words.matchCase(best.word, to: word)
                }
            } else if known && rare {
                if best.posterior - literalScore >= rareMargin, best.word.count >= minimumLength {
                    result.autocorrect = Words.matchCase(best.word, to: word)
                }
            } else if best.posterior - literalScore >= margin, best.word.count >= minimumLength {
                result.autocorrect = Words.matchCase(best.word, to: word)
            }
        }
        if let canonical = lexicon.canonical(lower), result.autocorrect == nil, canonical != typed, canonical.lowercased() == lower, canonical.first!.isUppercase, word.first!.isLowercase, !owned {
            // "i'm" → "I'm", "monday" stays as the person typed it unless the lexicon marks it capitalized.
            if lower.hasPrefix("i'") || lower == "i" { result.autocorrect = canonical }
        }

        // 4. Alternatives: other exact readings first, then completions, then the person's own words.
        var seen: Set<String> = [lower]
        if let fix = result.autocorrect { seen.insert(fix.lowercased()) }
        var alternatives: [String] = []
        func add(_ candidate: String) {
            let shown = Words.matchCase(candidate, to: word)
            if alternatives.count < 3, seen.insert(shown.lowercased()).inserted { alternatives.append(shown) }
        }
        for candidate in exact where !protected.contains(candidate.word.lowercased()) || candidate.word.lowercased() == lower { add(candidate.word) }
        for own in personal.counts.keys where own.hasPrefix(lower) && own != lower { add(own) }
        for completion in completions.sorted(by: { $0.posterior > $1.posterior }) { add(completion.word) }
        result.alternatives = alternatives
        return result
    }

    struct Candidate {
        var word: String
        var likelihood: Double
        var posterior: Double
        var isCompletion: Bool
        var isLiteral: Bool
    }

    /// Every reading of the keys worth considering, likeliest first, the literal always among them.
    func rank(_ typed: String, previous: String?, earlier: String?) -> [Candidate] {
        let lower = Lexicon.normalize(typed).lowercased()
        let taps = lower.utf8.map { geometry.evidence(forTyped: Lexicon.fold($0)) }
        var candidates: [String: Candidate] = [:]
        func consider(_ word: String, likelihood: Double, isCompletion: Bool) {
            let key = word.lowercased()
            let isLiteral = key == lower
            var posterior = likelihood + model.logProbability(word, after: previous, earlier: earlier)
            // A capitalized entry ("Linc", "Bern") typed in lowercase mid-sentence is an unlikely reading.
            if !isLiteral, word.first?.isUppercase == true, typed.first?.isLowercase == true, previous != "" { posterior -= 3 }
            guard posterior > -.infinity, posterior > candidates[key]?.posterior ?? -.infinity else { return }
            candidates[key] = Candidate(word: word, likelihood: likelihood, posterior: posterior, isCompletion: isCompletion && !isLiteral, isLiteral: isLiteral)
        }
        for result in decoder.decode(taps, count: 8) {
            if result.isCompletion, result.word.count == taps.count + 1 {
                // One letter short of a word ("runnin"): a slip, not a prefix.
                consider(result.word, likelihood: result.logLikelihood + Decoder.editLogProbability, isCompletion: false)
            }
            consider(result.word, likelihood: result.logLikelihood, isCompletion: result.isCompletion)
        }
        let literal = lexicon.canonical(lower) ?? typed
        consider(literal, likelihood: Decoder.logLikelihood(of: literal, given: taps), isCompletion: false)
        // The person's own words the lexicon doesn't know, if the keys could mean them.
        for (word, count) in personal.counts where count >= 1 && !lexicon.isWord(word) && word.utf8.count + 1 >= taps.count && abs(word.utf8.count - taps.count) <= 2 {
            let exact = Decoder.logLikelihood(of: word, given: taps)
            let completed = Decoder.logLikelihood(of: word, given: taps, completing: true)
            consider(personal.spelling(of: word), likelihood: max(exact, completed), isCompletion: completed > exact)
        }
        return candidates.values.sorted { $0.posterior > $1.posterior }
    }

    /// Next words after a space, the person's own habits first, then the corpus.
    public func predictions(after previous: String?, earlier: String?, limit: Int = 3) -> [String] {
        var out: [String] = []
        var seen: Set<String> = []
        func add(_ word: String) {
            let shown = previous == "" ? Words.matchCase(word, to: "A") : (lexicon.canonical(word) ?? word)
            if out.count < limit, word != Phrases.start, !word.contains("_"), seen.insert(word.lowercased()).inserted { out.append(shown) }
        }
        if let previous {
            for word in personal.next(after: previous) where personal.count(of: word, after: previous).count >= 2 { add(word) }
            if let phrases {
                for word in phrases.next(after: previous, earlier: earlier) { add(word) }
            }
        }
        return out
    }

    private func contextAfterSpace(in text: String) -> (String?, String?) {
        let trimmed = text[...].dropLast { $0 == " " }
        guard let last = trimmed.last else { return ("", nil) }
        if Words.sentenceEnders.contains(last) || last.isNewline { return ("", nil) }
        guard text.last == " " else { return (nil, nil) }
        let previousWord = Words.current(in: String(trimmed))
        guard !previousWord.isEmpty else { return (nil, nil) }
        let (earlier, _) = Words.context(before: previousWord, in: String(trimmed))
        return (previousWord.lowercased(), earlier)
    }

    private func isApostropheVariant(_ candidate: String, of lower: String) -> Bool {
        candidate.lowercased().replacingOccurrences(of: "'", with: "") == lower && candidate.contains("'")
    }

    /// A capitalized word that doesn't start a sentence: "Priya", "Wegmans".
    private func isMidSentenceName(_ word: Substring, previous: String?) -> Bool {
        guard let first = word.first, first.isUppercase, word.count > 1 else { return false }
        guard let previous else { return true }
        return !previous.isEmpty
    }

    /// Slang, laughs and abbreviations: how people text. Never corrected, never offered as a correction of something else.
    public static let textingWords: Set<String> = [
        "gonna", "wanna", "gotta", "idk", "tbh", "nah", "yea", "yeah", "ya", "ur", "rn",
        "omg", "btw", "lmk", "ngl", "imo", "imho", "smh", "bruh", "nope", "yep", "yup", "kinda",
        "sorta", "dunno", "cuz", "tho", "thx", "pls", "plz", "bc", "def", "prob", "obvi",
        "lowkey", "highkey", "fr", "ong", "haha", "hahaha", "hahahaha", "lol", "lmao",
        "lmfao", "rofl", "ok", "okk", "kk", "k", "ty", "tysm", "np", "nvm", "wyd", "hbu",
        "irl", "fomo", "goat", "sus", "bet", "oof", "ugh", "hmm", "hmmm", "mhm", "yay", "woo",
        "omw", "ttyl", "brb", "gn", "gm", "jk", "afaik", "iirc", "fwiw", "eta", "asap",
        "lmaoo", "lolol", "hah", "heh", "meh", "eh", "oh", "ooh", "ahh", "umm", "um", "uh",
        "ily", "wtf", "wth", "af", "ffs", "tf", "bff", "dm", "pm", "am", "tbd", "tba", "aka",
        "ikr", "ig", "idc", "idek", "ily", "ya'll", "yall", "gimme", "lemme", "ima", "imma",
        "whatcha", "dunno", "ain't", "aint", "tryna", "finna", "boutta", "bout", "til", "till",
        "sec", "min", "mins", "hr", "hrs", "wk", "wks", "yr", "yrs", "tmrw", "tmr", "tonite", "nite",
        "ppl", "msg", "txt", "pic", "pics", "vid", "vids", "app", "apps", "tv", "vc", "fyi", "rsvp",
        "ish", "ty", "yw", "wbu", "sup", "wassup", "yo", "aight", "ight", "fam", "bro", "sis", "dude",
    ]

    /// Spellings that always mean one thing, applied before the model gets a say.
    public static let commonTypos: [String: String] = [
        "teh": "the", "hte": "the", "helo": "hello", "adn": "and", "nad": "and", "taht": "that", "wiht": "with", "iwth": "with",
        "yuo": "you", "jsut": "just", "knwo": "know", "konw": "know", "liek": "like", "ahve": "have", "hvae": "have",
        "waht": "what", "thier": "their", "becuase": "because", "becasue": "because", "beacuse": "because",
        "recieve": "receive", "occured": "occurred", "definately": "definitely", "definatly": "definitely",
        "seperate": "separate", "untill": "until", "wich": "which", "woudl": "would", "shoudl": "should",
        "coudl": "could", "goign": "going", "abuot": "about", "tihs": "this", "amke": "make", "rigth": "right",
        "thign": "thing", "alot": "a lot", "thankyou": "thank you", "tommorow": "tomorrow", "tomorow": "tomorrow",
        "tomorrw": "tomorrow", "im": "I'm", "ive": "I've", "dont": "don't", "didnt": "didn't", "doesnt": "doesn't",
        "wasnt": "wasn't", "isnt": "isn't", "arent": "aren't", "couldnt": "couldn't", "wouldnt": "wouldn't",
        "shouldnt": "shouldn't", "havent": "haven't", "hasnt": "hasn't", "hadnt": "hadn't", "werent": "weren't",
        "youre": "you're", "youve": "you've", "youll": "you'll", "theyre": "they're", "theyve": "they've",
        "theyll": "they'll", "thats": "that's", "whats": "what's", "theres": "there's", "heres": "here's",
        "wheres": "where's", "hows": "how's", "whos": "who's", "couldve": "could've", "wouldve": "would've",
        "shouldve": "should've", "itll": "it'll", "weve": "we've", "cant": "can't", "wont": "won't",
    ]
}
