import Foundation

extension Game {
    // TODO: make this a throwing initializer
    public init?(pdn: String, position: Position = .start) {
        let separators = CharacterSet(charactersIn: "-x")
        let enhanced = ["(", ")", ";"].reduce(pdn) { $0.replacingOccurrences(of: $1, with: " \($1) ") }
        let helper = GameHelper(Game(position: position))
        
        for component in enhanced.components(separatedBy: .whitespacesAndNewlines) {
            switch component {
            case "": break
            case "(": helper.backward()
            case ")": if !helper.popVariation() || !helper.forward() { return nil }
            case ";": if !helper.popVariation() { return nil }
            default:
                guard !component.hasSuffix(".") else { continue }
                
                let squares = component
                    .components(separatedBy: separators)
                    .flatMap { Int($0) }
                    .filter((1 ... 50).contains)
                    .map { Square(humanValue: $0) }
                
                guard
                    let start = squares.first, let end = squares.last,
                    squares.dropFirst().dropLast().contains(where: helper.toggle) || helper.move(from: start, to: end)
                    else { return nil }
            }
        }
        
        self = helper.game
    }
    
    public var pdn: String {
        let moveNotations: [String] = zip(self.moves.indices, zip(self.moves, self.variations)).map { (ply: Ply, pair: (move: Move, variations: OrderedDictionary<Move, Game>)) in
            let withoutVariations = "\(ply.player == .white ? "\(ply.indicator) " : "")\(pair.move.unambiguousNotation)"
            let variations = pair.variations
            return variations.isEmpty ? withoutVariations : "\(withoutVariations) (\(variations.map { $0.value.pdn }.joined(separator: "; ")))"
        }
        
        let withoutBlackPlyIndicator = moveNotations.joined(separator: " ")
        return self.startPly.player == .white ? withoutBlackPlyIndicator : "\(self.startPly.indicator) \(withoutBlackPlyIndicator)"
    }
}
