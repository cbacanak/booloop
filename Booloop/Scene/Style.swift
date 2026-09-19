import UIKit

/// Renk + şekil eşlemesi (PLAN.md §2.1): her renk sabit bir şekille eşleşir,
/// renk tek başına hiçbir zaman bilgi taşımaz. Gri tonlama filtresiyle test edilir (§9.2).
enum SoulColor: Int, CaseIterable {
    case amber = 0, sky, orchid, moss

    var uiColor: UIColor {
        switch self {
        case .amber: return UIColor(red: 0.98, green: 0.72, blue: 0.30, alpha: 1)
        case .sky: return UIColor(red: 0.42, green: 0.78, blue: 0.98, alpha: 1)
        case .orchid: return UIColor(red: 0.85, green: 0.58, blue: 0.95, alpha: 1)
        case .moss: return UIColor(red: 0.55, green: 0.85, blue: 0.55, alpha: 1)
        }
    }

    /// Daire, kare, elmas, üçgen (§2.1).
    var shape: SoulShape { SoulShape.allCases[rawValue] }
}

enum SoulShape: CaseIterable {
    case circle, square, diamond, triangle

    /// Merkezi (0,0) olan, yarıçapı `r` olan şekil yolu.
    func path(radius r: CGFloat) -> CGPath {
        let p = CGMutablePath()
        switch self {
        case .circle:
            p.addEllipse(in: CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r))
        case .square:
            let s = r * 1.7
            p.addRoundedRect(in: CGRect(x: -s / 2, y: -s / 2, width: s, height: s),
                             cornerWidth: r * 0.25, cornerHeight: r * 0.25)
        case .diamond:
            p.move(to: CGPoint(x: 0, y: r))
            p.addLine(to: CGPoint(x: r, y: 0))
            p.addLine(to: CGPoint(x: 0, y: -r))
            p.addLine(to: CGPoint(x: -r, y: 0))
            p.closeSubpath()
        case .triangle:
            p.move(to: CGPoint(x: 0, y: r))
            p.addLine(to: CGPoint(x: r * 0.95, y: -r * 0.6))
            p.addLine(to: CGPoint(x: -r * 0.95, y: -r * 0.6))
            p.closeSubpath()
        }
        return p
    }
}

/// Geçici görsel dil (§9): gece, sıcak fener ışığı, yumuşak renkler. Son tasarım Aşama 4'te.
enum Palette {
    static let night = UIColor(red: 0.071, green: 0.063, blue: 0.122, alpha: 1)
    static let cell = UIColor(white: 1, alpha: 0.05)
    static let cellStroke = UIColor(white: 1, alpha: 0.10)
    static let ghost = UIColor(red: 0.95, green: 0.95, blue: 0.98, alpha: 1)
    static let ghostEye = UIColor(red: 0.16, green: 0.14, blue: 0.24, alpha: 1)
    static let stone = UIColor(red: 0.40, green: 0.40, blue: 0.47, alpha: 1)
    static let stoneMark = UIColor(red: 0.25, green: 0.25, blue: 0.32, alpha: 1)
    static let web = UIColor(white: 0.9, alpha: 0.55)
    static let arrow = UIColor(white: 0.9, alpha: 0.7)
    static let lanternBody = UIColor(red: 0.18, green: 0.16, blue: 0.24, alpha: 1)
    static let hud = UIColor(white: 0.92, alpha: 1)
    static var accent: UIColor { UIColor(named: "AccentColor") ?? .systemOrange }
}
