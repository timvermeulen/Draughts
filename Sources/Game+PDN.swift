import Parser

extension Game {
    public init?(pdn: String, position: Position = .start) {
        struct Move {
            let start, end: Square
            let intermediate: [Square]
            
            init?(squares: [Square]) {
                guard let first = squares.first, let last = squares.last, squares.count >= 2 else { return nil }
                
                start = first
                end = last
                intermediate = Array(squares.dropFirst().dropLast())
            }
        }
        
        enum Token {
            case move(Move)
            case startVariation
            case endVariation
            case nextVariation
        }
        
        let square = Parser.number.flatMap(Square.init(checkingHumanValue:))
        let move = square.any(separator: .character("x") <|> .character("-")).flatMap(Move.init).map(Token.move)
        
        let token: StringParser<Token> = move
            <|> Parser.character("(").onMatch(.startVariation)
            <|> Parser.character(")").onMatch(.endVariation)
            <|> Parser.character(";").onMatch(.nextVariation)
        
        let filling = ((Parser.number.optional.ignored <* Parser.character(".").many as StringParser<String>) <|> Parser.character(" ").ignored).any
        let parser = filling *> token.any(separator: filling) <* filling
        
        guard let tokens = parser.run(pdn)?.result else { return nil }
        let helper = GameHelper(position: position)
        
        for token in tokens {
            switch token {
            case .startVariation:
                helper.backward()
            case .endVariation:
                if !helper.popVariation() || !helper.forward() { return nil }
            case .nextVariation:
                if !helper.popVariation() { return nil }
            case .move(let move):
                if !move.intermediate.contains(where: helper.toggle) && !helper.move(from: move.start, to: move.end) { return nil }
            }
        }
        
        self = helper.game
    }
    
    private func variationsNotation(of variations: OrderedDictionary<Draughts.Move, Game>, at ply: Ply, includeVariation: (_ variation: Game, _ parentVariation: Game) throws -> Bool) rethrows -> String? {
        let notations: [String] = try variations.compactMap { move, variation in
            guard try includeVariation(variation, self) else { return nil }
            
            let withoutVariation = "\(ply.indicator) \(move.unambiguousNotation)"
            return try variation.moves.isEmpty ? withoutVariation : "\(withoutVariation) \(variation.makePDN(includingInitialBlackIndicator: false, includeVariation: includeVariation))"
        }
        
        return notations.isEmpty ? nil : "(\(notations.joined(separator: "; ")))"
    }
    
    internal func makePDN(includingInitialBlackIndicator: Bool = true, includeVariation: (_ variation: Game, _ parentVariation: Game) throws -> Bool) rethrows -> String {
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
    
    public var pdnWithoutRedundantVariations: String {
        return makePDN(includeVariation: { !$1.game(from: $0.startPly).getEndPositions(allowCrossVariationMoves: false).isSuperset(of: $0.getEndPositions(allowCrossVariationMoves: true)) })
    }
    
    public var pdn: String {
        return makePDN(includingInitialBlackIndicator: true, includeVariation: { _,_  in true })
    }
}
