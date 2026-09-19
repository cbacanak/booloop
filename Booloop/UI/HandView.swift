import UIKit

/// FTUE el işareti (PLAN.md §5): 1. seviyede kaydırmayı, 4. seviyede geri al düğmesini gösterir.
/// Metin yok. Reduced Motion açıkken hareket etmez, hedefte sabit durur (§9.2).
final class HandView: UIImageView {
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    init() {
        super.init(frame: CGRect(x: 0, y: 0, width: 56, height: 56))
        image = UIImage(systemName: "hand.point.up.left.fill")
        tintColor = .white
        contentMode = .scaleAspectFit
        isUserInteractionEnabled = false
        alpha = 0
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.6
        layer.shadowRadius = 4
        layer.shadowOffset = .zero
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmaz") }

    /// Parmak ucu `start`'tan `end`'e kayar, söner, tekrar eder.
    func showSwipe(from start: CGPoint, to end: CGPoint) {
        layer.removeAllAnimations()
        transform = .identity
        center = fingertipCenter(start)
        if reduceMotion {
            center = fingertipCenter(end)
            alpha = 1
            return
        }
        alpha = 0
        let target = fingertipCenter(end)
        UIView.animateKeyframes(withDuration: 1.6, delay: 0.3, options: [.repeat, .calculationModeCubic]) {
            UIView.addKeyframe(withRelativeStartTime: 0, relativeDuration: 0.15) { self.alpha = 1 }
            UIView.addKeyframe(withRelativeStartTime: 0.15, relativeDuration: 0.55) { self.center = target }
            UIView.addKeyframe(withRelativeStartTime: 0.7, relativeDuration: 0.2) { self.alpha = 0 }
        }
    }

    /// Parmak ucu `point` üstünde küçülüp büyür (dokunma).
    func showTap(at point: CGPoint) {
        layer.removeAllAnimations()
        transform = .identity
        center = fingertipCenter(point)
        alpha = 1
        if reduceMotion { return }
        UIView.animate(withDuration: 0.5, delay: 0.2, options: [.repeat, .autoreverse, .curveEaseInOut]) {
            self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        }
    }

    func hide() {
        layer.removeAllAnimations()
        alpha = 0
        transform = .identity
    }

    /// Simgede parmak ucu sol üsttedir; görünümün merkezi ona göre kaydırılır.
    private func fingertipCenter(_ tip: CGPoint) -> CGPoint {
        CGPoint(x: tip.x + bounds.width * 0.3, y: tip.y + bounds.height * 0.35)
    }
}
