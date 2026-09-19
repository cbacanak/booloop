import Foundation

/// Aşama 2 yüz yüze test oturumu kaydı (PLAN.md §8.3, §11). Olaylar yalnızca cihazda, oturum
/// başına bir JSON dosyasına yazılır; ağ ve üçüncü taraf SDK yok. Kayıt yalnızca geliştirici
/// ayarından başlatılan bir oturum sürerken yapılır; oturum yoksa `record` hiçbir şey yazmaz.
/// Eski oturumların dosyaları silinmez.
final class TestRecorder {
    static let shared = TestRecorder()

    /// Kayıtlı olay (§8.3). Alanlar olaya göre dolar; boş alanlar JSON'a yazılmaz.
    struct Event: Codable, Equatable {
        enum Name: String, Codable {
            case levelStart = "level_start"
            case levelComplete = "level_complete"
            case levelFail = "level_fail"
            case deadendShown = "deadend_shown"
            case invalidSwipe = "invalid_swipe"
        }

        var seq: Int
        var time: Date
        /// Oturum başından beri geçen saniye.
        var elapsed: Double
        var name: Name
        var level: Int
        var moves: Int?
        var par: Int?
        var stars: Int?
        var undoCount: Int?
        var deadendCount: Int?
        /// Seviye denemesinin başından beri geçen saniye.
        var seconds: Double?
        /// O ana kadar yapılan geçerli hamle sayısı.
        var moveIndex: Int?
        var direction: String?

        enum CodingKeys: String, CodingKey {
            case seq, time, elapsed, name = "event", level, moves, par, stars
            case undoCount = "undo_count", deadendCount = "deadend_count", seconds
            case moveIndex = "move_index", direction
        }

        init(name: Name, level: Int, moves: Int? = nil, par: Int? = nil, stars: Int? = nil,
             undoCount: Int? = nil, deadendCount: Int? = nil, seconds: Double? = nil,
             moveIndex: Int? = nil, direction: String? = nil) {
            self.seq = 0
            self.time = Date(timeIntervalSince1970: 0)
            self.elapsed = 0
            self.name = name
            self.level = level
            self.moves = moves
            self.par = par
            self.stars = stars
            self.undoCount = undoCount
            self.deadendCount = deadendCount
            self.seconds = seconds
            self.moveIndex = moveIndex
            self.direction = direction
        }
    }

    /// Bir test oturumu: testçi no, başlangıç, oturum başındaki geliştirici ayarları, olaylar.
    struct Session: Codable, Equatable {
        var id: String
        var tester: String
        var started: Date
        var appVersion: String
        var deadendTiming: String
        var multipliers: [Double]
        var events: [Event]

        enum CodingKeys: String, CodingKey {
            case id, tester, started, appVersion = "app_version"
            case deadendTiming = "deadend_timing", multipliers, events
        }
    }

    let directory: URL
    private let defaults: UserDefaults
    private let clock: () -> Date
    private let activeKey = "dev.testSession.active"
    private(set) var current: Session?

    init(directory: URL = TestRecorder.defaultDirectory,
         defaults: UserDefaults = .standard,
         clock: @escaping () -> Date = Date.init) {
        self.directory = directory
        self.defaults = defaults
        self.clock = clock
        if let id = defaults.string(forKey: activeKey) {
            current = try? load(url(for: id))
        }
    }

    static var defaultDirectory: URL {
        FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
            .appending(path: "TestSessions", directoryHint: .isDirectory)
    }

    var isRecording: Bool { current != nil }

    var now: Date { clock() }

    // MARK: - Oturum

    /// Yeni oturum başlatır; süren oturum varsa kapanır (dosyası kalır).
    @discardableResult
    func start(tester: String, settings: DevSettings = .shared) throws -> Session {
        let started = clock()
        let stamp = Self.idFormatter.string(from: started)
        let session = Session(
            id: "T\(tester)-\(stamp)", tester: tester, started: started,
            appVersion: Self.appVersion, deadendTiming: settings.deadEndTiming == .immediate ? "immediate" : "delayed",
            multipliers: settings.multipliers, events: [])
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try save(session)
        current = session
        defaults.set(session.id, forKey: activeKey)
        return session
    }

    /// Kaydı durdurur; dosya silinmez.
    func stop() {
        current = nil
        defaults.removeObject(forKey: activeKey)
    }

    /// Olayı süren oturuma ekler ve dosyayı yeniden yazar. Oturum yoksa hiçbir şey yapmaz.
    func record(_ event: Event) {
        guard var session = current else { return }
        var e = event
        e.seq = session.events.count + 1
        e.time = clock()
        e.elapsed = Self.round(e.time.timeIntervalSince(session.started))
        e.seconds = e.seconds.map(Self.round)
        session.events.append(e)
        current = session
        try? save(session)
    }

    /// Kayıtlı bütün oturumlar, en yenisi önce.
    func sessions() -> [Session] {
        let files = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return files.filter { $0.pathExtension == "json" }
            .compactMap { try? load($0) }
            .sorted { $0.started > $1.started }
    }

    // MARK: - Dışa aktarma

    /// Oturumu geçici klasöre CSV ve JSON olarak yazar; paylaşım sayfasına verilecek dosyalar.
    func exportFiles(for session: Session) throws -> [URL] {
        let dir = FileManager.default.temporaryDirectory.appending(path: "BooloopExport", directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let base = "booloop-\(session.id)"
        let csv = dir.appending(path: "\(base).csv")
        let json = dir.appending(path: "\(base).json")
        try Data(Self.csv(session).utf8).write(to: csv, options: .atomic)
        try Self.encoder.encode(session).write(to: json, options: .atomic)
        return [csv, json]
    }

    static let csvColumns = [
        "session", "tester", "seq", "time", "elapsed", "event", "level", "moves", "par", "stars",
        "undo_count", "deadend_count", "seconds", "move_index", "direction",
    ]

    static func csv(_ session: Session) -> String {
        var lines = [csvColumns.joined(separator: ",")]
        for e in session.events {
            let fields: [String] = [
                session.id, session.tester, String(e.seq), timeFormatter.string(from: e.time),
                format(e.elapsed), e.name.rawValue, String(e.level),
                e.moves.map(String.init) ?? "", e.par.map(String.init) ?? "", e.stars.map(String.init) ?? "",
                e.undoCount.map(String.init) ?? "", e.deadendCount.map(String.init) ?? "",
                e.seconds.map(format) ?? "", e.moveIndex.map(String.init) ?? "", e.direction ?? "",
            ]
            lines.append(fields.joined(separator: ","))
        }
        return lines.joined(separator: "\n") + "\n"
    }

    // MARK: - Dosya

    private func url(for id: String) -> URL { directory.appending(path: "\(id).json") }

    private func save(_ session: Session) throws {
        try Self.encoder.encode(session).write(to: url(for: session.id), options: .atomic)
    }

    private func load(_ url: URL) throws -> Session {
        try Self.decoder.decode(Session.self, from: Data(contentsOf: url))
    }

    private static let encoder: JSONEncoder = {
        let e = JSONEncoder()
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        e.dateEncodingStrategy = .custom { date, encoder in
            var c = encoder.singleValueContainer()
            try c.encode(timeFormatter.string(from: date))
        }
        return e
    }()

    private static let decoder: JSONDecoder = {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .custom { decoder in
            let s = try decoder.singleValueContainer().decode(String.self)
            guard let date = timeFormatter.date(from: s) else {
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath, debugDescription: s))
            }
            return date
        }
        return d
    }()

    private static let timeFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        f.timeZone = .current
        return f
    }()

    private static let idFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyyMMdd-HHmmss"
        return f
    }()

    private static var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "?"
        let build = info?["CFBundleVersion"] as? String ?? "?"
        return "\(version) (\(build))"
    }

    private static func round(_ x: Double) -> Double { (x * 1000).rounded() / 1000 }
    private static func format(_ x: Double) -> String { String(format: "%.3f", x) }
}
