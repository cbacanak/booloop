import Foundation
import BooloopCore

/// Uygulamaya gömülü bölüm paketi (`data/levels-200.json`, PLAN.md §4.5).
/// Aşama 2'de macera modu ilk 40 seviyeyi kapsar (§11).
enum LevelCatalog {
    static let adventureCount = 40

    static let pack: LevelPack = {
        guard let url = Bundle.main.url(forResource: "levels-200", withExtension: "json") else {
            fatalError("levels-200.json uygulama paketinde yok")
        }
        do {
            return try LevelPack(data: try Data(contentsOf: url))
        } catch {
            fatalError("Bölüm paketi yüklenemedi: \(error)")
        }
    }()

    /// Macera seviyeleri; seviye numarası = bölüm kimliği (1'den başlar).
    static var adventure: [LevelPack.Entry] { Array(pack.entries.prefix(adventureCount)) }

    static func entry(_ number: Int) -> LevelPack.Entry {
        precondition((1...pack.entries.count).contains(number), "seviye \(number) yok")
        return pack.entries[number - 1]
    }

    /// Bölüm (chapter) numarası, 1'den başlar; her bölüm 20 seviye (§4.2).
    static func chapter(of entry: LevelPack.Entry) -> Int { (entry.id - 1) / 20 + 1 }
}
