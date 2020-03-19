import Parser

extension Position {
    public var fen: String {
        func pieceSymbols(of player: Player, kind: Piece.Kind) -> String? {
            let result = self
                .pieces(of: player, kind: kind)
                .serialized()
                .lazy
                .reversed()
                .map { "\(kind == .king ? "K" : "")\($0)" }
                .joined(separator: ",")
            
            return Optional(result, where: { !$0.isEmpty })
        }
        
        let pieceSymbolsOfPlayer = { [pieceSymbols(of: $0, kind: .man), pieceSymbols(of: $0, kind: .king)].compactMap { $0 }.joined(separator: ",") }
        return "\(playerToMove == .white ? "W" : "B"):W\(pieceSymbolsOfPlayer(.white)):B\(pieceSymbolsOfPlayer(.black))"
    }
    
    public convenience init?(fen: String) {
        func pieces(for player: Player) -> StringParser<[Piece]> {
            let square = Parser.number.compactMap(Square.init(checkingHumanValue:))
            
            let man  = curry(Piece.init) <^> .result(player) <*>                    .result(.man)  <*> square
            let king = curry(Piece.init) <^> .result(player) <*> .character("K") *> .result(.king) <*> square
            
            return  (man <|> king).any(separator: .character(",")) <* Parser.character(",").optional
        }
        
        let playerToMove: StringParser<Player> = Parser.character("W").onMatch(.white) <|> Parser.character("B").onMatch(.black)
        let tuple = makeTuple <^> playerToMove <* .string(":W") <*> pieces(for: .white) <* .string(":B") <*> pieces(for: .black)
        
        guard let ((player, whitePieces, blackPieces), _) = tuple.run(fen) else { return nil }
        self.init(pieces: whitePieces + blackPieces, playerToMove: player)
    }
}
