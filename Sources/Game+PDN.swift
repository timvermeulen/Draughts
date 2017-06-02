import Foundation

extension Game {
    // TODO: make this a throwing initializer
    public init?(pdn: String, position: Position = .start) {
        let separators = CharacterSet(charactersIn: "-x")
        let enhanced = ["(", ")", ";"].reduce(pdn) { $0.replacingOccurrences(of: $1, with: " \($1) ") }
        let helper = GameHelper(position: position)
        
        for component in enhanced.components(separatedBy: .whitespacesAndNewlines) {
            switch component {
            case "":
                break
            case "(":
                helper.backward()
            case ")":
                if !helper.popVariation() || !helper.forward() { return nil }
            case ";":
                if !helper.popVariation() { return nil }
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
    
    internal func toPDN(includingInitialBlackIndicator: Bool) -> String {
        func variationsNotation(of variations: OrderedDictionary<Move, Game>, at ply: Ply) -> String? {
            guard !variations.isEmpty else { return nil }
            
            let notations: [String] = variations.lazy.map {
                let (move, variation) = $0
                
                let withoutVariation = "\(ply.indicator) \(move.unambiguousNotation)"
                return variation.moves.isEmpty ? withoutVariation : "\(withoutVariation) \(variation.toPDN(includingInitialBlackIndicator: false))"
            }
            
            return "(\(notations.joined(separator: "; ")))"
        }
        
        let moveNotations: [String] = zip(moves.indices, zip(moves, variations)).map {
            let (ply, (move, variations)) = $0
            
            let withoutIndicator = move.unambiguousNotation
            let withoutVariations = ply.player == .white ? "\(ply.indicator) \(withoutIndicator)" : withoutIndicator
            
            return variationsNotation(of: variations, at: ply).map { "\(withoutVariations) \($0)" } ?? withoutVariations
        }
        
        let withoutBlackPlyIndicator = moveNotations.joined(separator: " ")
        let withoutFinalVariations = startPly.player == .white || !includingInitialBlackIndicator
            ? withoutBlackPlyIndicator
            : "\(startPly.indicator) \(withoutBlackPlyIndicator)"
        
        return variationsNotation(of: endVariations, at: endPly).map { "\(withoutFinalVariations) \($0)" } ?? withoutFinalVariations
    }
    
    public var pdn: String {
        return toPDN(includingInitialBlackIndicator: true)
    }
}
