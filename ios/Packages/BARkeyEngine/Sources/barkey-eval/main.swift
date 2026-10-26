import Foundation
import BARkeyEngine

// Fat-finger evaluation: perturb casual sentences the way a thumb does, run the corrector word by word, and
// measure how many slips it fixes and how many good words it ruins.
//
//   swift run -c release barkey-eval [--seed N] [--rate 0.15] [--verbose]

var seed: UInt64 = 7
var rate = 0.15
var verbose = false
var edit = 0.01
var sigma = 0.55
var blend = 0.5
var args = Array(CommandLine.arguments.dropFirst())
while let flag = args.first {
    args.removeFirst()
    switch flag {
    case "--seed": seed = UInt64(args.removeFirst())!
    case "--rate": rate = Double(args.removeFirst())!
    case "--verbose": verbose = true
    case "--edit": edit = Double(args.removeFirst())!
    case "--sigma": sigma = Double(args.removeFirst())!
    case "--blend": blend = Double(args.removeFirst())!
    default: break
    }
}

struct RNG: RandomNumberGenerator {
    var state: UInt64
    mutating func next() -> UInt64 {
        state ^= state << 13; state ^= state >> 7; state ^= state << 17
        return state
    }
}
var rng = RNG(state: seed)

Decoder.missedKeyLogProbability = log(edit)
LanguageModel.phraseBlend = blend
let geometry = KeyGeometry(rows: ["qwertyuiop", "asdfghjkl", "zxcvbnm"], offsets: [0, 0.5, 1.5], sigma: sigma)

func slip(_ word: String) -> String? {
    var chars = Array(word)
    guard chars.count >= 3 else { return nil }
    let i = Int.random(in: 0..<chars.count, using: &rng)
    let letter = chars[i]
    guard letter.isLetter else { return nil }
    let roll = Double.random(in: 0..<1, using: &rng)
    let neighbors = geometry.neighbors(of: letter)
    if roll < 0.6, let n = neighbors.randomElement(using: &rng) {
        chars[i] = letter.isUppercase ? Character(n.uppercased()) : n
    } else if roll < 0.75, i + 1 < chars.count, chars[i] != chars[i + 1] {
        chars.swapAt(i, i + 1)
    } else if roll < 0.9 {
        chars.remove(at: i)
    } else if let n = neighbors.randomElement(using: &rng) {
        chars.insert(n, at: i + 1)
    } else { return nil }
    let out = String(chars)
    return out == word ? nil : out
}

let corrector = Corrector(geometry: geometry)

var slips = 0, fixed = 0, wrongFix = 0, untouched = 0
var clean = 0, ruined = 0
var ruinedExamples: [String] = [], missedExamples: [String] = []
let start = Date()
var calls = 0

for sentence in EvalCorpus.sentences {
    let words = sentence.split(separator: " ").map(String.init)
    var typedSoFar = ""
    for word in words {
        let core = word.trimmingCharacters(in: .punctuationCharacters)
        let trailing = word.hasSuffix(core) ? "" : String(word.last!)
        let slipped = Double.random(in: 0..<1, using: &rng) < rate ? slip(core) : nil
        let typed = slipped ?? core
        let text = typedSoFar + typed
        let result = corrector.suggestions(for: text)
        calls += 1
        let applied = result.autocorrect ?? typed
        if let slipped {
            slips += 1
            if applied.lowercased() == core.lowercased() { fixed += 1 }
            else if applied == slipped { untouched += 1; if missedExamples.count < 25 { missedExamples.append("\(slipped) → \(applied) (wanted \(core))") } }
            else { wrongFix += 1; if missedExamples.count < 25 { missedExamples.append("\(slipped) → \(applied) (wanted \(core))") } }
        } else {
            clean += 1
            if applied.lowercased() != core.lowercased() { ruined += 1; if ruinedExamples.count < 25 { ruinedExamples.append("\(core) → \(applied)   [\(sentence)]") } }
        }
        typedSoFar += core + trailing + " "
    }
}
let elapsed = Date().timeIntervalSince(start)
func pct(_ a: Int, _ b: Int) -> String { b == 0 ? "–" : String(format: "%.1f%%", Double(a) / Double(b) * 100) }
print("sentences \(EvalCorpus.sentences.count)  words \(slips + clean)  slips \(slips)  rate \(rate)  seed \(seed)")
print("fixed \(fixed) (\(pct(fixed, slips)))  left alone \(untouched) (\(pct(untouched, slips)))  wrong fix \(wrongFix) (\(pct(wrongFix, slips)))")
print("clean words ruined \(ruined) / \(clean) (\(pct(ruined, clean)))")
print(String(format: "%.2f ms per word", elapsed / Double(calls) * 1000))
if verbose || ruined > 0 {
    print("\nRuined:"); ruinedExamples.forEach { print("  " + $0) }
}
if verbose {
    print("\nMissed:"); missedExamples.forEach { print("  " + $0) }
}
