import Foundation
import BooloopCore

/// Çıkmaz göstergesinin zamanlaması (PLAN.md §2.8, §14 madde 1). Aşama 2 testinde ikisi de denenir.
enum DeadEndTiming: Int, CaseIterable {
    case immediate = 0
    case delayed = 1

    var title: String {
        switch self {
        case .immediate: return "Anında"
        case .delayed: return "Bir hamle gecikmeli"
        }
    }
}

/// Geliştirici ayarları (PLAN.md §14 madde 1–2). Yalnızca test için; kural değildir.
final class DevSettings {
    static let shared = DevSettings()

    /// Hamle hakkı bantları (PLAN.md §2.6): bölüm 2–3, 4–7, 8–10. Değer, par'ın katı olarak ek hak.
    static let bands: [(title: String, chapters: ClosedRange<Int>)] = [
        ("Bölüm 2–3", 2...3), ("Bölüm 4–7", 4...7), ("Bölüm 8–10", 8...10),
    ]
    static let defaultMultipliers: [Double] = [1.0, 0.75, 0.5]

    private let defaults: UserDefaults
    private let timingKey = "dev.deadEndTiming"
    private let multipliersKey = "dev.moveMultipliers"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    var deadEndTiming: DeadEndTiming {
        get { DeadEndTiming(rawValue: defaults.integer(forKey: timingKey)) ?? .immediate }
        set { defaults.set(newValue.rawValue, forKey: timingKey) }
    }

    var multipliers: [Double] {
        get {
            let stored = defaults.array(forKey: multipliersKey) as? [Double] ?? []
            return stored.count == Self.defaultMultipliers.count ? stored : Self.defaultMultipliers
        }
        set { defaults.set(newValue, forKey: multipliersKey) }
    }

    func setMultiplier(_ value: Double, band: Int) {
        var m = multipliers
        m[band] = value
        multipliers = m
    }

    func resetToDefaults() {
        defaults.removeObject(forKey: timingKey)
        defaults.removeObject(forKey: multipliersKey)
    }

    /// Bölümün hangi banda düştüğü; 1. bölüm sınırsız (`nil`).
    static func band(forChapter chapter: Int) -> Int? {
        bands.firstIndex { $0.chapters.contains(chapter) }
    }

    /// Hamle hakkı; `nil` = sınırsız. Varsayılan çarpanlarla `entry.moves` ile aynıdır.
    func moveBudget(for entry: LevelPack.Entry) -> Int? {
        guard let band = Self.band(forChapter: LevelCatalog.chapter(of: entry)) else { return nil }
        return Self.budget(par: entry.par, multiplier: multipliers[band])
    }

    /// `build_levels.move_budget`: `par + max(3, round(par × çarpan))`.
    /// Python `round` yarımları çift sayıya yuvarlar; Swift'te aynı kural seçilir.
    static func budget(par: Int, multiplier: Double) -> Int {
        let extra = Int((Double(par) * multiplier).rounded(.toNearestOrEven))
        return par + max(3, extra)
    }
}
