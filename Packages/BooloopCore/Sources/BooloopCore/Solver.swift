/// Durum sınırlı BFS çözücü (PLAN.md §10.2). İki kullanım: ipucu (en kısa
/// çözümün ilk hamlesi) ve çıkmaz tespiti (§2.8).
public struct Solver: Sendable {
    public enum Outcome: Sendable, Equatable {
        /// En kısa çözüm; kazanılmış durumda boş.
        case solvable([Direction])
        /// Ulaşılabilir her durum tarandı, hiçbiri kazanmıyor.
        case dead
        /// Durum sınırı aşıldı; gösterge konuşmaz (§2.8).
        case unknown
    }

    public let level: Level
    /// Keşfedilen en fazla durum sayısı. Ölçümde bölüm başına ~60 bin (§10.2).
    public var stateLimit: Int

    public init(level: Level, stateLimit: Int = 200_000) {
        self.level = level
        self.stateLimit = stateLimit
    }

    public func solve(from state: State? = nil) -> Outcome {
        let root = state ?? level.start
        if level.isWon(root) { return .solvable([]) }

        var states: [State] = [root]
        var parent: [Int32] = [-1]
        var move: [UInt8] = [0]
        var index: [State: Int32] = [root: 0]
        var head = 0

        while head < states.count {
            let s = states[head]
            for d in Direction.allCases {
                guard let n = level.slide(s, d), index[n] == nil else { continue }
                let i = Int32(states.count)
                states.append(n); parent.append(Int32(head)); move.append(UInt8(d.rawValue))
                index[n] = i
                // BFS: ilk bulunan kazanan durum en kısa yoldadır.
                if level.isWon(n) { return .solvable(path(to: Int(i), parent: parent, move: move)) }
                if states.count > stateLimit { return .unknown }
            }
            head += 1
        }
        return .dead
    }

    /// İpucu: en kısa çözümün ilk hamlesi. Çıkmaz, kazanılmış ya da bilinmiyorsa `nil`.
    public func hint(from state: State) -> Direction? {
        if case .solvable(let path) = solve(from: state) { return path.first }
        return nil
    }

    private func path(to i: Int, parent: [Int32], move: [UInt8]) -> [Direction] {
        var out: [Direction] = []
        var c = i
        while parent[c] >= 0 {
            out.append(Direction(rawValue: Int(move[c]))!)
            c = Int(parent[c])
        }
        return out.reversed()
    }
}
