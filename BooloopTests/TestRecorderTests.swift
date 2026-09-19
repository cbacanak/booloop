import XCTest
import BooloopCore
@testable import Booloop

/// Test oturumu kaydı (PLAN.md §8.3): olaylar doğru sırayla ve alanlarla yazılır, oturum yokken
/// hiçbir şey yazılmaz, eski oturumlar silinmez. Olaylar sahne üzerinden oynatılarak üretilir.
@MainActor
final class TestRecorderTests: XCTestCase {
    private final class Clock {
        var now = Date(timeIntervalSince1970: 1_789_800_000)
        func advance(_ seconds: TimeInterval) { now += seconds }
    }

    private var directory: URL!
    private var defaults: UserDefaults!
    private var clock: Clock!

    override func setUp() {
        super.setUp()
        directory = FileManager.default.temporaryDirectory.appending(path: "TestRecorderTests-\(UUID().uuidString)")
        let suite = "TestRecorderTests.\(UUID().uuidString)"
        defaults = UserDefaults(suiteName: suite)!
        defaults.removePersistentDomain(forName: suite)
        clock = Clock()
        Progress.shared.reset()
    }

    override func tearDown() {
        try? FileManager.default.removeItem(at: directory)
        Progress.shared.reset()
        super.tearDown()
    }

    private func makeRecorder() -> TestRecorder {
        let clock = self.clock!
        return TestRecorder(directory: directory, defaults: defaults, clock: { clock.now })
    }

    private func makeController(_ number: Int, recorder: TestRecorder) -> GameViewController {
        let vc = GameViewController(levelNumber: number)
        vc.recorder = recorder
        vc.instantAnimations = true
        vc.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        vc.view.layoutIfNeeded()
        return vc
    }

    private func freshSettings() -> DevSettings {
        let suite = "TestRecorderTests.settings.\(UUID().uuidString)"
        return DevSettings(defaults: UserDefaults(suiteName: suite)!)
    }

    func testNothingIsWrittenWithoutSession() {
        let recorder = makeRecorder()
        let vc = makeController(1, recorder: recorder)
        for direction in vc.session.entry.solution { XCTAssertTrue(vc.swipe(direction)) }
        XCTAssertTrue(vc.session.isWon)
        XCTAssertFalse(recorder.isRecording)
        XCTAssertFalse(FileManager.default.fileExists(atPath: directory.path), "oturum yokken dosya yazılmaz")
        XCTAssertTrue(recorder.sessions().isEmpty)
    }

    /// FTUE 4. seviye: çıkmaza giden hamle, geçersiz kaydırma, geri al, çözüm.
    func testEventOrderAndFieldsOnLevel4() throws {
        let recorder = makeRecorder()
        let session = try recorder.start(tester: "7", settings: freshSettings())
        XCTAssertTrue(session.id.hasPrefix("T7-"))

        clock.advance(5)
        let vc = makeController(4, recorder: recorder)
        let entry = vc.session.entry
        let level = entry.level
        let solver = Solver(level: level)
        let deadMove = try XCTUnwrap(Direction.allCases.first { d in
            level.slide(level.start, d).map { solver.solve(from: $0) == .dead } ?? false
        })
        let afterDead = try XCTUnwrap(level.slide(level.start, deadMove))
        let invalid = try XCTUnwrap(Direction.allCases.first { level.slide(afterDead, $0) == nil },
                                    "çıkmaz durumda geçersiz bir kaydırma bekleniyordu")

        clock.advance(2)
        XCTAssertTrue(vc.swipe(deadMove))
        XCTAssertTrue(vc.session.showsDeadEnd)
        XCTAssertFalse(vc.swipe(invalid))
        XCTAssertTrue(vc.undo())
        XCTAssertFalse(vc.session.showsDeadEnd)
        clock.advance(8)
        for direction in entry.solution { XCTAssertTrue(vc.swipe(direction)) }
        XCTAssertTrue(vc.session.isWon)

        let events = try XCTUnwrap(recorder.current).events
        XCTAssertEqual(events.map(\.name), [.levelStart, .deadendShown, .invalidSwipe, .levelComplete])
        XCTAssertEqual(events.map(\.seq), [1, 2, 3, 4])
        XCTAssertTrue(events.allSatisfy { $0.level == 4 })
        XCTAssertEqual(events.map(\.elapsed), [5, 7, 7, 15])

        XCTAssertEqual(events[1].moveIndex, 1)
        XCTAssertEqual(events[2].moveIndex, 1)
        XCTAssertEqual(events[2].direction, String(describing: invalid))

        let complete = events[3]
        XCTAssertEqual(complete.moves, entry.par + 1, "geri al hamleyi iade etmez (§2.7)")
        XCTAssertEqual(complete.par, entry.par)
        XCTAssertEqual(complete.stars, 2)
        XCTAssertEqual(complete.undoCount, 1)
        XCTAssertEqual(complete.deadendCount, 1)
        XCTAssertEqual(complete.seconds, 10)
        XCTAssertNil(events[0].moves, "level_start yalnızca seviyeyi taşır")

        // Dosyadaki JSON §8.3 alan adlarını kullanır ve yeniden açılınca oturum sürer.
        let file = directory.appending(path: "\(session.id).json")
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: file)) as? [String: Any])
        let last = try XCTUnwrap((json["events"] as? [[String: Any]])?.last)
        XCTAssertEqual(last["event"] as? String, "level_complete")
        XCTAssertEqual(last["undo_count"] as? Int, 1)
        XCTAssertEqual(last["deadend_count"] as? Int, 1)
        XCTAssertNil(last["move_index"], "boş alan yazılmaz")
        XCTAssertEqual(json["tester"] as? String, "7")

        let reopened = makeRecorder()
        XCTAssertEqual(reopened.current, recorder.current)
    }

    func testFailThenRetryStartsNewAttempt() throws {
        let recorder = makeRecorder()
        try recorder.start(tester: "2", settings: freshSettings())
        let vc = makeController(21, recorder: recorder)
        let budget = try XCTUnwrap(vc.session.moveBudget)
        while !vc.session.isOver {
            let level = vc.session.level
            let move = try XCTUnwrap(Direction.allCases.first { d in
                level.slide(vc.session.state, d).map { !level.isWon($0) } ?? false
            })
            XCTAssertTrue(vc.swipe(move))
        }
        XCTAssertTrue(vc.session.isFailed)
        vc.restart()

        let events = try XCTUnwrap(recorder.current).events
        let lifecycle = events.map(\.name).filter { $0 != .deadendShown }
        XCTAssertEqual(lifecycle, [.levelStart, .levelFail, .levelStart])
        let fail = try XCTUnwrap(events.first { $0.name == .levelFail })
        XCTAssertEqual(fail.moves, budget)
        XCTAssertEqual(fail.level, 21)
        XCTAssertEqual(events.map(\.seq), Array(1...events.count))
    }

    func testStopAndNewSessionKeepOldFiles() throws {
        let recorder = makeRecorder()
        let first = try recorder.start(tester: "1", settings: freshSettings())
        recorder.record(.init(name: .levelStart, level: 1))
        clock.advance(60)
        let second = try recorder.start(tester: "2", settings: freshSettings())
        XCTAssertEqual(recorder.current?.id, second.id)
        XCTAssertEqual(recorder.current?.events.count, 0)

        recorder.stop()
        XCTAssertFalse(recorder.isRecording)
        recorder.record(.init(name: .levelStart, level: 1))
        XCTAssertNil(makeRecorder().current, "durdurulan oturum yeniden açılışta sürmez")

        let all = recorder.sessions()
        XCTAssertEqual(all.map(\.id), [second.id, first.id], "eski oturum silinmez, en yenisi önce")
        XCTAssertEqual(all.last?.events.count, 1)
    }

    func testExportWritesCSVAndJSON() throws {
        let recorder = makeRecorder()
        let session = try recorder.start(tester: "3", settings: freshSettings())
        recorder.record(.init(name: .levelStart, level: 1))
        clock.advance(4.25)
        recorder.record(.init(name: .levelComplete, level: 1, moves: 1, par: 1, stars: 3,
                              undoCount: 0, deadendCount: 0, seconds: 4.25))

        let files = try recorder.exportFiles(for: try XCTUnwrap(recorder.current))
        XCTAssertEqual(files.map(\.pathExtension), ["csv", "json"])
        let csv = try String(contentsOf: files[0], encoding: .utf8)
        let rows = csv.split(separator: "\n").map { $0.split(separator: ",", omittingEmptySubsequences: false).map(String.init) }
        XCTAssertEqual(rows.count, 3)
        XCTAssertEqual(rows[0], TestRecorder.csvColumns)
        let col = { (name: String) in TestRecorder.csvColumns.firstIndex(of: name)! }
        XCTAssertEqual(rows[1][col("event")], "level_start")
        XCTAssertEqual(rows[1][col("moves")], "")
        XCTAssertEqual(rows[2][col("session")], session.id)
        XCTAssertEqual(rows[2][col("tester")], "3")
        XCTAssertEqual(rows[2][col("event")], "level_complete")
        XCTAssertEqual(rows[2][col("stars")], "3")
        XCTAssertEqual(rows[2][col("seconds")], "4.250")
        XCTAssertEqual(rows[2][col("elapsed")], "4.250")

        let exported = try JSONSerialization.jsonObject(with: Data(contentsOf: files[1])) as? [String: Any]
        XCTAssertEqual(exported?["id"] as? String, session.id)
        XCTAssertEqual((exported?["events"] as? [Any])?.count, 2)
    }
}
