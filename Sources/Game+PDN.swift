import Foundation

extension Game {
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
                
                guard let start = squares.first, let end = squares.last else { return nil }
                
                for square in squares.dropFirst().dropLast() {
                    helper.toggle(square)
                }
                
                guard helper.move(from: start, to: end) else { return nil }
            }
        }
        
        self = helper.game
    }
    
    public var pdn: String {
        let moveNotations: [String] = zip(self.moves.indices, zip(self.moves, self.variations)).map { ply, pair in
            let withoutVariations = "\(ply.player == .white ? "\((ply.number + 1) / 2 + 1). " : "")\(pair.0.unambiguousNotation)"
            let variations = pair.1
            return variations.isEmpty ? withoutVariations : "\(withoutVariations) (\(variations.map { $0.variation.pdn }.joined(separator: "; ")))"
        }
        
        let withoutPrefixPly = moveNotations.joined(separator: " ")
        return self.startPly.player == .white ? withoutPrefixPly : "\(self.startPly.number / 2 + 1). ... \(withoutPrefixPly)"
    }
}
