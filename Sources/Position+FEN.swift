import Foundation

extension Position {
    public init?(fen: String) {
        let components = fen.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ":")
        guard components.count == 3 && !components[1].isEmpty && !components[2].isEmpty else { return nil }
        
        var white = Bitboard.empty
        var black = Bitboard.empty
        var theKings = Bitboard.empty
        let player: Player = components[0] == "W" ? .white : .black
        
        for (component, player): (String, Player) in [(components[1], .white), (components[2], .black)] {
            let pieceStrings = String(component.characters.dropFirst()).components(separatedBy: ",")
            
            let men = pieceStrings
                .filter { $0.characters.first != "K" }
                .flatMap { Int($0) }
                .map(Square.init(humanValue:))
            
            let kings = pieceStrings
                .filter { $0.characters.first == "K" }
                .flatMap { Int($0.substring(from: $0.index(after: $0.startIndex))) }
                .map(Square.init(humanValue:))
            
            for man in men {
                switch player {
                case .white: white |= Bitboard(man)
                case .black: black |= Bitboard(man)
                }
            }
            
            for king in kings {
                switch player {
                case .white: white |= Bitboard(king)
                case .black: black |= Bitboard(king)
                }
                theKings |= Bitboard(king)
            }
        }
        
        self.init(white: white, black: black, kings: theKings, ply: Ply(player: player))
    }
}
