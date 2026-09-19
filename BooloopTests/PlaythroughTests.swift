import XCTest
import BooloopCore
@testable import Booloop

/// Sahne entegrasyon testi (Aşama 2): ilk 40 seviyenin kayıtlı çözümü `GameViewController`
/// üzerinden, sahne adımları anında uygulanarak oynatılır. Hepsi kazanır, sahne her hamlede
/// oturumun durumunu çizer (PLAN.md §2.10 değişmez 3; §10.2 altın test 1'in sahne karşılığı).
@MainActor
final class PlaythroughTests: XCTestCase {
    private func makeController(_ number: Int) -> GameViewController {
        let vc = GameViewController(levelNumber: number)
        vc.instantAnimations = true
        vc.view.frame = CGRect(x: 0, y: 0, width: 393, height: 852)
        vc.view.layoutIfNeeded()
        return vc
    }

    func testRecordedSolutionsWinThroughScene() {
        Progress.shared.reset()
        defer { Progress.shared.reset() }
        for number in 1...LevelCatalog.adventureCount {
            let vc = makeController(number)
            let entry = vc.session.entry
            XCTAssertEqual(entry.id, number)
            XCTAssertEqual(entry.solution.count, entry.par, "seviye \(number): çözüm uzunluğu par değil")
            XCTAssertEqual(vc.scene.current, entry.level.start, "seviye \(number): sahne başlangıç durumunda değil")
            XCTAssertGreaterThan(vc.scene.cellSize, 0, "seviye \(number): tahta yerleşmedi")

            for (i, direction) in entry.solution.enumerated() {
                XCTAssertFalse(vc.session.showsDeadEnd, "seviye \(number) hamle \(i): çözüm yolunda çıkmaz göstergesi")
                XCTAssertTrue(vc.swipe(direction), "seviye \(number) hamle \(i): kaydırma kabul edilmedi")
                XCTAssertEqual(vc.scene.current, vc.session.state, "seviye \(number) hamle \(i): sahne durumu oturumdan farklı")
                XCTAssertEqual(vc.scene.segmentCount, vc.session.state.body.count - 1, "seviye \(number) hamle \(i): gövde parçası sayısı")
                XCTAssertEqual(vc.scene.ghostPosition, vc.scene.position(ofCell: vc.session.state.body[0]),
                               "seviye \(number) hamle \(i): hayalet yanlış karede")
            }

            XCTAssertTrue(vc.session.isWon, "seviye \(number): çözüm kazanmadı")
            XCTAssertEqual(vc.session.movesUsed, entry.par)
            XCTAssertEqual(vc.session.stars, 3, "seviye \(number): par'da 3 yıldız")
            XCTAssertEqual(vc.scene.litLanternCount, entry.level.lanterns.count, "seviye \(number): bütün fenerler yanmalı")
            XCTAssertTrue(vc.isShowingOverlay, "seviye \(number): bitiş ekranı yok")
            XCTAssertFalse(vc.swipe(entry.solution[0]), "seviye \(number): bitmiş seviyede kaydırma kabul edilmemeli")
        }
        XCTAssertTrue(Progress.shared.isUnlocked(LevelCatalog.adventureCount))
        XCTAssertEqual(Progress.shared.stars(for: LevelCatalog.adventureCount), 3)
    }

    func testUndoThroughSceneRestoresBoard() {
        let vc = makeController(2)
        let entry = vc.session.entry
        let start = vc.scene.current
        XCTAssertFalse(vc.undo(), "başta geri al yok")
        XCTAssertTrue(vc.swipe(entry.solution[0]))
        XCTAssertNotEqual(vc.scene.current, start)
        XCTAssertTrue(vc.undo())
        XCTAssertEqual(vc.scene.current, start)
        XCTAssertEqual(vc.scene.ghostPosition, vc.scene.position(ofCell: start.body[0]))
        XCTAssertEqual(vc.session.movesUsed, 1, "geri al hamleyi iade etmez (§2.7)")
    }

    func testInvalidSwipeIsRejectedWithoutCounting() throws {
        // Başlangıçta geçersiz bir yönü olan ilk seviye (kenar ya da mezar taşı).
        let entry = try XCTUnwrap(LevelCatalog.adventure.first { e in
            Direction.allCases.contains { e.level.slide(e.level.start, $0) == nil }
        })
        let vc = makeController(entry.id)
        let level = vc.session.level
        let invalid = try XCTUnwrap(Direction.allCases.first { level.slide(level.start, $0) == nil })
        XCTAssertFalse(vc.swipe(invalid))
        XCTAssertEqual(vc.session.movesUsed, 0)
        XCTAssertEqual(vc.scene.current, level.start)
    }

    func testRestartClearsBoard() {
        Progress.shared.reset()
        defer { Progress.shared.reset() }
        let vc = makeController(3)
        let entry = vc.session.entry
        XCTAssertTrue(vc.swipe(entry.solution[0]))
        vc.restart()
        XCTAssertEqual(vc.session.movesUsed, 0)
        XCTAssertEqual(vc.scene.current, entry.level.start)
        XCTAssertFalse(vc.isShowingOverlay)
    }
}
