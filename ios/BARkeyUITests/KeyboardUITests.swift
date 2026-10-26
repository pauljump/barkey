import XCTest

/// Types on the real BARkey keyboard inside the app's "Try the keyboard" field. The simulator must have the
/// keyboard enabled first (qa/sim-keyboard.sh does that) and the hardware keyboard disconnected.
final class KeyboardUITests: XCTestCase {
    var app: XCUIApplication!

    override func setUp() {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoOnboarded"]
        app.launch()
    }

    private func key(_ label: String) -> XCUIElement {
        for candidate in [label, label.uppercased(), label.lowercased()] {
            let k = app.keys[candidate]
            if k.exists { return k }
            let b = app.buttons[candidate]
            if b.exists { return b }
        }
        return app.keys[label]
    }

    /// Brings up BARkey in the try field; switches with the globe key if the system keyboard came up.
    private func focusTryField() -> XCUIElement {
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        XCTAssertTrue(app.keyboards.firstMatch.waitForExistence(timeout: 10), "no keyboard appeared")
        for _ in 0..<3 where !app.keyboards.staticTexts["BARkey"].exists && app.keyboards.buttons["Next keyboard"].exists && !isBarkey() {
            app.keyboards.buttons["Next keyboard"].tap()
            sleep(1)
        }
        return field
    }

    /// BARkey's bar shows suggestions; the system keyboard's predictive bar is a different element.
    private func isBarkey() -> Bool {
        app.otherElements["BARkeyKeyboard"].exists || app.keyboards.firstMatch.otherElements.matching(NSPredicate(format: "label CONTAINS 'BARkey'")).firstMatch.exists
    }

    private func type(_ text: String) {
        for ch in text {
            let label = ch == " " ? "space" : String(ch)
            let k = key(label)
            if !k.waitForExistence(timeout: 5) {
                let dump = app.keyboards.firstMatch.debugDescription
                XCTFail("no key \(label). Keyboard tree:\n" + String(dump.prefix(6000)))
            }
            k.tap()
        }
    }

    func testSlipIsFixedAndBackspaceReverts() throws {
        let field = focusTryField()
        add(XCTAttachment(screenshot: app.screenshot()))
        type("teh ")
        let afterFix = field.value as? String ?? ""
        add(XCTAttachment(screenshot: app.screenshot()))
        XCTAssertTrue(afterFix.lowercased().hasPrefix("the "), "expected 'The ', got '\(afterFix)'")
        key("delete").tap()
        let reverted = field.value as? String ?? ""
        XCTAssertTrue(reverted.lowercased().hasPrefix("teh "), "expected revert to 'teh ', got '\(reverted)'")
        type("lol ")
        let slang = field.value as? String ?? ""
        XCTAssertTrue(slang.lowercased().hasSuffix("lol "), "slang must stay: '\(slang)'")
    }

    func testDoubleSpacePeriodAndCaps() throws {
        let field = focusTryField()
        type("hi there  ok")
        let text = field.value as? String ?? ""
        XCTAssertEqual(text, "Hi there. Ok", "got '\(text)'")
    }
}
