import SpriteKit
import UIKit
import BooloopCore

/// Tahtayı çizer ve BooloopCore'un döndürdüğü `SlideStep` dizisini kare kare oynatır
/// (PLAN.md §9: ~80 ms/kare, uzun kaymada hızlanır). Kural mantığı içermez; hangi
/// karenin toplandığı, hangi fenerin dolduğu adımların içinden okunur.
final class BoardScene: SKScene {
    let level: Level
    /// Animasyon süresi çarpanı; 0 = anında uygula (testler).
    var animationScale: Double = 1
    var onCollect: (() -> Void)?
    var onDeposit: (() -> Void)?

    /// Sahnenin şu an çizdiği durum.
    private(set) var current: State
    private(set) var isAnimating = false

    private var cell: CGFloat = 0
    /// Tahtanın sol üst köşesi (sahne koordinatı; y yukarı artar, ızgarada y aşağı artar).
    private var origin: CGPoint = .zero
    private let boardLayer = SKNode()
    private let pieceLayer = SKNode()
    private var ghost = SKNode()
    private var segments: [SKNode] = []
    private var wispNodes: [Int: SKNode] = [:]
    private var lanternNodes: [LanternNode] = []
    private var gateNodes: [(node: SKNode, lantern: Int)] = []
    private var deadEnd = false
    private let reduceMotion = UIAccessibility.isReduceMotionEnabled

    init(level: Level, state: State, size: CGSize) {
        self.level = level
        self.current = state
        super.init(size: size)
        scaleMode = .resizeFill
        backgroundColor = Palette.night
        pieceLayer.zPosition = 5
        addChild(boardLayer)
        addChild(pieceLayer)
        layoutBoard()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) kullanılmaz") }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        layoutBoard()
    }

    // MARK: - Yerleşim ve sorgular

    var cellSize: CGFloat { cell }
    var ghostPosition: CGPoint { ghost.position }
    var segmentCount: Int { segments.count }
    var litLanternCount: Int { lanternNodes.filter(\.isFull).count }

    func position(ofCell c: UInt8) -> CGPoint {
        let p = level.point(c)
        return CGPoint(x: origin.x + (CGFloat(p.x) + 0.5) * cell,
                       y: origin.y - (CGFloat(p.y) + 0.5) * cell)
    }

    private func position(of p: Point) -> CGPoint { position(ofCell: UInt8(level.cell(p))) }

    private func layoutBoard() {
        guard size.width > 0, size.height > 0 else { return }
        let pad: CGFloat = 12
        cell = floor(min((size.width - 2 * pad) / CGFloat(level.width),
                         (size.height - 2 * pad) / CGFloat(level.height)))
        let boardW = cell * CGFloat(level.width)
        let boardH = cell * CGFloat(level.height)
        origin = CGPoint(x: (size.width - boardW) / 2, y: (size.height + boardH) / 2)
        rebuild()
    }

    /// Animasyonsuz olarak verilen duruma geçer (geri al, tekrar).
    func snap(to state: State) {
        removeAllActions()
        isAnimating = false
        current = state
        rebuild()
    }

    /// §2.8: çıkmazda fenerlerin ışığı söner.
    func setDeadEnd(_ on: Bool) {
        guard on != deadEnd else { return }
        deadEnd = on
        for lantern in lanternNodes { lantern.setDimmed(on, animated: animationScale > 0) }
    }

    /// §2.2: geçersiz kaydırmada hayalet hafifçe sallanır.
    func shake(_ direction: Direction) {
        guard animationScale > 0, !isAnimating else { return }
        let v = direction.step
        let out = SKAction.moveBy(x: CGFloat(v.dx) * 6, y: CGFloat(-v.dy) * 6, duration: 0.05)
        ghost.run(.sequence([out, out.reversed(), out.reversed(), out]))
    }

    // MARK: - Düğümler

    /// Bütün düğümleri `current` durumundan yeniden kurar.
    private func rebuild() {
        boardLayer.removeAllChildren()
        pieceLayer.removeAllChildren()
        segments = []
        wispNodes = [:]
        lanternNodes = []
        gateNodes = []
        guard cell > 0 else { return }

        for y in 0..<level.height {
            for x in 0..<level.width {
                let tile = SKShapeNode(rectOf: CGSize(width: cell - 3, height: cell - 3), cornerRadius: cell * 0.18)
                tile.fillColor = Palette.cell
                tile.strokeColor = Palette.cellStroke
                tile.lineWidth = 1
                tile.position = position(of: Point(x, y))
                boardLayer.addChild(tile)
            }
        }
        for p in level.walls { boardLayer.addChild(makeWall(at: position(of: p))) }
        for p in level.webs { boardLayer.addChild(makeWeb(at: position(of: p))) }
        for (p, d) in level.arrows { boardLayer.addChild(makeArrow(at: position(of: p), direction: d)) }
        for (i, l) in level.lanterns.enumerated() {
            let node = LanternNode(color: soulColor(l.color), capacity: l.capacity, cell: cell)
            node.position = position(of: l.position)
            node.setFill(Int(current.fill[i]))
            node.setDimmed(deadEnd, animated: false)
            boardLayer.addChild(node)
            lanternNodes.append(node)
        }
        for (p, lanternIndex) in level.gates {
            let node = makeGate(color: soulColor(level.lanterns[lanternIndex].color))
            node.position = position(of: p)
            boardLayer.addChild(node)
            gateNodes.append((node, lanternIndex))
        }
        updateGates(current)

        for (i, w) in level.wisps.enumerated() where current.hasWisp(i) {
            let node = makeWisp(color: soulColor(w.color))
            node.position = position(of: w.position)
            pieceLayer.addChild(node)
            wispNodes[i] = node
        }
        for (k, c) in current.body.dropFirst().enumerated() {
            let segment = makeSegment(color: soulColor(Int(current.colors[k])))
            segment.position = position(ofCell: c)
            pieceLayer.addChild(segment)
            segments.append(segment)
        }
        ghost = makeGhost()
        ghost.position = position(ofCell: current.body[0])
        pieceLayer.addChild(ghost)
    }

    private func soulColor(_ raw: Int) -> SoulColor { SoulColor(rawValue: raw) ?? .amber }

    /// Mezar taşı: kemerli üst, düz gövde, küçük haç. Duvar (§2.1).
    private func makeWall(at p: CGPoint) -> SKNode {
        let node = SKNode()
        node.position = p
        let w = cell * 0.6
        let h = cell * 0.72
        let top = SKShapeNode(ellipseOf: CGSize(width: w, height: w))
        top.position = CGPoint(x: 0, y: h / 2 - w / 2)
        let base = SKShapeNode(rectOf: CGSize(width: w, height: h - w / 2))
        base.position = CGPoint(x: 0, y: -w / 4)
        for part in [top, base] {
            part.fillColor = Palette.stone
            part.strokeColor = Palette.stone
            part.lineWidth = 1
            node.addChild(part)
        }
        let bar = SKShapeNode(rectOf: CGSize(width: w * 0.5, height: 3), cornerRadius: 1.5)
        let post = SKShapeNode(rectOf: CGSize(width: 3, height: w * 0.5), cornerRadius: 1.5)
        for part in [bar, post] {
            part.fillColor = Palette.stoneMark
            part.strokeColor = .clear
            part.position = CGPoint(x: 0, y: h * 0.1)
            node.addChild(part)
        }
        return node
    }

    /// Örümcek ağı: dört çapraz çizgi ve iki halka.
    private func makeWeb(at p: CGPoint) -> SKNode {
        let path = CGMutablePath()
        let r = cell * 0.4
        for i in 0..<4 {
            let a = CGFloat(i) * .pi / 4
            path.move(to: CGPoint(x: -r * cos(a), y: -r * sin(a)))
            path.addLine(to: CGPoint(x: r * cos(a), y: r * sin(a)))
        }
        for k: CGFloat in [0.35, 0.7] {
            let rr = r * k
            path.addEllipse(in: CGRect(x: -rr, y: -rr, width: 2 * rr, height: 2 * rr))
        }
        let node = SKShapeNode(path: path)
        node.strokeColor = Palette.web
        node.fillColor = .clear
        node.lineWidth = 1
        node.position = p
        return node
    }

    /// Yön oku: yukarı bakan ok, yöne göre döndürülür.
    private func makeArrow(at p: CGPoint, direction: Direction) -> SKNode {
        let r = cell * 0.3
        let path = CGMutablePath()
        path.move(to: CGPoint(x: 0, y: r))
        path.addLine(to: CGPoint(x: r * 0.85, y: -r * 0.45))
        path.addLine(to: CGPoint(x: 0, y: -r * 0.05))
        path.addLine(to: CGPoint(x: -r * 0.85, y: -r * 0.45))
        path.closeSubpath()
        let node = SKShapeNode(path: path)
        node.fillColor = Palette.arrow
        node.strokeColor = .clear
        node.position = p
        switch direction {
        case .up: node.zRotation = 0
        case .right: node.zRotation = -.pi / 2
        case .down: node.zRotation = .pi
        case .left: node.zRotation = .pi / 2
        }
        return node
    }

    /// Fener kapısı: bağlı fenerin renginde parmaklık; fener dolunca solar.
    private func makeGate(color: SoulColor) -> SKNode {
        let node = SKNode()
        let frame = SKShapeNode(rectOf: CGSize(width: cell * 0.78, height: cell * 0.78), cornerRadius: cell * 0.12)
        frame.fillColor = Palette.lanternBody
        frame.strokeColor = color.uiColor
        frame.lineWidth = 2
        node.addChild(frame)
        for i in -1...1 {
            let bar = SKShapeNode(rectOf: CGSize(width: 2, height: cell * 0.62))
            bar.fillColor = color.uiColor
            bar.strokeColor = .clear
            bar.position = CGPoint(x: CGFloat(i) * cell * 0.2, y: 0)
            node.addChild(bar)
        }
        let key = SKShapeNode(path: color.shape.path(radius: cell * 0.11))
        key.fillColor = Palette.lanternBody
        key.strokeColor = color.uiColor
        key.lineWidth = 1.5
        node.addChild(key)
        return node
    }

    private func updateGates(_ s: State) {
        for gate in gateNodes {
            let open = Int(s.fill[gate.lantern]) >= level.lanterns[gate.lantern].capacity
            gate.node.alpha = open ? 0.18 : 1
        }
    }

    /// Ruh: renkli alev, içinde beyaz çekirdek; şekil renge bağlı (§2.1).
    private func makeWisp(color: SoulColor) -> SKNode {
        let node = SKNode()
        let glow = SKShapeNode(circleOfRadius: cell * 0.3)
        glow.fillColor = color.uiColor.withAlphaComponent(0.18)
        glow.strokeColor = .clear
        node.addChild(glow)
        let body = SKShapeNode(path: color.shape.path(radius: cell * 0.24))
        body.fillColor = color.uiColor
        body.strokeColor = .clear
        node.addChild(body)
        let core = SKShapeNode(path: color.shape.path(radius: cell * 0.1))
        core.fillColor = UIColor(white: 1, alpha: 0.85)
        core.strokeColor = .clear
        node.addChild(core)
        if !reduceMotion && animationScale > 0 {
            let up = SKAction.moveBy(x: 0, y: cell * 0.05, duration: 0.9)
            up.timingMode = .easeInEaseOut
            node.run(.repeatForever(.sequence([up, up.reversed()])))
        }
        return node
    }

    /// Gövde parçası: taşınan ruhun şekli, açık renkli yastık içinde.
    private func makeSegment(color: SoulColor) -> SKNode {
        let node = SKNode()
        let pill = SKShapeNode(rectOf: CGSize(width: cell * 0.66, height: cell * 0.66), cornerRadius: cell * 0.22)
        pill.fillColor = Palette.ghost.withAlphaComponent(0.85)
        pill.strokeColor = .clear
        node.addChild(pill)
        let mark = SKShapeNode(path: color.shape.path(radius: cell * 0.16))
        mark.fillColor = color.uiColor
        mark.strokeColor = .clear
        node.addChild(mark)
        return node
    }

    /// Hayalet (geçici çizim, §9): oval gövde, iki göz. Dalgalı alt kenar ve dil yok.
    private func makeGhost() -> SKNode {
        let node = SKNode()
        let body = SKShapeNode(ellipseOf: CGSize(width: cell * 0.72, height: cell * 0.8))
        body.fillColor = Palette.ghost
        body.strokeColor = .clear
        node.addChild(body)
        for side: CGFloat in [-1, 1] {
            let eye = SKShapeNode(circleOfRadius: cell * 0.06)
            eye.fillColor = Palette.ghostEye
            eye.strokeColor = .clear
            eye.position = CGPoint(x: side * cell * 0.13, y: cell * 0.08)
            node.addChild(eye)
        }
        node.zPosition = 10
        return node
    }

    // MARK: - Kaydırma animasyonu

    /// Adımları sırayla oynatır; bitince `completion`. Anında modda hepsi hemen uygulanır.
    func play(_ result: SlideResult, completion: @escaping () -> Void) {
        guard !isAnimating else { return }
        if animationScale <= 0 {
            for step in result.steps { apply(step, duration: 0) }
            completion()
            return
        }
        isAnimating = true
        runStep(result.steps, index: 0, completion: completion)
    }

    /// ~80 ms/kare başlangıç değeri; uzun kaymada hızlanır, 35 ms'nin altına inmez (§9).
    private func stepDuration(_ index: Int) -> TimeInterval {
        max(0.035, 0.08 * pow(0.86, Double(min(index, 10)))) * animationScale
    }

    private func runStep(_ steps: [SlideStep], index: Int, completion: @escaping () -> Void) {
        guard index < steps.count else {
            isAnimating = false
            completion()
            return
        }
        let duration = stepDuration(index)
        apply(steps[index], duration: duration)
        run(.wait(forDuration: duration)) { [weak self] in
            guard let self else { return }
            self.finish(steps[index])
            self.runStep(steps, index: index + 1, completion: completion)
        }
    }

    /// Bırakmadan önceki gövde: adım sonu gövdesi + bu adımda fenere giren kuyruk kareleri
    /// (ilk bırakılan en dıştaki kuyruktur).
    private func preDepositBody(_ step: SlideStep) -> [UInt8] {
        step.state.body + step.deposited.reversed().map { UInt8(level.cell(level.lanterns[$0].position)) }
    }

    /// Adımın hareketini başlatır: baş bir kare ilerler, gövde onu izler, toplanan ruh parçaya döner.
    private func apply(_ step: SlideStep, duration: TimeInterval) {
        let body = preDepositBody(step)
        if let w = step.collected, body.count > 1 {
            let segment = makeSegment(color: soulColor(level.wisps[w].color))
            segment.position = position(ofCell: body[1])   // eski baş karesi
            pieceLayer.addChild(segment)
            segments.insert(segment, at: 0)
            if let node = wispNodes.removeValue(forKey: w) {
                if duration > 0 {
                    node.run(.sequence([.fadeOut(withDuration: duration), .removeFromParent()]))
                } else {
                    node.removeFromParent()
                }
            }
            onCollect?()
        }
        move(ghost, to: position(ofCell: body[0]), duration: duration)
        for (k, segment) in segments.enumerated() where k + 1 < body.count {
            move(segment, to: position(ofCell: body[k + 1]), duration: duration)
        }
        if duration <= 0 { finish(step) }
    }

    private func move(_ node: SKNode, to point: CGPoint, duration: TimeInterval) {
        guard duration > 0 else {
            node.position = point
            return
        }
        let action = SKAction.move(to: point, duration: duration)
        action.timingMode = .linear
        node.run(action)
    }

    /// Adımın sonu: fenere giren kuyruk parçaları kalkar, fener yanar, kapılar güncellenir.
    private func finish(_ step: SlideStep) {
        let keep = max(0, step.state.body.count - 1)
        while segments.count > keep {
            let segment = segments.removeLast()
            if animationScale > 0 {
                let vanish = SKAction.group([.fadeOut(withDuration: 0.12), .scale(to: 0.4, duration: 0.12)])
                segment.run(.sequence([vanish, .removeFromParent()]))
            } else {
                segment.removeFromParent()
            }
        }
        for lantern in step.deposited {
            lanternNodes[lantern].setFill(Int(step.state.fill[lantern]))
            onDeposit?()
        }
        updateGates(step.state)
        current = step.state
    }
}
