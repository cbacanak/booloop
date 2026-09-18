/// Oyun durumu. `booloop_gen.py`'deki `(pos, cols, wisps, fill)` dörtlüsünün karşılığı.
public struct State: Hashable, Sendable {
    /// Gövde kareleri, baş önce. Kuyruk ucu en önce toplanan ruhtur.
    public internal(set) var body: [UInt8]
    /// Baştan sonraki her gövde parçasının rengi; `colors.count == body.count - 1`.
    public internal(set) var colors: [UInt8]
    /// Henüz toplanmamış ruhlar: `level.wisps` indekslerinin bit maskesi.
    public internal(set) var wisps: UInt32
    /// Fener başına bırakılmış ruh sayısı; `level.lanterns` sırasıyla.
    public internal(set) var fill: [UInt8]

    public func hasWisp(_ index: Int) -> Bool { wisps & (1 << UInt32(index)) != 0 }
}

/// Bir kaydırmanın tek karelik adımı; sahne bunları sırayla çizer.
public struct SlideStep: Sendable, Equatable {
    /// Başın bu adımda ilerlediği yön. Ok karesine girilince sonraki adımın yönü değişir.
    public var direction: Direction
    /// Adım sonrası durum.
    public var state: State
    /// Bu adımda toplanan ruhun `level.wisps` indeksi.
    public var collected: Int?
    /// Bu adımda sırayla dolan fener indeksleri (zincirleme bırakma).
    public var deposited: [Int]
}

public struct SlideResult: Sendable, Equatable {
    public var steps: [SlideStep]
    public var state: State { steps[steps.count - 1].state }
}
