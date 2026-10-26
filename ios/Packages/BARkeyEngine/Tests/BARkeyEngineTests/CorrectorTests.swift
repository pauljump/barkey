import XCTest
@testable import BARkeyEngine

final class CorrectorTests: XCTestCase {
    let corrector = Corrector()

    func fix(_ text: String) -> String? { corrector.suggestions(for: text).autocorrect }

    func testCommonSlipsAreFixed() {
        XCTAssertEqual(fix("teh"), "the")
        XCTAssertEqual(fix("I think teh"), "the")
        XCTAssertEqual(fix("thnaks"), "thanks")
        XCTAssertEqual(fix("helo there"), nil, "mid-sentence context: 'there' is a word")
        XCTAssertEqual(fix("helo"), "hello")
        XCTAssertEqual(fix("I am goong"), "going")
        XCTAssertEqual(fix("see you tomorrpw"), "tomorrow")
        XCTAssertEqual(fix("wiht"), "with")
        XCTAssertEqual(fix("recieve"), "receive")
        XCTAssertEqual(fix("Teh"), "The")
        XCTAssertEqual(fix("TEH"), "THE")
        XCTAssertEqual(fix("beautifil"), "beautiful")
        XCTAssertEqual(fix("I will be homr"), "home")
    }

    func testNeighbourSlips() {
        XCTAssertEqual(fix("I am so tired todsy"), "today")
        XCTAssertEqual(fix("can you grab milk on the way homw"), "home")
        XCTAssertEqual(fix("running a few minutes lste"), "late")
        XCTAssertEqual(fix("the meetung"), "meeting")
    }

    func testContractions() {
        XCTAssertEqual(fix("dont"), "don't")
        XCTAssertEqual(fix("i"), "I")
        XCTAssertEqual(fix("im"), "I'm")
        XCTAssertEqual(fix("cant"), "can't")
        XCTAssertEqual(fix("wont"), "won't")
        XCTAssertEqual(fix("didnt"), "didn't")
        XCTAssertEqual(fix("i'm"), "I'm")
        // Real words that are also contractions are offered, never forced.
        XCTAssertNil(fix("its"))
        XCTAssertNil(fix("well"))
        XCTAssertNil(fix("were"))
        XCTAssertNil(fix("ill"))
        XCTAssertNil(fix("id"))
        XCTAssertNil(fix("hell"))
        XCTAssertNil(fix("shell"))
        XCTAssertNil(fix("lets"))
    }

    func testRealWordsAreLeftAlone() {
        for word in ["the", "hello", "running", "Monday", "pizza", "fine", "okay", "because", "awesome", "yes", "no", "to", "of", "it", "at", "on", "do", "so", "an", "or", "me", "we", "he", "be", "by", "up", "us", "in", "is", "as", "if", "my", "am"] {
            XCTAssertNil(fix(word), word)
            XCTAssertNil(fix("I said " + word), word)
        }
    }

    func testTextingIsNotCorrected() {
        for word in ["lol", "lmao", "idk", "tbh", "gonna", "wanna", "omw", "haha", "hahaha", "ok", "k", "ty", "pls", "rn", "ngl", "yall", "tryna", "ikr"] {
            XCTAssertNil(fix(word), word)
            XCTAssertNil(fix("yeah " + word), word)
        }
    }

    func testNamesHandlesAndNumbersAreProtected() {
        XCTAssertNil(fix("I saw Priya"))
        XCTAssertNil(fix("at Wegmans"))
        XCTAssertNil(fix("iPhone"))
        XCTAssertNil(fix("OPWDD"))
        XCTAssertNil(fix("@pauljump"))
        XCTAssertNil(fix("#nyc"))
        XCTAssertNil(fix("https://renting.win/abc"))
        XCTAssertNil(fix("renting.win"))
        XCTAssertNil(fix("paul@me"))
        XCTAssertNil(fix("room 4b"))
        XCTAssertNil(fix("x"))
        XCTAssertNil(fix("ok c"))
    }

    func testPersonalWordsAreNeverCorrected() {
        var personal = PersonalVocabulary(messages: ["Rex has his opwdd meeting", "opwdd called again", "Rex is asleep", "Jenna said yes", "Jenna is home"])
        personal.keep("stuyv")
        let own = Corrector(personal: personal)
        XCTAssertNil(own.suggestions(for: "opwdd").autocorrect)
        XCTAssertNil(own.suggestions(for: "jenna").autocorrect)
        XCTAssertNil(own.suggestions(for: "stuyv").autocorrect)
        XCTAssertNil(own.suggestions(for: "the rex").autocorrect)
        // And a slip of an owned word corrects to it.
        XCTAssertEqual(own.suggestions(for: "tell jenns").autocorrect, "Jenna")
    }

    func testAlternativesAndCompletions() {
        let s = corrector.suggestions(for: "I am goin")
        XCTAssertEqual(s.literal, "goin")
        XCTAssertTrue(s.alternatives.contains("going"), "\(s)")
        let t = corrector.suggestions(for: "its")
        XCTAssertTrue(t.alternatives.contains("it's"), "\(t)")
    }

    func testPredictions() {
        let s = corrector.suggestions(for: "I am going to ")
        XCTAssertNil(s.literal)
        XCTAssertFalse(s.predictions.isEmpty)
        XCTAssertTrue(s.predictions.allSatisfy { !$0.contains("_") })
        let start = corrector.suggestions(for: "Hey. ")
        XCTAssertFalse(start.predictions.isEmpty)
        XCTAssertTrue(start.predictions.allSatisfy { $0.first!.isUppercase }, "\(start.predictions)")
        var personal = PersonalVocabulary()
        for _ in 0..<3 { personal.add(message: "omw home now") }
        let own = Corrector(personal: personal)
        XCTAssertEqual(own.suggestions(for: "omw ").predictions.first, "home")
    }

    func testSpeed() {
        let words = ["I", "am", "goign", "to", "the", "stroe", "and", "then", "homw", "tonight", "beautifil", "restaurnat"]
        var text = ""
        measure {
            for word in words {
                text += word
                _ = corrector.suggestions(for: text)
                text += " "
            }
            corrector.invalidate()
        }
    }

    func testWordsHelpers() {
        XCTAssertEqual(String(Words.current(in: "hello wor")), "wor")
        XCTAssertEqual(String(Words.current(in: "hello ")), "")
        XCTAssertEqual(Words.previous(before: Words.current(in: "hello wor"), in: "hello wor"), "hello")
        XCTAssertEqual(Words.previous(before: Words.current(in: "Hi. wor"), in: "Hi. wor"), "")
        XCTAssertEqual(Words.matchCase("the", to: "Teh"), "The")
        XCTAssertEqual(Words.matchCase("the", to: "TEH"), "THE")
        XCTAssertTrue(Words.hasDeliberateCasing("iPhone"))
        XCTAssertFalse(Words.hasDeliberateCasing("Hello"))
    }
}
