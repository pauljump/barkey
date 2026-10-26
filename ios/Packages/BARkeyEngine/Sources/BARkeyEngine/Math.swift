import Foundation

enum Math {
    @inline(__always) static func log(_ x: Double) -> Double { Foundation.log(x) }
    @inline(__always) static func exp(_ x: Double) -> Double { Foundation.exp(x) }

    static func logSumExp(_ a: Double, _ b: Double) -> Double {
        let high = max(a, b)
        guard high > -.infinity else { return high }
        return high + log1p(exp(min(a, b) - high))
    }
}

struct Heap<Element> {
    private var items: [(priority: Double, element: Element)] = []

    var isEmpty: Bool { items.isEmpty }

    mutating func push(_ element: Element, priority: Double) {
        items.append((priority, element))
        var child = items.count - 1
        while child > 0 {
            let parent = (child - 1) / 2
            guard items[parent].priority < items[child].priority else { break }
            items.swapAt(parent, child)
            child = parent
        }
    }

    mutating func pop() -> Element? {
        guard !items.isEmpty else { return nil }
        items.swapAt(0, items.count - 1)
        let top = items.removeLast()
        var parent = 0
        while true {
            let left = parent * 2 + 1, right = left + 1
            var largest = parent
            if left < items.count, items[left].priority > items[largest].priority { largest = left }
            if right < items.count, items[right].priority > items[largest].priority { largest = right }
            guard largest != parent else { break }
            items.swapAt(parent, largest)
            parent = largest
        }
        return top.element
    }
}
