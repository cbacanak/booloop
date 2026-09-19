import BooloopCore

/// Tek bir seviyenin oyun oturumu: durum, hamle sayacı ve hakkı (§2.6), geri al (§2.7),
/// çıkmaz göstergesi (§2.8), yıldız (§2.9). Kural mantığı BooloopCore'dadır; burada yalnızca
/// çekirdeğin sonuçları uygulamaya bağlanır.
final class GameSession {
    let entry: LevelPack.Entry
    let level: Level
    /// Hamle hakkı; `nil` = sınırsız.
    let moveBudget: Int?
    var deadEndTiming: DeadEndTiming

    private(set) var state: State
    private(set) var movesUsed = 0
    private(set) var undoCount = 0

    private var history: [State] = []
    private var deadHistory: [Bool] = []
    /// Şu anki durum çıkmaz mı (çözücü emin değilse `false`, §2.8).
    private var deadNow = false
    /// Bir önceki durum çıkmaz mıydı; gecikmeli gösterge bunu kullanır.
    private var deadPrev = false
    private let solver: Solver

    init(entry: LevelPack.Entry, settings: DevSettings = .shared) {
        self.entry = entry
        self.level = entry.level
        self.state = entry.level.start
        self.moveBudget = settings.moveBudget(for: entry)
        self.deadEndTiming = settings.deadEndTiming
        self.solver = Solver(level: entry.level)
    }

    var isWon: Bool { level.isWon(state) }

    /// Hak bitti, fenerler dolmadı (§2.6).
    var isFailed: Bool {
        guard let budget = moveBudget else { return false }
        return !isWon && movesUsed >= budget
    }

    var isOver: Bool { isWon || isFailed }

    var movesLeft: Int? { moveBudget.map { max(0, $0 - movesUsed) } }

    var canUndo: Bool { !history.isEmpty && !isOver }

    /// FTUE'de geri al'ı öğreten seviye (§5). Burada gösterge geliştirici ayarından bağımsız
    /// olarak her zaman anında gelir; el geri al'ı ancak gösterge yandıktan sonra gösterebilir.
    static let ftueUndoLevel = 4

    /// Uygulanan zamanlama: FTUE geri al seviyesinde anında, diğerlerinde geliştirici ayarı.
    var effectiveDeadEndTiming: DeadEndTiming {
        entry.id == Self.ftueUndoLevel ? .immediate : deadEndTiming
    }

    /// Göstergenin şu an yanıp yanmadığı.
    var showsDeadEnd: Bool { effectiveDeadEndTiming == .immediate ? deadNow : deadPrev }

    /// §2.9. Aşama 2'de güçlendirici olmadığı için 3 yıldız mümkündür.
    var stars: Int {
        guard isWon else { return 0 }
        if movesUsed <= entry.par { return 3 }
        if movesUsed <= entry.par + 2 { return 2 }
        return 1
    }

    /// Geçerli kaydırma: durum ilerler, hamle sayılır. Geçersizse `nil` ve hiçbir şey değişmez.
    @discardableResult
    func swipe(_ direction: Direction) -> SlideResult? {
        guard !isOver, let result = level.slideSteps(state, direction) else { return nil }
        history.append(state)
        deadHistory.append(deadNow)
        state = result.state
        movesUsed += 1
        deadPrev = deadNow
        deadNow = isWon ? false : solver.solve(from: state) == .dead
        return result
    }

    /// Bir önceki duruma döner; harcanan hamleyi iade etmez (§2.7).
    @discardableResult
    func undo() -> Bool {
        guard canUndo, let previous = history.popLast() else { return false }
        state = previous
        deadNow = deadHistory.removeLast()
        deadPrev = deadHistory.last ?? false
        undoCount += 1
        return true
    }

    /// Ücretsiz tekrar (§2.6): her şey başa döner.
    func restart() {
        state = level.start
        history.removeAll()
        deadHistory.removeAll()
        deadNow = false
        deadPrev = false
        movesUsed = 0
        undoCount = 0
    }
}
