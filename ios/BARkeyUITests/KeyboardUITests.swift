import XCTest

/// Types on the real BARkey keyboard inside the app's "Try the keyboard" field.
///
/// A custom keyboard runs in its own process, so XCUITest cannot see its keys. The test records where the system
/// keyboard's keys are (same QWERTY geometry), switches to BARkey with the "Next keyboard" button, then taps those
/// coordinates. Run `qa/sim-keyboard.sh <udid>` first (software keyboard, reboot). The test adds BARkey in Settings
/// and allows Full Access if needed.
final class KeyboardUITests: XCTestCase {
    var app: XCUIApplication!
    private var keyCenters: [String: CGPoint] = [:]

    override func setUp() {
        continueAfterFailure = false
        enableKeyboardInSettingsIfNeeded()
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoOnboarded"]
        app.launch()
    }

    // MARK: Settings

    private func enableKeyboardInSettingsIfNeeded() {
        let settings = XCUIApplication(bundleIdentifier: "com.apple.Preferences")
        settings.launch()
        func tapCell(_ label: String, timeout: TimeInterval = 8) -> Bool {
            let cell = settings.cells.staticTexts[label].firstMatch
            if cell.waitForExistence(timeout: timeout) { cell.tap(); return true }
            for q in [settings.buttons[label], settings.staticTexts[label], settings.descendants(matching: .any)[label]] {
                let e = q.firstMatch
                if e.waitForExistence(timeout: 2) { e.tap(); return true }
            }
            return false
        }
        XCTAssertTrue(tapCell("General"), "Settings > General not found")
        XCTAssertTrue(tapCell("Keyboard"), "General > Keyboard not found")
        XCTAssertTrue(tapCell("Keyboards"), "Keyboard > Keyboards not found")
        if !settings.cells.staticTexts["BARkey"].firstMatch.waitForExistence(timeout: 3) {
            XCTAssertTrue(tapCell("Add New Keyboard"), "Add New Keyboard not found")
            XCTAssertTrue(tapCell("BARkey"), "BARkey not listed under third-party keyboards")
            XCTAssertTrue(settings.cells.staticTexts["BARkey"].firstMatch.waitForExistence(timeout: 8), "BARkey did not appear in Keyboards")
        }
        settings.cells.staticTexts["BARkey"].firstMatch.tap()
        let toggle = settings.switches["Allow Full Access"].firstMatch
        if toggle.waitForExistence(timeout: 5), (toggle.value as? String) == "0" {
            toggle.tap()
            let allow = settings.alerts.buttons["Allow"].firstMatch
            if allow.waitForExistence(timeout: 5) { allow.tap() }
        }
        settings.terminate()
    }

    // MARK: Keyboard

    private var nextKeyboard: XCUIElement { app.buttons["Next keyboard"].firstMatch }

    /// True while BARkey is up: the system key map is gone and the switcher no longer offers BARkey as "next".
    private func isBarkey() -> Bool {
        guard nextKeyboard.exists else { return false }
        let next = (nextKeyboard.value as? String) ?? ""
        return !next.localizedCaseInsensitiveContains("BARkey") && !app.keyboards.firstMatch.keys["Q"].exists
    }

    private func recordSystemKeyCenters() {
        let kb = app.keyboards.firstMatch
        for key in kb.keys.allElementsBoundByIndex where key.frame.width > 10 {
            keyCenters[key.label.lowercased()] = CGPoint(x: key.frame.midX, y: key.frame.midY)
        }
        for button in kb.buttons.allElementsBoundByIndex where button.frame.width > 10 {
            keyCenters[button.label.lowercased()] = CGPoint(x: button.frame.midX, y: button.frame.midY)
        }
    }

    private func focusTryField() -> XCUIElement {
        let field = app.textViews.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 10))
        field.tap()
        // With a custom keyboard up there is no "Keyboard" element at all; the switcher button is the one constant.
        if !nextKeyboard.waitForExistence(timeout: 6) { field.tap() }
        XCTAssertTrue(nextKeyboard.waitForExistence(timeout: 10), "no keyboard appeared (no Next keyboard button): is BARkey enabled?")
        // Record the system keyboard's key geometry first (same QWERTY frames as BARkey).
        for _ in 0..<3 where !app.keyboards.firstMatch.keys["Q"].exists {
            nextKeyboard.tap(); sleep(2)
        }
        XCTAssertTrue(app.keyboards.firstMatch.keys["Q"].waitForExistence(timeout: 5), "could not reach the system keyboard to record key positions")
        recordSystemKeyCenters()
        for _ in 0..<3 where !isBarkey() {
            nextKeyboard.tap(); sleep(2)
        }
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = "keyboard up"; a.lifetime = .keepAlways; add(a)
        XCTAssertTrue(isBarkey(), "could not switch to BARkey (next: \(String(describing: nextKeyboard.value)))")
        XCTAssertFalse(keyCenters.isEmpty, "no key geometry recorded")
        return field
    }

    private func tapKey(_ label: String) {
        let names = label == " " ? ["space"] : label == "⌫" ? ["delete", "backspace"] : [label.lowercased()]
        guard let center = names.compactMap({ keyCenters[$0] }).first else { return XCTFail("no geometry for key \(label)") }
        app.coordinate(withNormalizedOffset: .zero).withOffset(CGVector(dx: center.x, dy: center.y)).tap()
        usleep(label == " " ? 60_000 : 120_000)
    }

    private func type(_ text: String) {
        var previous: Character? = nil
        for ch in text {
            // A human pause before a space so the bar has caught up; but a second space is a quick double-tap.
            if ch == " " && previous != " " { usleep(350_000) }
            tapKey(String(ch))
            previous = ch
        }
    }

    private func fieldText(_ field: XCUIElement) -> String { (field.value as? String) ?? "" }

    // MARK: Tests

    func testSlipIsFixedAndBackspaceReverts() throws {
        let field = focusTryField()
        type("teh ")
        let afterFix = fieldText(field)
        add(XCTAttachment(screenshot: app.screenshot()))
        XCTAssertTrue(afterFix.lowercased().hasPrefix("the "), "expected 'The ', got '\(afterFix)'")
        tapKey("⌫")
        usleep(300_000)
        let reverted = fieldText(field)
        XCTAssertTrue(reverted.lowercased().hasPrefix("teh "), "expected revert to 'teh ', got '\(reverted)'")
        type("lol ")
        let slang = fieldText(field)
        XCTAssertTrue(slang.lowercased().hasSuffix("lol "), "slang must stay: '\(slang)'")
    }

    func testDoubleSpacePeriodAndCaps() throws {
        let field = focusTryField()
        type("hi there  ok")
        let text = fieldText(field)
        XCTAssertEqual(text, "Hi there. Ok", "got '\(text)'")
    }
}
