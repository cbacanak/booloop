import Foundation

/// Yerel ilerleme (PLAN.md §10.3): en son bitirilen seviye ve seviye başına yıldız.
/// UserDefaults gerekçesi PrivacyInfo.xcprivacy'de CA92.1.
final class Progress {
    static let shared = Progress()

    private let defaults: UserDefaults
    private let completedKey = "progress.highestCompleted"
    private let starsKey = "progress.stars"

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    private(set) var highestCompleted: Int {
        get { defaults.integer(forKey: completedKey) }
        set { defaults.set(newValue, forKey: completedKey) }
    }

    /// Seviyeler sırayla açılır (§6.1).
    func isUnlocked(_ number: Int) -> Bool { number <= highestCompleted + 1 }

    func stars(for number: Int) -> Int {
        (defaults.dictionary(forKey: starsKey) as? [String: Int])?[String(number)] ?? 0
    }

    func complete(_ number: Int, stars: Int) {
        highestCompleted = max(highestCompleted, number)
        var all = defaults.dictionary(forKey: starsKey) as? [String: Int] ?? [:]
        all[String(number)] = max(all[String(number)] ?? 0, stars)
        defaults.set(all, forKey: starsKey)
    }

    func reset() {
        defaults.removeObject(forKey: completedKey)
        defaults.removeObject(forKey: starsKey)
    }

    func unlockAll(upTo number: Int) {
        highestCompleted = max(highestCompleted, number - 1)
    }
}
