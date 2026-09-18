import UIKit

/// Haptik (PLAN.md §9): toplama hafif, bırakma orta, bölüm sonu başarı, geçersiz kaydırma hata.
/// Ayarlardan kapatma Aşama 3'te (§9); şimdilik tek bayrak.
@MainActor
enum Haptics {
    static var isEnabled = true

    private static let light = UIImpactFeedbackGenerator(style: .light)
    private static let medium = UIImpactFeedbackGenerator(style: .medium)
    private static let notification = UINotificationFeedbackGenerator()

    static func collect() {
        guard isEnabled else { return }
        light.impactOccurred()
    }

    static func deposit() {
        guard isEnabled else { return }
        medium.impactOccurred()
    }

    static func success() {
        guard isEnabled else { return }
        notification.notificationOccurred(.success)
    }

    static func failure() {
        guard isEnabled else { return }
        notification.notificationOccurred(.warning)
    }

    static func invalid() {
        guard isEnabled else { return }
        notification.notificationOccurred(.error)
    }
}
