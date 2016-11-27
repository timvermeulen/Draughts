extension Game {
    public init?(pdn: String, position: Position = .start) {
        fatalError()
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
