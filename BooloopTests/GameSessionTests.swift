import XCTest
import BooloopCore
@testable import Booloop

/// Oturum kuralları: geri al (§2.7), çıkmaz göstergesi ve zamanlaması (§2.8, §14 madde 1),
/// hamle hakkı ve başarısızlık (§2.6).
final class GameSessionTests: XCTestCase {
    private func freshSettings() -> DevSettings {
        let suite = "BooloopTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        return DevSettings(defaults: defaults)
    }

    /// İlk hamlesi çıkmaza götüren, çıkmazdan sonra da en az bir geçerli hamlesi olan bir seviye.
    /// FTUE geri al seviyesi zamanlama ayarını yok saydığı için atlanır.
    private func deadFirstMove() -> (LevelPack.Entry, Direction)? {
        for entry in LevelCatalog.adventure where entry.id != GameSession.ftueUndoLevel {
            let solver = Solver(level: entry.level)
            for direction in Direction.allCases {
                guard let after = entry.level.slide(entry.level.start, direction),
                      solver.solve(from: after) == .dead,
                      Direction.allCases.contains(where: { entry.level.slide(after, $0) != nil })
                else { continue }
                return (entry, direction)
            }
        }
        return nil
    }

    func testUndoRestoresStateWithoutRefund() {
        let entry = LevelCatalog.entry(4)
        let session = GameSession(entry: entry, settings: freshSettings())
        let start = session.state
        XCTAssertFalse(session.canUndo)
        XCTAssertFalse(session.undo())
        XCTAssertNotNil(session.swipe(entry.solution[0]))
        XCTAssertEqual(session.movesUsed, 1)
        XCTAssertTrue(session.canUndo)
        XCTAssertTrue(session.undo())
        XCTAssertEqual(session.state, start)
        XCTAssertEqual(session.movesUsed, 1, "geri al hamleyi iade etmez (§2.7)")
        XCTAssertEqual(session.undoCount, 1)
    }

    func testInvalidSwipeChangesNothing() throws {
        let entry = try XCTUnwrap(LevelCatalog.adventure.first { e in
            Direction.allCases.contains { e.level.slide(e.level.start, $0) == nil }
        })
        let session = GameSession(entry: entry, settings: freshSettings())
        let invalid = try XCTUnwrap(Direction.allCases.first { entry.level.slide(entry.level.start, $0) == nil })
        XCTAssertNil(session.swipe(invalid))
        XCTAssertEqual(session.movesUsed, 0)
        XCTAssertEqual(session.state, entry.level.start)
    }

    func testImmediateDeadEndIndicator() throws {
        let (entry, direction) = try XCTUnwrap(deadFirstMove(), "ilk 40 seviyede çıkmaza götüren ilk hamle bekleniyordu")
        let settings = freshSettings()
        settings.deadEndTiming = .immediate
        let session = GameSession(entry: entry, settings: settings)
        XCTAssertFalse(session.showsDeadEnd)
        XCTAssertNotNil(session.swipe(direction))
        XCTAssertTrue(session.showsDeadEnd, "anında gösterge hamleden hemen sonra yanar")
        XCTAssertTrue(session.undo())
        XCTAssertFalse(session.showsDeadEnd, "geri alınca gösterge söner")
    }

    func testDelayedDeadEndIndicator() throws {
        let (entry, direction) = try XCTUnwrap(deadFirstMove())
        let settings = freshSettings()
        settings.deadEndTiming = .delayed
        let session = GameSession(entry: entry, settings: settings)
        XCTAssertNotNil(session.swipe(direction))
        XCTAssertFalse(session.showsDeadEnd, "gecikmeli gösterge ilk hamlede yanmaz")
        let second = try XCTUnwrap(Direction.allCases.first { entry.level.slide(session.state, $0) != nil })
        XCTAssertNotNil(session.swipe(second))
        XCTAssertTrue(session.showsDeadEnd, "gecikmeli gösterge bir hamle sonra yanar")
        XCTAssertTrue(session.undo())
        XCTAssertFalse(session.showsDeadEnd)
        XCTAssertTrue(session.undo())
        XCTAssertFalse(session.showsDeadEnd)
    }

    func testFTUEUndoLevelIgnoresDelayedSetting() throws {
        let entry = LevelCatalog.entry(GameSession.ftueUndoLevel)
        let solver = Solver(level: entry.level)
        let direction = try XCTUnwrap(Direction.allCases.first { d in
            entry.level.slide(entry.level.start, d).map { solver.solve(from: $0) == .dead } ?? false
        }, "FTUE 4. seviyede çıkmaza götüren ilk hamle bekleniyordu (§5)")
        let settings = freshSettings()
        settings.deadEndTiming = .delayed
        let session = GameSession(entry: entry, settings: settings)
        XCTAssertEqual(session.effectiveDeadEndTiming, .immediate)
        XCTAssertNotNil(session.swipe(direction))
        XCTAssertTrue(session.showsDeadEnd, "FTUE 4. seviyede gösterge ayardan bağımsız anında yanar")
        XCTAssertTrue(session.undo())
        XCTAssertFalse(session.showsDeadEnd)
    }

    func testDeadEndNeverShownOnSolutionPath() {
        for entry in LevelCatalog.adventure {
            for timing in DeadEndTiming.allCases {
                let settings = freshSettings()
                settings.deadEndTiming = timing
                let session = GameSession(entry: entry, settings: settings)
                for direction in entry.solution {
                    XCTAssertFalse(session.showsDeadEnd, "bölüm \(entry.id), \(timing)")
                    XCTAssertNotNil(session.swipe(direction), "bölüm \(entry.id)")
                }
                XCTAssertTrue(session.isWon)
                XCTAssertFalse(session.showsDeadEnd)
            }
        }
    }

    func testChapterOneIsUnlimitedAndChapterTwoHasBudget() {
        let settings = freshSettings()
        XCTAssertNil(GameSession(entry: LevelCatalog.entry(20), settings: settings).moveBudget)
        let second = GameSession(entry: LevelCatalog.entry(21), settings: settings)
        XCTAssertEqual(second.moveBudget, LevelCatalog.entry(21).moves)
        XCTAssertEqual(second.movesLeft, second.moveBudget)
    }

    func testFailureWhenBudgetRunsOut() throws {
        let entry = LevelCatalog.entry(21)
        let session = GameSession(entry: entry, settings: freshSettings())
        let budget = try XCTUnwrap(session.moveBudget)
        // Kazanmayan geçerli hamlelerle hakkı tüket.
        while !session.isOver {
            let move = Direction.allCases.first { direction in
                guard let next = entry.level.slide(session.state, direction) else { return false }
                return !entry.level.isWon(next)
            }
            guard let move else { break }
            XCTAssertNotNil(session.swipe(move))
        }
        XCTAssertTrue(session.isFailed, "hak bitince seviye başarısız (§2.6)")
        XCTAssertEqual(session.movesUsed, budget)
        XCTAssertEqual(session.movesLeft, 0)
        XCTAssertFalse(session.canUndo)
        XCTAssertNil(session.swipe(.up), "bitmiş seviyede hamle kabul edilmez")
        session.restart()
        XCTAssertEqual(session.movesUsed, 0)
        XCTAssertFalse(session.isOver)
    }

    func testStars() {
        let entry = LevelCatalog.entry(2)   // par 2
        let session = GameSession(entry: entry, settings: freshSettings())
        XCTAssertEqual(session.stars, 0)
        for direction in entry.solution { XCTAssertNotNil(session.swipe(direction)) }
        XCTAssertEqual(session.stars, 3)
    }
}
