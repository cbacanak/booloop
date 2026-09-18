/// Kayma yönü (PLAN.md §4.5): 0 yukarı, 1 sağ, 2 aşağı, 3 sol.
public enum Direction: Int, CaseIterable, Sendable, Codable {
    case up = 0, right, down, left

    var dx: Int { self == .right ? 1 : self == .left ? -1 : 0 }
    var dy: Int { self == .down ? 1 : self == .up ? -1 : 0 }
}

public struct Point: Hashable, Sendable {
    public var x: Int
    public var y: Int
    public init(_ x: Int, _ y: Int) { self.x = x; self.y = y }
}

public struct Lantern: Hashable, Sendable {
    public var position: Point
    public var color: Int
    public var capacity: Int
}

public struct Wisp: Hashable, Sendable {
    public var position: Point
    public var color: Int
}

public enum LevelError: Error, Equatable {
    case badSize(Int, Int)
    case outOfBounds(Point)
    case overlap(Point)
    case badDirection(Int)
    case badColor(Int)
    case badCapacity(Int)
    case badGate(Int)
    case wispCountMismatch(color: Int)
    case tooManyWisps(Int)
    case malformed(String)
}

/// Değişmez bölüm tanımı (PLAN.md §2.1). Kareler içeride `x + y*W` indeksiyle tutulur.
public struct Level: Sendable {
    public let width: Int
    public let height: Int
    public let walls: Set<Point>
    public let webs: Set<Point>
    public let arrows: [Point: Direction]
    /// Kapı karesi → bağlı olduğu fenerin indeksi.
    public let gates: [Point: Int]
    public let head: Point
    public let lanterns: [Lantern]
    public let wisps: [Wisp]

    // Kare başına arama tabloları; -1 = yok.
    let wallAt: [Bool]
    let webAt: [Bool]
    let arrowAt: [Int8]
    let gateAt: [Int8]
    let lanternAt: [Int8]
    let wispAt: [Int8]
    let capacities: [UInt8]

    public var cellCount: Int { width * height }

    public init(width: Int, height: Int,
                walls: [Point] = [], webs: [Point] = [],
                arrows: [Point: Direction] = [:], gates: [Point: Int] = [:],
                head: Point, lanterns: [Lantern], wisps: [Wisp]) throws {
        guard width > 0, height > 0, width * height <= 255 else { throw LevelError.badSize(width, height) }
        guard wisps.count <= 32 else { throw LevelError.tooManyWisps(wisps.count) }
        self.width = width; self.height = height
        self.walls = Set(walls); self.webs = Set(webs)
        self.arrows = arrows; self.gates = gates
        self.head = head; self.lanterns = lanterns; self.wisps = wisps

        let n = width * height
        var wallAt = [Bool](repeating: false, count: n)
        var webAt = [Bool](repeating: false, count: n)
        var arrowAt = [Int8](repeating: -1, count: n)
        var gateAt = [Int8](repeating: -1, count: n)
        var lanternAt = [Int8](repeating: -1, count: n)
        var wispAt = [Int8](repeating: -1, count: n)
        var used = [Bool](repeating: false, count: n)

        func claim(_ p: Point) throws -> Int {
            guard p.x >= 0, p.y >= 0, p.x < width, p.y < height else { throw LevelError.outOfBounds(p) }
            let c = p.x + p.y * width
            guard !used[c] else { throw LevelError.overlap(p) }
            used[c] = true
            return c
        }

        _ = try claim(head)
        for p in walls { wallAt[try claim(p)] = true }
        for p in webs { webAt[try claim(p)] = true }
        for (p, d) in arrows { arrowAt[try claim(p)] = Int8(d.rawValue) }
        for (i, l) in lanterns.enumerated() {
            guard (0..<4).contains(l.color) else { throw LevelError.badColor(l.color) }
            guard (1...2).contains(l.capacity) else { throw LevelError.badCapacity(l.capacity) }
            lanternAt[try claim(l.position)] = Int8(i)
        }
        for (p, g) in gates {
            guard lanterns.indices.contains(g) else { throw LevelError.badGate(g) }
            gateAt[try claim(p)] = Int8(g)
        }
        for (i, w) in wisps.enumerated() {
            guard (0..<4).contains(w.color) else { throw LevelError.badColor(w.color) }
            wispAt[try claim(w.position)] = Int8(i)
        }
        // §2.5: her renk için fener kapasitesi kadar ruh.
        for color in Set(lanterns.map(\.color)).union(wisps.map(\.color)) {
            let need = lanterns.filter { $0.color == color }.reduce(0) { $0 + $1.capacity }
            guard wisps.filter({ $0.color == color }).count == need else {
                throw LevelError.wispCountMismatch(color: color)
            }
        }

        self.wallAt = wallAt; self.webAt = webAt; self.arrowAt = arrowAt
        self.gateAt = gateAt; self.lanternAt = lanternAt; self.wispAt = wispAt
        self.capacities = lanterns.map { UInt8($0.capacity) }
    }

    public func cell(_ p: Point) -> Int { p.x + p.y * width }
    public func point(_ cell: Int) -> Point { Point(cell % width, cell / width) }
    public func point(_ cell: UInt8) -> Point { point(Int(cell)) }

    public var start: State {
        State(body: [UInt8(cell(head))], colors: [],
              wisps: wisps.isEmpty ? 0 : UInt32.max >> (32 - wisps.count),
              fill: [UInt8](repeating: 0, count: lanterns.count))
    }

    public func isWon(_ s: State) -> Bool {
        for i in capacities.indices where s.fill[i] < capacities[i] { return false }
        return true
    }
}
