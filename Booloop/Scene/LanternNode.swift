import SpriteKit
import UIKit

/// Fener (§2.1, §9): sönükken koyu, dolunca parlar; çıkmazda ışığı söner (§2.8).
final class LanternNode: SKNode {
    let color: SoulColor
    let capacity: Int
    private(set) var fill = 0

    private let glow: SKShapeNode
    private let body: SKShapeNode
    private let marks: [SKShapeNode]

    var isFull: Bool { fill >= capacity }

    init(color: SoulColor, capacity: Int, cell: CGFloat) {
        self.color = color
        self.capacity = capacity

        let glow = SKShapeNode(circleOfRadius: cell * 0.55)
        glow.fillColor = color.uiColor.withAlphaComponent(0.28)
        glow.strokeColor = .clear
        glow.alpha = 0
        self.glow = glow

        let body = SKShapeNode(rectOf: CGSize(width: cell * 0.7, height: cell * 0.8), cornerRadius: cell * 0.14)
        body.fillColor = Palette.lanternBody
        body.strokeColor = color.uiColor
        body.lineWidth = 2
        self.body = body

        var marks: [SKShapeNode] = []
        let radius = capacity == 1 ? cell * 0.17 : cell * 0.12
        for i in 0..<capacity {
            let mark = SKShapeNode(path: color.shape.path(radius: radius))
            mark.fillColor = .clear
            mark.strokeColor = color.uiColor
            mark.lineWidth = 2
            let offset = capacity == 1 ? 0 : (CGFloat(i) - 0.5) * cell * 0.3
            mark.position = CGPoint(x: 0, y: -offset)
            marks.append(mark)
        }
        self.marks = marks

        super.init()
        addChild(glow)
        addChild(body)
        for mark in marks { addChild(mark) }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmaz") }

    func setFill(_ count: Int) {
        fill = count
        for (i, mark) in marks.enumerated() {
            mark.fillColor = i < count ? color.uiColor : .clear
        }
        glow.alpha = isFull ? 1 : 0
    }

    /// §2.8: çıkmazda fenerlerin ışığı söner.
    func setDimmed(_ dimmed: Bool, animated: Bool) {
        let target: CGFloat = dimmed ? 0.3 : 1
        removeAction(forKey: "dim")
        if animated {
            run(.fadeAlpha(to: target, duration: 0.25), withKey: "dim")
        } else {
            alpha = target
        }
    }
}
