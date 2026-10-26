import Foundation

/// A word list with frequencies, stored as a flat trie in one byte array so it loads without parsing.
///
/// Layout: an 8-byte header (`HXL1`, node count) then 8 bytes per node, children of a node contiguous and in
/// order: letter, word log-probability, subtree log-mass, flags (last sibling, capitalized), first child index.
/// Probabilities are stored as `-ln p` in tenths of a nat (0 means "not a word").
public final class Lexicon: @unchecked Sendable {
    public let bytes: [UInt8]

    static let header: [UInt8] = Array("HXL1".utf8)
    public static let alphabet = 27

    public init?(bytes: [UInt8]) {
        guard bytes.count >= 16, Array(bytes[0..<4]) == Self.header else { return nil }
        self.bytes = bytes
    }

    /// The bundled English lexicon (SCOWL words, Google Books fiction frequencies).
    public static let english: Lexicon = {
        let url = Bundle.module.url(forResource: "en", withExtension: "lexicon")!
        return Lexicon(bytes: [UInt8](try! Data(contentsOf: url, options: .alwaysMapped)))!
    }()

    struct Node: Hashable {
        let index: Int
        init(_ index: Int) { self.index = index }
        var offset: Int { 8 + index * 8 }
    }

    var root: Node { Node(0) }

    @inline(__always) func letter(_ node: Node) -> UInt8 { bytes[node.offset] }

    @inline(__always) func logWord(_ node: Node) -> Double? {
        let q = bytes[node.offset + 1]
        return q == 0 ? nil : -Double(q) / 10
    }

    @inline(__always) func logMass(_ node: Node) -> Double { -Double(bytes[node.offset + 2]) / 10 }

    func isCapitalized(_ node: Node) -> Bool { bytes[node.offset + 3] & 2 != 0 }

    func children(_ node: Node) -> Children {
        let o = node.offset + 4
        let first = Int(bytes[o]) | Int(bytes[o + 1]) << 8 | Int(bytes[o + 2]) << 16 | Int(bytes[o + 3]) << 24
        return Children(lexicon: self, first: first)
    }

    func child(_ node: Node, _ letter: UInt8) -> Node? {
        children(node).first { self.letter($0) == letter }
    }

    func node(for word: some StringProtocol) -> Node? {
        var node = root
        for byte in word.utf8 {
            guard let next = child(node, Self.fold(byte)) else { return nil }
            node = next
        }
        return node
    }

    public func logProbability(of word: some StringProtocol) -> Double? {
        node(for: Self.normalize(word)).flatMap(logWord)
    }

    public func isWord(_ word: some StringProtocol) -> Bool { logProbability(of: word) != nil }

    /// The word as the lexicon spells it ("I'm" for "im"), if it is one.
    public func canonical(_ word: some StringProtocol) -> String? {
        let key = Self.normalize(word)
        guard let node = node(for: key), logWord(node) != nil else { return nil }
        let lower = key.lowercased()
        return isCapitalized(node) ? lower.prefix(1).uppercased() + lower.dropFirst() : lower
    }

    struct Children: Sequence, IteratorProtocol {
        let lexicon: Lexicon
        var upcoming: Int

        init(lexicon: Lexicon, first: Int) {
            self.lexicon = lexicon
            self.upcoming = first
        }

        mutating func next() -> Node? {
            guard upcoming != 0 else { return nil }
            let node = Node(upcoming)
            upcoming = lexicon.bytes[node.offset + 3] & 1 != 0 ? 0 : upcoming + 1
            return node
        }
    }

    /// Curly apostrophes read as straight ones.
    static func normalize(_ word: some StringProtocol) -> String {
        String(word).replacingOccurrences(of: "’", with: "'")
    }

    @inline(__always) static func fold(_ byte: UInt8) -> UInt8 {
        switch byte {
        case 65...90: byte + 32
        default: byte
        }
    }

    @inline(__always) static func index(of letter: UInt8) -> Int? {
        switch letter {
        case 97...122: Int(letter - 97)
        case 39: 26
        default: nil
        }
    }

    @inline(__always) static func letter(at index: Int) -> UInt8 { index == 26 ? 39 : UInt8(97 + index) }

    static let labels = (0..<alphabet).map { String(UnicodeScalar(letter(at: $0))) }

    /// True when every character is a–z, A–Z or an apostrophe, so the trie can hold it.
    public static func isSpellable(_ word: some StringProtocol) -> Bool {
        let key = normalize(word)
        return !key.isEmpty && key.utf8.allSatisfy { index(of: fold($0)) != nil }
    }

    /// The `count` most frequent words, optionally starting with a prefix.
    public func mostFrequent(count: Int, startingWith prefix: String = "") -> [String] {
        guard let start = node(for: prefix) else { return [] }
        var heap = Heap<(node: Node, spelling: [UInt8], terminal: Bool)>()
        heap.push((start, Array(prefix.lowercased().utf8), false), priority: logMass(start))
        var words: [String] = []
        while words.count < count, let (node, spelling, terminal) = heap.pop() {
            if terminal {
                words.append(canonical(String(decoding: spelling, as: UTF8.self)) ?? "")
                continue
            }
            if let word = logWord(node) { heap.push((node, spelling, true), priority: word) }
            for child in children(node) { heap.push((child, spelling + [letter(child)], false), priority: logMass(child)) }
        }
        return words
    }
}
