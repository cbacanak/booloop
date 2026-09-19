import UIKit
import BooloopCore

extension Direction {
    /// Izgara adımı; y aşağı doğru artar (PLAN.md §4.5: 0 yukarı, 1 sağ, 2 aşağı, 3 sol).
    var step: (dx: Int, dy: Int) {
        switch self {
        case .up: return (0, -1)
        case .right: return (1, 0)
        case .down: return (0, 1)
        case .left: return (-1, 0)
        }
    }

    var gestureDirection: UISwipeGestureRecognizer.Direction {
        switch self {
        case .up: return .up
        case .right: return .right
        case .down: return .down
        case .left: return .left
        }
    }

    init?(gesture: UISwipeGestureRecognizer.Direction) {
        switch gesture {
        case .up: self = .up
        case .right: self = .right
        case .down: self = .down
        case .left: self = .left
        default: return nil
        }
    }
}
