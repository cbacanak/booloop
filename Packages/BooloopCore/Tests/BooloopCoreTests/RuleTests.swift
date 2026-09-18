import Testing
@testable import BooloopCore

// Elle yazılmış kural vakaları (PLAN.md §10.2, altın test 3). Beklenen sonuçlar
// tools/booloop_gen.py ile doğrulandı.

private func P(_ x: Int, _ y: Int) -> Point { Point(x, y) }
private func L(_ x: Int, _ y: Int, _ c: Int, _ k: Int = 1) -> Lantern { Lantern(position: P(x, y), color: c, capacity: k) }
private func W(_ x: Int, _ y: Int, _ c: Int) -> Wisp { Wisp(position: P(x, y), color: c) }

private extension Level {
    func bodyPoints(_ s: State) -> [Point] { s.body.map { point($0) } }
}

@Suite struct RuleTests {
    /// 4×2, üç ruh toplanınca gövde 2×2'lik bir halka kurar.
    let ring = try! Level(width: 4, height: 2, walls: [P(2, 0)], head: P(0, 0),
                          lanterns: [L(3, 0, 0), L(3, 1, 1), L(2, 1, 2)],
                          wisps: [W(1, 0, 0), W(1, 1, 1), W(0, 1, 2)])

    @Test func collectingGrowsBehindHead() throws {
        let s = try #require(ring.replay([.right, .down]))
        #expect(ring.bodyPoints(s) == [P(1, 1), P(1, 0), P(0, 0)])
        #expect(s.colors == [1, 0])               // en önce toplanan kuyruk ucunda
        #expect(s.wisps == 0b100)
    }

    @Test func bodyBlocks() throws {
        let s = try #require(ring.replay([.right, .down]))
        #expect(ring.slide(s, .up) == nil)        // (1,0) gövde
    }

    @Test func vacatingTailDoesNotBlock() throws {
        let s = try #require(ring.replay([.right, .down, .left, .up]))
        #expect(ring.bodyPoints(s) == [P(0, 0), P(0, 1), P(1, 1), P(1, 0)])
        let t = try #require(ring.slide(s, .right))
        #expect(ring.bodyPoints(t) == [P(1, 0), P(0, 0), P(0, 1), P(1, 1)])
    }

    @Test func invalidSlide() {
        #expect(ring.slide(ring.start, .left) == nil)
        #expect(ring.slide(ring.start, .up) == nil)
    }

    @Test func chainDeposit() throws {
        let level = try Level(width: 7, height: 1, head: P(0, 0),
                              lanterns: [L(3, 0, 0), L(4, 0, 1)], wisps: [W(1, 0, 0), W(2, 0, 1)])
        let r = try #require(level.slideSteps(level.start, .right))
        #expect(r.steps.count == 5)               // bütün fenerler dolunca durur
        #expect(r.steps.map(\.collected) == [0, 1, nil, nil, nil])
        #expect(r.steps.last?.deposited == [0, 1])
        #expect(level.bodyPoints(r.state) == [P(5, 0)])
        #expect(level.isWon(r.state))
        #expect(level.slide(r.state, .right) == nil)
    }

    @Test func webStops() throws {
        let level = try Level(width: 5, height: 1, webs: [P(2, 0)], head: P(0, 0),
                              lanterns: [L(3, 0, 0)], wisps: [W(4, 0, 0)])
        let s = try #require(level.slide(level.start, .right))
        #expect(level.bodyPoints(s) == [P(2, 0)])
    }

    @Test func arrowLoopIsCut() throws {
        let level = try Level(width: 3, height: 3,
                              arrows: [P(1, 0): .down, P(1, 1): .left, P(0, 1): .up, P(0, 0): .right],
                              head: P(2, 0), lanterns: [L(2, 1, 0)], wisps: [W(2, 2, 0)])
        let r = try #require(level.slideSteps(level.start, .left))
        #expect(r.steps.count == 3 * 3 * 4)
        #expect(level.bodyPoints(r.state) == [P(0, 0)])
        #expect(r.steps.prefix(4).map(\.direction) == [.left, .down, .left, .up])
    }

    @Test func gateOpensWhenLanternFull() throws {
        let level = try Level(width: 5, height: 2, gates: [P(2, 1): 0], head: P(0, 0),
                              lanterns: [L(3, 0, 0), L(1, 1, 1)], wisps: [W(1, 0, 0), W(4, 1, 1)])
        let closed = try #require(level.replay([.down, .right]))
        #expect(level.bodyPoints(closed) == [P(1, 1)])
        let won = try #require(level.replay([.right, .down, .left]))
        #expect(level.isWon(won))
    }

    @Test func wrongColorLanternIgnored() throws {
        let level = try Level(width: 5, height: 1, head: P(0, 0),
                              lanterns: [L(2, 0, 1), L(4, 0, 0)], wisps: [W(1, 0, 0), W(3, 0, 1)])
        let s = try #require(level.replay([.right]))
        #expect(s.fill == [0, 0])
    }

    @Test func solverOutcomes() throws {
        let level = try Level(width: 4, height: 4, walls: [P(3, 1)], head: P(1, 1),
                              lanterns: [L(2, 1, 0)], wisps: [W(2, 3, 0)])
        let solver = Solver(level: level)
        guard case .solvable(let path) = solver.solve() else { Issue.record("çözülebilir olmalı"); return }
        #expect(path.count == 3)
        #expect(level.isWon(try #require(level.replay(path))))
        let lost = try #require(level.slide(level.start, .up))
        #expect(solver.solve(from: lost) == .dead)
        #expect(Solver(level: level, stateLimit: 1).solve() == .unknown)
    }

    @Test func rejectsBadLevels() {
        #expect(throws: LevelError.overlap(P(0, 0))) {
            try Level(width: 2, height: 1, walls: [P(0, 0)], head: P(0, 0), lanterns: [L(1, 0, 0)], wisps: [])
        }
        #expect(throws: LevelError.wispCountMismatch(color: 0)) {
            try Level(width: 3, height: 1, head: P(0, 0), lanterns: [L(1, 0, 0, 2)], wisps: [W(2, 0, 0)])
        }
        #expect(throws: LevelError.outOfBounds(P(3, 0))) {
            try Level(width: 3, height: 1, head: P(3, 0), lanterns: [], wisps: [])
        }
    }
}
