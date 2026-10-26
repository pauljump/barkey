import Foundation

/// Finds the words a sequence of keystrokes most likely meant: A* over the lexicon trie, scoring each word as
/// P(keys | word) × P(word). A word may differ by one missed, extra or swapped key (about 1 in 100 keystrokes), and
/// typing a contraction's apostrophe is a coin flip. Each node's subtree mass bounds every word below it, so the
/// search finds the best words first.
public struct Decoder {
    let lexicon: Lexicon

    /// A key that meant nothing (about 1 in 200 keystrokes).
    public static var extraKeyLogProbability = Math.log(0.005)
    /// A letter the thumb skipped (about 1 in 50: the most common slip after hitting a neighbour).
    public static var missedKeyLogProbability = Math.log(0.02)
    /// Two keys in the wrong order.
    public static var swapLogProbability = Math.log(0.01)
    /// The penalty for a dropped final letter ("runnin").
    public static var editLogProbability: Double { missedKeyLogProbability }
    static let apostropheLogProbability = Math.log(0.5)
    static let budget = 8000

    struct Result: Hashable {
        var word: String
        var logLikelihood: Double
        var logPrior: Double
        var isCompletion: Bool
    }

    private struct State {
        var node: Lexicon.Node
        var tap: Int
        var edits: Int
        var completing: Bool
        var score: Double
        var spelling: Int
        var terminal: Bool
    }

    private struct Trail {
        private var steps: [(previous: Int, letter: UInt8)] = []
        static let empty = -1

        mutating func extend(_ spelling: Int, with letter: UInt8) -> Int {
            steps.append((spelling, letter))
            return steps.count - 1
        }

        func word(_ spelling: Int) -> String {
            var letters: [UInt8] = []
            var step = spelling
            while step != Self.empty {
                letters.append(steps[step].letter)
                step = steps[step].previous
            }
            return String(decoding: letters.reversed(), as: UTF8.self)
        }
    }

    /// The `count` likeliest words, completions included, and at least the likeliest word of exactly the typed length.
    func decode(_ taps: [TapEvidence], count: Int = 6, completions: Bool = true) -> [Result] {
        guard !taps.isEmpty else { return [] }
        let best = taps.map(\.best)
        let offset = best.reduce(0, +)
        var heap = Heap<State>()
        var found: [Result] = []
        var seen: Set<Lexicon.Node> = []
        var trail = Trail()
        var exact = 0, pops = 0

        func push(_ state: State) {
            let bound = state.terminal ? state.score : state.score + lexicon.logMass(state.node)
            if bound > -.infinity { heap.push(state, priority: bound) }
        }
        func emit(_ state: State) {
            guard let word = lexicon.logWord(state.node) else { return }
            var terminal = state
            terminal.terminal = true
            terminal.score += word
            push(terminal)
        }
        push(State(node: lexicon.root, tap: 0, edits: 0, completing: false, score: 0, spelling: Trail.empty, terminal: false))

        while found.count < count || exact == 0, pops < Self.budget, let state = heap.pop() {
            pops += 1
            if state.terminal {
                guard seen.insert(state.node).inserted else { continue }
                let word = trail.word(state.spelling)
                let logPrior = lexicon.logWord(state.node) ?? 0
                found.append(Result(word: lexicon.canonical(word) ?? word, logLikelihood: state.score - logPrior + offset, logPrior: logPrior, isCompletion: state.completing))
                if !state.completing { exact += 1 }
                continue
            }
            let i = state.tap
            if i == taps.count, state.spelling != Trail.empty {
                if !state.completing { emit(state) }
            }
            // An extra key that meant nothing.
            if i < taps.count, state.edits == 0 {
                push(State(node: state.node, tap: i + 1, edits: 1, completing: false,
                           score: state.score + taps[i].stray - best[i] + Self.extraKeyLogProbability, spelling: state.spelling, terminal: false))
            }
            for child in lexicon.children(state.node) {
                let letter = lexicon.letter(child)
                guard let index = Lexicon.index(of: letter) else { continue }
                let spelling = trail.extend(state.spelling, with: letter)
                if i == taps.count {
                    guard completions else { continue }
                    let next = State(node: child, tap: i, edits: state.edits, completing: true, score: state.score, spelling: spelling, terminal: false)
                    if lexicon.logWord(child) != nil { emit(next) }
                    push(next)
                    continue
                }
                guard !state.completing else { continue }
                // The key meant this letter (dead on, or a neighbour).
                push(State(node: child, tap: i + 1, edits: state.edits, completing: false,
                           score: state.score + taps[i].letters[index] - best[i], spelling: spelling, terminal: false))
                // A letter the person skipped (apostrophes are skipped half the time).
                if letter == 39 || state.edits == 0 {
                    push(State(node: child, tap: i, edits: state.edits + (letter == 39 ? 0 : 1), completing: false,
                               score: state.score + (letter == 39 ? Self.apostropheLogProbability : Self.missedKeyLogProbability), spelling: spelling, terminal: false))
                }
                // Two keys in the wrong order.
                if state.edits == 0, i + 1 < taps.count {
                    for grandchild in lexicon.children(child) {
                        guard let second = Lexicon.index(of: lexicon.letter(grandchild)), second != index else { continue }
                        let swapped = taps[i].letters[second] + taps[i + 1].letters[index] - best[i] - best[i + 1]
                        push(State(node: grandchild, tap: i + 2, edits: 1, completing: false,
                                   score: state.score + swapped + Self.swapLogProbability, spelling: trail.extend(spelling, with: lexicon.letter(grandchild)), terminal: false))
                    }
                }
            }
        }
        return found
    }

    /// P(keys | word) for any word, lexicon or not: the best reading of the keys as the word, with at most one missed,
    /// extra or swapped key and any skipped apostrophes. `completing` lets the keys cover only the start of the word.
    static func logLikelihood(of word: String, given taps: [TapEvidence], completing: Bool = false) -> Double {
        let lower = Lexicon.normalize(word).lowercased()
        let letters = Array(lower.utf8).compactMap(Lexicon.index(of:))
        guard letters.count == lower.utf8.count, !letters.isEmpty else { return -.infinity }
        let best = taps.map(\.best)
        var total = -Double.infinity
        for reading in readings(of: letters, taps: taps.count, completing: completing) {
            var score = reading.logPenalty
            for (j, letter) in reading.letters.enumerated() {
                guard let letter else { score += taps[j].stray - best[j]; continue }
                score += taps[j].letters[letter] - best[j]
            }
            total = Math.logSumExp(total, score)
        }
        return total
    }

    struct Reading {
        var letters: [Int?]
        var logPenalty: Double
    }

    static func readings(of letters: [Int], taps: Int, completing: Bool) -> [Reading] {
        var found: [Reading] = []
        func walk(_ i: Int, _ j: Int, _ edited: Bool, _ reading: Reading) {
            if j == taps {
                if completing ? (i > 0 && i < letters.count) : i == letters.count { found.append(reading) }
                if completing { return }
            }
            if i < letters.count, j < taps {
                walk(i + 1, j + 1, edited, Reading(letters: reading.letters + [letters[i]], logPenalty: reading.logPenalty))
            }
            if i < letters.count, letters[i] == 26 || !edited {
                walk(i + 1, j, edited || letters[i] != 26, Reading(letters: reading.letters, logPenalty: reading.logPenalty + (letters[i] == 26 ? apostropheLogProbability : missedKeyLogProbability)))
            }
            guard !edited else { return }
            if j < taps {
                walk(i, j + 1, true, Reading(letters: reading.letters + [nil], logPenalty: reading.logPenalty + extraKeyLogProbability))
            }
            if i + 1 < letters.count, j + 1 < taps, letters[i] != letters[i + 1] {
                walk(i + 2, j + 2, true, Reading(letters: reading.letters + [letters[i + 1], letters[i]], logPenalty: reading.logPenalty + swapLogProbability))
            }
        }
        walk(0, 0, false, Reading(letters: [], logPenalty: 0))
        return found
    }
}
