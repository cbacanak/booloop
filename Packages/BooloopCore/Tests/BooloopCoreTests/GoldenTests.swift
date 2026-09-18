import Foundation
import Testing
@testable import BooloopCore

// Altın testler (PLAN.md §10.2). Tek kaynak depodaki data/levels-200.json;
// kayma verisi tools/make_slide_golden.py ile Python referansından üretilir.

private let testsDir = URL(fileURLWithPath: #filePath).deletingLastPathComponent()
private let repoRoot = testsDir.deletingLastPathComponent().deletingLastPathComponent()
    .deletingLastPathComponent().deletingLastPathComponent()

private let pack: LevelPack = {
    let data = try! Data(contentsOf: repoRoot.appending(path: "data/levels-200.json"))
    return try! LevelPack(data: data)
}()

@Suite struct GoldenTests {
    @Test func packMeta() {
        #expect(pack.rulesVersion == LevelPack.rulesVersion)
        #expect(pack.entries.count == 200)
        #expect(pack.entries.map(\.id) == Array(1...200))
    }

    /// Değişmez 3: kayıtlı çözüm kazanır ve uzunluğu par'a eşittir.
    @Test(arguments: pack.entries)
    func solutionWins(_ e: LevelPack.Entry) throws {
        #expect(e.solution.count == e.par)
        let s = try #require(e.level.replay(e.solution), "bölüm \(e.id): geçersiz hamle")
        #expect(e.level.isWon(s), "bölüm \(e.id)")
    }

    /// Değişmez 4: hamle hakkı ≥ par.
    @Test func moveBudgetCoversPar() {
        for e in pack.entries {
            if let m = e.moves { #expect(m >= e.par, "bölüm \(e.id)") }
        }
    }

    /// Swift çözücü Python ile aynı par'ı bulur.
    @Test(arguments: pack.entries)
    func solverFindsPar(_ e: LevelPack.Entry) throws {
        guard case .solvable(let path) = Solver(level: e.level).solve() else {
            Issue.record("bölüm \(e.id): çözülemedi"); return
        }
        #expect(path.count == e.par, "bölüm \(e.id)")
        #expect(e.level.isWon(try #require(e.level.replay(path))), "bölüm \(e.id)")
    }

    /// Değişmez 1: rastgele hamle dizilerinde her adım Python referansıyla aynı.
    @Test func slideMatchesPython() throws {
        let data = try Data(contentsOf: testsDir.appending(path: "Fixtures/slide-golden.json"))
        let golden = try JSONDecoder().decode(SlideGolden.self, from: data)
        #expect(golden.rules_version == LevelPack.rulesVersion)
        let byId = Dictionary(uniqueKeysWithValues: pack.entries.map { ($0.id, $0.level) })
        var checked = 0
        for walk in golden.walks {
            let level = try #require(byId[walk.id])
            var s = level.start
            for (i, (move, expected)) in zip(walk.moves, walk.states).enumerated() {
                let n = level.slide(s, try #require(Direction(rawValue: move)))
                #expect(n.map { encode(level, $0) } == expected, "bölüm \(walk.id), hamle \(i)")
                if n == nil && expected != nil || n != nil && expected == nil { break }
                if let n { s = n }
                checked += 1
            }
        }
        #expect(checked > 10_000)
    }

    @Test func slideStepsEndInSlideResult() throws {
        for e in pack.entries {
            var s = e.level.start
            for d in e.solution {
                let r = try #require(e.level.slideSteps(s, d), "bölüm \(e.id)")
                #expect(r.state == e.level.slide(s, d))
                s = r.state
            }
        }
    }
}

extension LevelPack.Entry: CustomTestStringConvertible {
    public var testDescription: String { "#\(id)" }
}

private struct SlideGolden: Decodable {
    struct Walk: Decodable { let id: Int; let moves: [Int]; let states: [Encoded?] }
    let rules_version: Int
    let walks: [Walk]
}

/// Python `enc`: [gövde [[x,y]], renkler, kalan ruhlar [[x,y,renk]] (konuma göre sıralı), doluluk]
private struct Encoded: Decodable, Equatable {
    let body: [[Int]], colors: [Int], wisps: [[Int]], fill: [Int]
    init(body: [[Int]], colors: [Int], wisps: [[Int]], fill: [Int]) {
        self.body = body; self.colors = colors; self.wisps = wisps; self.fill = fill
    }
    init(from decoder: Decoder) throws {
        var c = try decoder.unkeyedContainer()
        body = try c.decode([[Int]].self); colors = try c.decode([Int].self)
        wisps = try c.decode([[Int]].self); fill = try c.decode([Int].self)
    }
}

private func encode(_ level: Level, _ s: State) -> Encoded {
    let wisps = level.wisps.indices.filter(s.hasWisp).map { level.wisps[$0] }
        .sorted { ($0.position.x, $0.position.y) < ($1.position.x, $1.position.y) }
        .map { [$0.position.x, $0.position.y, $0.color] }
    return Encoded(body: s.body.map { let p = level.point($0); return [p.x, p.y] },
                   colors: s.colors.map(Int.init), wisps: wisps, fill: s.fill.map(Int.init))
}
