extension Game {
    // TODO: make this a throwing initializer
    public init?(pdn: String, position: Position = .start) {
        let enhanced = ["(", ")", ";"].reduce(pdn) { $0.replacing($1, with: " \($1) ") }
        let helper = GameHelper(position: position)
        
        for component in enhanced.components(separatedByCharactersIn: " ") {
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
                    .components(separatedByCharactersIn: "-x")
                    .flatMap { Int($0) }
                    .filter((1...50).contains)
                    .map { Square(humanValue: $0) }
                
                guard
                    let start = squares.first, let end = squares.last,
                    squares.dropFirst().dropLast().contains(where: helper.toggle) || helper.move(from: start, to: end)
                    else { return nil }
            }
        }
        
        self = helper.game
    }
    
    private func variationsNotation(of variations: OrderedDictionary<Draughts.Move, Game>, at ply: Ply, includeVariation: (Game) throws -> Bool) rethrows -> String? {
        let notations: [String] = try variations.flatMap { move, variation in
            guard try includeVariation(variation) else { return nil }
            
            let withoutVariation = "\(ply.indicator) \(move.unambiguousNotation)"
            return try variation.moves.isEmpty ? withoutVariation : "\(withoutVariation) \(variation.makePDN(includingInitialBlackIndicator: false, includeVariation: includeVariation))"
        }
        
        return notations.isEmpty ? nil : "(\(notations.joined(separator: "; ")))"
    }
    
    internal func makePDN(includingInitialBlackIndicator: Bool = true, includeVariation: (Game) throws -> Bool) rethrows -> String {
        let moveNotations: [String] = try zip(moves.indices, zip(moves, variations)).map { (ply: Ply, pair: (move: Draughts.Move, variations: OrderedDictionary<Draughts.Move, Game>)) in
            let withoutIndicator = pair.move.unambiguousNotation
            let withoutVariations = ply.player == .white ? "\(ply.indicator) \(withoutIndicator)" : withoutIndicator
            
            return try variationsNotation(of: pair.variations, at: ply, includeVariation: includeVariation).map { "\(withoutVariations) \($0)" } ?? withoutVariations
        }
        
        let withoutBlackPlyIndicator = moveNotations.joined(separator: " ")
        let withoutFinalVariations = startPly.player == .white || !includingInitialBlackIndicator
            ? withoutBlackPlyIndicator
            : "\(self.startPly.indicator) \(withoutBlackPlyIndicator)"
        
        return try variationsNotation(of: endVariations, at: endPly, includeVariation: includeVariation).map { "\(withoutFinalVariations) \($0)" } ?? withoutFinalVariations
    }
    
    public var relevantPDN: String {
        return makePDN(includeVariation: { !game(from: $0.startPly).endPositions.isSuperset(of: $0.endPositions) })
    }
    
    public var pdn: String {
        return makePDN(includingInitialBlackIndicator: true, includeVariation: { _ in true })
    }
}
