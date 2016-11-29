import Foundation

extension Position {
    public var fen: String {
        func pieceSymbols(of player: Player, kind: Piece.Kind) -> String? {
            let result = self
                .pieces(of: player, kind: kind)
                .map { "\(kind == .king ? "K" : "")\($0)" }
                .joined(separator: ",")
            
            return result.isEmpty ? nil : result
        }
        
        func pieceSymbols(of player: Player) -> String {
            return [pieceSymbols(of: player, kind: .man), pieceSymbols(of: player, kind: .king)].flatMap { $0 }.joined(separator: ",")
        }
        
        return "\(self.playerToMove == .white ? "W" : "B"):W\(pieceSymbols(of: .white)):B\(pieceSymbols(of: .black))"
    }
    
    public convenience init?(fen: String) {
        let components = fen.trimmingCharacters(in: .whitespacesAndNewlines).components(separatedBy: ":")
        guard components.count == 3 && !components[1].isEmpty && !components[2].isEmpty else { return nil }
        
        var white = Bitboard.empty
        var black = Bitboard.empty
        var kings = Bitboard.empty
        let player: Player = components[0] == "W" ? .white : .black
        
        for (component, player): (String, Player) in [(components[1], .white), (components[2], .black)] {
            let pieceStrings = String(component.characters.dropFirst()).components(separatedBy: ",")
            
            let men = pieceStrings
                .filter { $0.characters.first != "K" }
                .flatMap { Int($0) }
                .map(Square.init(humanValue:))
            
            let theKings = pieceStrings
                .filter { $0.characters.first == "K" }
                .flatMap { Int($0.substring(from: $0.index(after: $0.startIndex))) }
                .map(Square.init(humanValue:))
            
            for man in men {
                switch player {
                case .white: white.formUnion(Bitboard(square: man))
                case .black: black.formUnion(Bitboard(square: man))
                }
            }
            
            for king in theKings {
                switch player {
                case .white: white.formUnion(Bitboard(square: king))
                case .black: black.formUnion(Bitboard(square: king))
                }
                
                kings.formUnion(Bitboard(square: king))
            }
        }
        
        self.init(white: white, black: black, kings: kings, playerToMove: player)
    }
}
