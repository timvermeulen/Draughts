import Parser

extension Parser {
    public var ignored: Parser<Void> {
        return self.map { _ in () }
    }
    
    public static func surrounding<Start, End>(_ parser: @escaping @autoclosure () -> Parser, by start: Parser<Start>, and end: @escaping @autoclosure () -> Parser<End>) -> Parser {
        return start.ignored.flatMap {
            parser().flatMap { value in
                end().ignored.map { value }
            }
        }
    }
}

extension Parsers {
    internal static var square: Parser<Square> {
        return Parser(self.number, where: (1 ... 50).contains).map { Square(humanValue: $0) }
    }
    
    internal static var moveSeparator: Parser<Character> {
        return Parser(self.character, where: ["-", "x"].contains)
    }
    
    internal static var move: Parser<[Square]> {
        return self.square.many(separator: self.moveSeparator)
    }
    
    internal static var plyIndicator: Parser<String> {
        return self.number.flatMap { number in
            self.character(".").many(separator: self.character(" ").optional).map { suffix in
                "\(number)\(String(suffix))"
            }
        }
    }
    
    internal static var moves: Parser<(Game) -> Game?> {
        let separator = (self.character(" ").ignored ?? self.plyIndicator.ignored).any()
        
        return separator.flatMap { _ in
            self.move.any(separator: separator).map { moves in
                { game in
                    let helper = GameHelper(game)
                    
                    for squares in moves {
                        guard helper.toggle(squares) else { return nil }
                    }
                    
                    return helper.game
                }
            }
        }
    }
    
    internal static var variation: Parser<(Game) -> Game?> {
        return Parser.surrounding(self.movesAndVariations.many(separator: character(";")), by: character("("), and: character(")")).map { transformations in
            { game in
                var game = game
                
                for transform in transformations {
                    guard
                        let secondToLastPosition = game.positions.dropLast().last,
                        let variation = transform(Game(position: secondToLastPosition)),
                        let move = variation.moves.first
                        else { return nil }
                    
                    game.variations[variation.startPly].append((move, variation))
                }
                
                return game
            }
        }
    }
    
    internal static var movesAndVariations: Parser<(Game) -> Game?> {
        return (self.moves ?? self.variation).many().map { transformations in
            { game in
                var game = game
                
                for transform in transformations {
                    guard let newGame = transform(game) else { return nil }
                    game = newGame
                }
                
                return game
            }
        }
    }
}

extension Game {
    public init?(pdn: String, position: Position = .start) {
        let parser = Parsers.moves.flatMap { $0(Game(position: position)) }
        guard let (game, _) = parser.run(pdn) else { return nil }
        self = game
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
