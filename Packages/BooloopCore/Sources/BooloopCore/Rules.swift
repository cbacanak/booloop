// Kayma kuralı (PLAN.md §2.2–2.5). `tools/booloop_gen.py` içindeki `slide` ile
// adım adım aynıdır; farklı davranırsa hata buradadır.

extension Level {
    /// Geçerli kaydırma sonrası durum; hayalet en az bir kare ilerleyemiyorsa `nil`.
    public func slide(_ state: State, _ direction: Direction) -> State? {
        var s = state
        var steps: [SlideStep] = []
        return advance(&s, direction, record: false, steps: &steps) ? s : nil
    }

    /// `slide` ile aynı sonuç, artı sahnenin çizeceği kare kare adımlar.
    public func slideSteps(_ state: State, _ direction: Direction) -> SlideResult? {
        var s = state
        var steps: [SlideStep] = []
        return advance(&s, direction, record: true, steps: &steps) ? SlideResult(steps: steps) : nil
    }

    /// Bir hamle dizisini baştan oynatır. Geçersiz hamle `nil` döndürür.
    public func replay(_ moves: [Direction], from state: State? = nil) -> State? {
        var s = state ?? start
        for d in moves {
            guard let n = slide(s, d) else { return nil }
            s = n
        }
        return s
    }

    private func advance(_ s: inout State, _ direction: Direction, record: Bool, steps: inout [SlideStep]) -> Bool {
        var d = direction
        var moved = false
        var guardCount = 0
        while true {
            if isWon(s) { break }                                   // 4. bütün fenerler doldu
            guardCount += 1
            if guardCount > cellCount * 4 { break }                 // ok döngüsü koruması
            let head = Int(s.body[0])
            let nx = head % width + d.dx, ny = head / width + d.dy
            guard nx >= 0, ny >= 0, nx < width, ny < height else { break }
            let n = nx + ny * width
            if wallAt[n] { break }
            let g = gateAt[n]
            if g >= 0 && s.fill[Int(g)] < capacities[Int(g)] { break }   // kapı kapalı

            let w = Int(wispAt[n])
            let grow = w >= 0 && s.hasWisp(w)
            // Kuyruğun son karesi bu adımda boşalacaksa engel değil; ruh toplanıyorsa engel.
            let bodyEnd = grow ? s.body.count : s.body.count - 1
            if s.body[0..<bodyEnd].contains(UInt8(n)) { break }

            s.body.insert(UInt8(n), at: 0)
            if grow {
                s.wisps &= ~(1 << UInt32(w))
                s.colors.insert(UInt8(wisps[w].color), at: 0)
            } else {
                s.body.removeLast()
            }

            var deposited: [Int] = []
            while let color = s.colors.last {                      // kuyruktan bırakma (zincir)
                let l = Int(lanternAt[Int(s.body[s.body.count - 1])])
                guard l >= 0, lanterns[l].color == Int(color), s.fill[l] < capacities[l] else { break }
                s.fill[l] += 1
                s.colors.removeLast()
                s.body.removeLast()
                deposited.append(l)
            }
            moved = true
            if record {
                steps.append(SlideStep(direction: d, state: s, collected: grow ? w : nil, deposited: deposited))
            }

            if webAt[n] { break }                                   // ağ durdurur
            let a = arrowAt[n]
            if a >= 0 { d = Direction(rawValue: Int(a))! }         // ok yönü çevirir
        }
        return moved
    }
}
