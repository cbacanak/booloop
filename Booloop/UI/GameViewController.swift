import UIKit
import SpriteKit
import BooloopCore

/// Oyun ekranı: sahne, HUD, kaydırma girdisi, geri al, çıkmaz göstergesi, FTUE eli.
/// Kural mantığı `GameSession` → BooloopCore'dadır; burası yalnızca bağlar ve çizer.
/// Yerleşim güvenli alana göre (§10.3); hareket sırasında 120 Hz, dururken 60.
final class GameViewController: UIViewController {
    let levelNumber: Int
    private(set) var session: GameSession
    private(set) var scene: BoardScene!
    /// Testler için: adımlar animasyonsuz, anında uygulanır.
    var instantAnimations = false {
        didSet { scene?.animationScale = instantAnimations ? 0 : 1 }
    }
    var isShowingOverlay: Bool { overlay != nil }

    private let skView = SKView()
    private let backButton = UIButton(type: .system)
    private let levelLabel = UILabel()
    private let movesLabel = UILabel()
    private let undoButton = UIButton(type: .system)
    private let settingsButton = UIButton(type: .system)
    private let hand = HandView()
    private var overlay: UIView?
    private var undoHandShown = false
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    init(levelNumber: Int) {
        self.levelNumber = levelNumber
        self.session = GameSession(entry: LevelCatalog.entry(levelNumber))
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmaz") }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    // MARK: - Yaşam döngüsü

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = Palette.night
        buildHUD()
        buildScene()
        installGestures()
        refreshHUD()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Geliştirici ayarından dönüldüyse zamanlama değişmiş olabilir (§14 madde 1).
        session.deadEndTiming = DevSettings.shared.deadEndTiming
        refreshHUD()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if levelNumber == 1, session.movesUsed == 0 { showSwipeHand() }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        hand.hide()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if scene.size != skView.bounds.size { scene.size = skView.bounds.size }
    }

    // MARK: - Kurulum

    private func buildHUD() {
        let guide = view.safeAreaLayoutGuide
        let symbol = UIImage.SymbolConfiguration(pointSize: 22, weight: .semibold)
        let big = UIImage.SymbolConfiguration(pointSize: 34, weight: .semibold)

        backButton.setImage(UIImage(systemName: "chevron.left", withConfiguration: symbol), for: .normal)
        backButton.tintColor = Palette.hud
        backButton.accessibilityLabel = "Back"
        backButton.addTarget(self, action: #selector(backTapped), for: .touchUpInside)

        levelLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        levelLabel.textColor = Palette.hud
        levelLabel.textAlignment = .center

        movesLabel.font = .monospacedDigitSystemFont(ofSize: 20, weight: .semibold)
        movesLabel.textColor = Palette.hud
        movesLabel.textAlignment = .right
        movesLabel.accessibilityLabel = "Moves"

        undoButton.setImage(UIImage(systemName: "arrow.uturn.backward.circle.fill", withConfiguration: big), for: .normal)
        undoButton.tintColor = Palette.hud
        undoButton.accessibilityLabel = "Undo"
        undoButton.addTarget(self, action: #selector(undoTapped), for: .touchUpInside)

        settingsButton.setImage(UIImage(systemName: "gearshape", withConfiguration: symbol), for: .normal)
        settingsButton.tintColor = Palette.hud.withAlphaComponent(0.6)
        settingsButton.accessibilityLabel = "Developer settings"
        settingsButton.addTarget(self, action: #selector(settingsTapped), for: .touchUpInside)
        #if !DEBUG
        settingsButton.isHidden = true
        #endif

        for v in [skView, backButton, levelLabel, movesLabel, undoButton, settingsButton] {
            v.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(v)
        }
        view.addSubview(hand)   // elle konumlanır, Auto Layout dışında

        NSLayoutConstraint.activate([
            backButton.leadingAnchor.constraint(equalTo: guide.leadingAnchor, constant: 16),
            backButton.topAnchor.constraint(equalTo: guide.topAnchor, constant: 8),
            backButton.widthAnchor.constraint(equalToConstant: 44),
            backButton.heightAnchor.constraint(equalToConstant: 44),

            levelLabel.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            levelLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            movesLabel.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -20),
            movesLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),

            skView.topAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8),
            skView.leadingAnchor.constraint(equalTo: guide.leadingAnchor),
            skView.trailingAnchor.constraint(equalTo: guide.trailingAnchor),

            undoButton.topAnchor.constraint(equalTo: skView.bottomAnchor, constant: 8),
            undoButton.centerXAnchor.constraint(equalTo: guide.centerXAnchor),
            undoButton.bottomAnchor.constraint(equalTo: guide.bottomAnchor, constant: -12),
            undoButton.widthAnchor.constraint(equalToConstant: 72),
            undoButton.heightAnchor.constraint(equalToConstant: 72),

            settingsButton.centerYAnchor.constraint(equalTo: undoButton.centerYAnchor),
            settingsButton.trailingAnchor.constraint(equalTo: guide.trailingAnchor, constant: -16),
            settingsButton.widthAnchor.constraint(equalToConstant: 44),
            settingsButton.heightAnchor.constraint(equalToConstant: 44),
        ])
    }

    private func buildScene() {
        skView.backgroundColor = Palette.night
        skView.ignoresSiblingOrder = true
        skView.preferredFramesPerSecond = 60   // hareketsizken 60 (§10.3)
        scene = BoardScene(level: session.level, state: session.state, size: skView.bounds.size)
        scene.animationScale = instantAnimations ? 0 : 1
        scene.onCollect = { Haptics.collect() }
        scene.onDeposit = { Haptics.deposit() }
        skView.presentScene(scene)
    }

    private func installGestures() {
        for direction in Direction.allCases {
            let recognizer = UISwipeGestureRecognizer(target: self, action: #selector(swiped(_:)))
            recognizer.direction = direction.gestureDirection
            view.addGestureRecognizer(recognizer)
        }
    }

    // MARK: - Girdi

    @objc private func swiped(_ recognizer: UISwipeGestureRecognizer) {
        guard let direction = Direction(gesture: recognizer.direction) else { return }
        swipe(direction)
    }

    /// Kaydırma girdisi. Kabul edildiyse `true`; geçersiz hamle, bitmiş seviye ya da animasyon
    /// sürerken `false`.
    @discardableResult
    func swipe(_ direction: Direction) -> Bool {
        guard !scene.isAnimating, overlay == nil else { return false }
        hand.hide()
        guard let result = session.swipe(direction) else {
            scene.shake(direction)   // §2.2: geçersiz kaydırma, hamle sayılmaz
            Haptics.invalid()
            return false
        }
        skView.preferredFramesPerSecond = 120   // hareket sırasında 120 Hz (§10.3)
        scene.play(result) { [weak self] in
            self?.slideFinished()
        }
        return true
    }

    private func slideFinished() {
        skView.preferredFramesPerSecond = 60
        refreshHUD()
        if session.isWon {
            Haptics.success()
            Progress.shared.complete(levelNumber, stars: session.stars)
            showOverlay(won: true)
        } else if session.isFailed {
            Haptics.failure()
            showOverlay(won: false)
        } else if session.showsDeadEnd, levelNumber == GameSession.ftueUndoLevel, !undoHandShown {
            undoHandShown = true   // §5: 4. seviyede el geri al'ı gösterir
            showUndoHand()
        }
    }

    @objc private func undoTapped() { undo() }

    /// §2.7: bir önceki duruma döner, hamleyi iade etmez.
    @discardableResult
    func undo() -> Bool {
        guard !scene.isAnimating, overlay == nil, session.undo() else { return false }
        hand.hide()
        scene.snap(to: session.state)
        refreshHUD()
        return true
    }

    /// §2.6: ücretsiz tekrar.
    func restart() {
        session.restart()
        dismissOverlay()
        scene.snap(to: session.state)
        refreshHUD()
    }

    func goToNextLevel() {
        guard levelNumber < LevelCatalog.adventureCount, let nav = navigationController else {
            backTapped()
            return
        }
        var stack = nav.viewControllers
        stack.removeLast()
        stack.append(GameViewController(levelNumber: levelNumber + 1))
        nav.setViewControllers(stack, animated: true)
    }

    @objc private func backTapped() { navigationController?.popViewController(animated: true) }
    @objc private func settingsTapped() {
        navigationController?.pushViewController(DevSettingsViewController(), animated: true)
    }
    @objc private func nextTapped() { goToNextLevel() }
    @objc private func retryTapped() { restart() }

    // MARK: - HUD

    private func refreshHUD() {
        levelLabel.text = String(levelNumber)
        movesLabel.isHidden = levelNumber < 6   // §5: sayaç 6. seviyeden itibaren
        if let budget = session.moveBudget {
            movesLabel.text = "\(session.movesUsed) / \(budget)"
        } else {
            movesLabel.text = String(session.movesUsed)
        }
        undoButton.isEnabled = session.canUndo
        undoButton.alpha = session.canUndo ? 1 : 0.35
        let dead = session.showsDeadEnd
        scene.setDeadEnd(dead)
        setUndoPulse(dead)
    }

    /// §2.8: çıkmazda geri al düğmesi nabız atar; Reduced Motion'da sabit vurgu (§9.2).
    private func setUndoPulse(_ on: Bool) {
        undoButton.layer.removeAnimation(forKey: "pulse")
        if on && !reduceMotion {
            let pulse = CABasicAnimation(keyPath: "transform.scale")
            pulse.fromValue = 1.0
            pulse.toValue = 1.18
            pulse.duration = 0.55
            pulse.autoreverses = true
            pulse.repeatCount = .infinity
            pulse.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            undoButton.layer.add(pulse, forKey: "pulse")
        }
        undoButton.tintColor = on ? Palette.accent : Palette.hud
    }

    private func showOverlay(won: Bool) {
        dismissOverlay()
        let dim = UIView()
        dim.backgroundColor = UIColor(white: 0, alpha: 0.55)
        dim.translatesAutoresizingMaskIntoConstraints = false

        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 28
        stack.translatesAutoresizingMaskIntoConstraints = false

        let iconConfig = UIImage.SymbolConfiguration(pointSize: 44, weight: .bold)
        if won, levelNumber >= 6 {   // §5: yıldızlar 6. seviyeden itibaren
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 8
            for i in 1...3 {
                let earned = i <= session.stars
                let star = UIImageView(image: UIImage(systemName: earned ? "star.fill" : "star", withConfiguration: iconConfig))
                star.tintColor = earned ? Palette.accent : Palette.hud.withAlphaComponent(0.4)
                row.addArrangedSubview(star)
            }
            stack.addArrangedSubview(row)
        } else {
            let name = won ? "checkmark.circle.fill" : "xmark.circle.fill"
            let icon = UIImageView(image: UIImage(systemName: name, withConfiguration: iconConfig))
            icon.tintColor = won ? Palette.accent : Palette.hud
            stack.addArrangedSubview(icon)
        }

        let button = UIButton(type: .system)
        let buttonConfig = UIImage.SymbolConfiguration(pointSize: 60, weight: .semibold)
        let buttonName = won ? "arrow.right.circle.fill" : "arrow.counterclockwise.circle.fill"
        button.setImage(UIImage(systemName: buttonName, withConfiguration: buttonConfig), for: .normal)
        button.tintColor = Palette.hud
        button.accessibilityLabel = won ? "Next level" : "Retry"
        button.addTarget(self, action: won ? #selector(nextTapped) : #selector(retryTapped), for: .touchUpInside)
        stack.addArrangedSubview(button)

        dim.addSubview(stack)
        view.addSubview(dim)
        NSLayoutConstraint.activate([
            dim.topAnchor.constraint(equalTo: view.topAnchor),
            dim.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dim.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dim.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stack.centerXAnchor.constraint(equalTo: dim.centerXAnchor),
            stack.centerYAnchor.constraint(equalTo: dim.centerYAnchor),
        ])
        overlay = dim
        dim.alpha = 0
        UIView.animate(withDuration: reduceMotion || instantAnimations ? 0 : 0.25) { dim.alpha = 1 }
    }

    private func dismissOverlay() {
        overlay?.removeFromSuperview()
        overlay = nil
    }

    // MARK: - FTUE eli (§5)

    private func showSwipeHand() {
        guard let first = session.entry.solution.first, scene.cellSize > 0 else { return }
        let startScene = scene.position(ofCell: session.state.body[0])
        let v = first.step
        let reach = scene.cellSize * 2
        let endScene = CGPoint(x: startScene.x + CGFloat(v.dx) * reach, y: startScene.y - CGFloat(v.dy) * reach)
        let start = view.convert(scene.convertPoint(toView: startScene), from: skView)
        let end = view.convert(scene.convertPoint(toView: endScene), from: skView)
        hand.showSwipe(from: start, to: end)
    }

    private func showUndoHand() {
        hand.showTap(at: undoButton.center)
    }
}
