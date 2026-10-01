import XCTest

/// 上架截图采集:语言由外部写入 App Group(jev.language.v1),本测试只负责导航和截图。
/// 机型要求:iPhone 16 Pro Max 级别(1320×2868)。跑之前把 App 数据清干净(未唤起键盘的状态)。
/// 用法:SHOT_LANG=zh|en 注入 launchEnvironment 决定附件名后缀。
final class ScreenshotTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    func testCaptureStoreScreenshots() throws {
        let suffix = ProcessInfo.processInfo.environment["SHOT_LANG"] ?? "zh"
        let app = XCUIApplication()
        app.launch()
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 15))
        sleep(2)

        // 开始页(状态区 + 三步启用)
        snap(app, name: "03-home-\(suffix)")

        // 模型页(判断层 + 生成层顶部)
        let modelsTab = tabBar.buttons["模型"].exists ? tabBar.buttons["模型"] : tabBar.buttons["Models"]
        XCTAssertTrue(modelsTab.waitForExistence(timeout: 8))
        modelsTab.tap()
        sleep(2)
        snap(app, name: "02-models-\(suffix)")
    }

    /// 全屏截图存为 attachment(导出时用这个名字)
    private func snap(_ app: XCUIApplication, name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
