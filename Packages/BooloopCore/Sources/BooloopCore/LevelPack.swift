import Foundation

/// `data/levels-200.json` (PLAN.md §4.5).
public struct LevelPack: Sendable {
    /// Bu çekirdeğin uyguladığı kural sürümü (PLAN.md §2).
    public static let rulesVersion = 1

    public let schema: Int
    public let rulesVersion: Int
    public let entries: [Entry]

    public struct Entry: Sendable {
        public let id: Int
        public let chapter: String
        public let level: Level
        public let par: Int
        /// Hamle hakkı; `nil` = sınırsız.
        public let moves: Int?
        public let solution: [Direction]
        public let intro: Bool
    }

    public enum LoadError: Error, Equatable {
        case unsupportedSchema(Int)
        case unsupportedRules(Int)
        case countMismatch(expected: Int, actual: Int)
        case level(id: Int, LevelError)
    }

    public init(data: Data) throws {
        let raw = try JSONDecoder().decode(RawPack.self, from: data)
        guard raw.meta.schema == 1 else { throw LoadError.unsupportedSchema(raw.meta.schema) }
        guard raw.meta.rules_version == Self.rulesVersion else { throw LoadError.unsupportedRules(raw.meta.rules_version) }
        guard raw.meta.count == raw.levels.count else {
            throw LoadError.countMismatch(expected: raw.meta.count, actual: raw.levels.count)
        }
        schema = raw.meta.schema
        rulesVersion = raw.meta.rules_version
        entries = try raw.levels.map { r in
            do {
                return Entry(id: r.id, chapter: r.chapter, level: try r.level.make(), par: r.par, moves: r.moves,
                             solution: try r.solution.map(direction), intro: r.intro)
            } catch let e as LevelError {
                throw LoadError.level(id: r.id, e)
            }
        }
    }
}

// MARK: - JSON biçimi

private struct RawPack: Decodable {
    struct Meta: Decodable { let schema: Int; let rules_version: Int; let count: Int }
    let meta: Meta
    let levels: [RawEntry]
}

private struct RawEntry: Decodable {
    let id: Int
    let chapter: String
    let level: RawLevel
    let par: Int
    let moves: Int?
    let solution: [Int]
    let intro: Bool
}

private struct RawLevel: Decodable {
    let w: Int, h: Int
    let walls: [[Int]], webs: [[Int]], arrows: [[Int]], gates: [[Int]]
    let head: [Int]
    let lanterns: [[Int]], wisps: [[Int]]

    func make() throws -> Level {
        func point(_ a: [Int], _ n: Int) throws -> Point {
            guard a.count == n else { throw LevelError.malformed("\(a)") }
            return Point(a[0], a[1])
        }
        var arrowMap: [Point: Direction] = [:]
        for a in arrows { arrowMap[try point(a, 3)] = try direction(a[2]) }
        var gateMap: [Point: Int] = [:]
        for g in gates { gateMap[try point(g, 3)] = g[2] }
        return try Level(
            width: w, height: h,
            walls: try walls.map { try point($0, 2) },
            webs: try webs.map { try point($0, 2) },
            arrows: arrowMap, gates: gateMap,
            head: try point(head, 2),
            lanterns: try lanterns.map { Lantern(position: try point($0, 4), color: $0[2], capacity: $0[3]) },
            wisps: try wisps.map { Wisp(position: try point($0, 3), color: $0[2]) })
    }
}

private func direction(_ raw: Int) throws -> Direction {
    guard let d = Direction(rawValue: raw) else { throw LevelError.badDirection(raw) }
    return d
}
