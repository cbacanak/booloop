import XCTest
import BooloopCore
@testable import Booloop

/// Hamle hakkı (PLAN.md §2.6): varsayılan çarpanlar `build_levels.move_budget` ile aynı
/// sonucu verir; geliştirici ayarı yalnızca çarpanı değiştirir, hak hiçbir zaman par'ın altına inmez.
final class MoveBudgetTests: XCTestCase {
    private func freshSettings() -> DevSettings {
        let suite = "BooloopTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return DevSettings(defaults: defaults)
    }

    func testDefaultMultipliersReproducePackBudgets() {
        let settings = freshSettings()
        XCTAssertEqual(settings.multipliers, DevSettings.defaultMultipliers)
        for entry in LevelCatalog.pack.entries {
            XCTAssertEqual(settings.moveBudget(for: entry), entry.moves, "bölüm \(entry.id)")
        }
    }

    func testBudgetNeverBelowPar() {
        let settings = freshSettings()
        for band in 0..<DevSettings.bands.count { settings.setMultiplier(0, band: band) }
        for entry in LevelCatalog.pack.entries {
            if let budget = settings.moveBudget(for: entry) {
                XCTAssertGreaterThanOrEqual(budget, entry.par + 3, "bölüm \(entry.id)")
            }
        }
    }

    func testPythonHalfToEvenRounding() {
        XCTAssertEqual(DevSettings.budget(par: 6, multiplier: 0.75), 10)   // 4.5 → 4
        XCTAssertEqual(DevSettings.budget(par: 10, multiplier: 0.75), 18)  // 7.5 → 8
        XCTAssertEqual(DevSettings.budget(par: 4, multiplier: 0.5), 7)     // max(3, 2)
        XCTAssertEqual(DevSettings.budget(par: 7, multiplier: 1.0), 14)
    }

    func testChapterBands() {
        XCTAssertNil(DevSettings.band(forChapter: 1))
        XCTAssertEqual(DevSettings.band(forChapter: 2), 0)
        XCTAssertEqual(DevSettings.band(forChapter: 3), 0)
        XCTAssertEqual(DevSettings.band(forChapter: 4), 1)
        XCTAssertEqual(DevSettings.band(forChapter: 7), 1)
        XCTAssertEqual(DevSettings.band(forChapter: 8), 2)
        XCTAssertEqual(DevSettings.band(forChapter: 10), 2)
        XCTAssertEqual(LevelCatalog.chapter(of: LevelCatalog.entry(20)), 1)
        XCTAssertEqual(LevelCatalog.chapter(of: LevelCatalog.entry(21)), 2)
    }

    func testSettingsPersistInDefaults() {
        let suite = "BooloopTests.persist"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        let a = DevSettings(defaults: defaults)
        a.deadEndTiming = .delayed
        a.setMultiplier(1.25, band: 1)
        let b = DevSettings(defaults: defaults)
        XCTAssertEqual(b.deadEndTiming, .delayed)
        XCTAssertEqual(b.multipliers[1], 1.25)
        b.resetToDefaults()
        XCTAssertEqual(DevSettings(defaults: defaults).multipliers, DevSettings.defaultMultipliers)
        defaults.removePersistentDomain(forName: suite)
    }
}
