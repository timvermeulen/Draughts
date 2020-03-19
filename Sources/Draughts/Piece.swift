public struct Piece {
    public enum Kind {
        case man, king
    }
    
    public let player: Player
    public var kind: Kind
    public var square: Square
}

extension Piece {
    public var isValid: Bool {
        return kind == .king || !square.isOnPromotionRow(of: player)
    }
}

extension Piece {
    public enum Direction {
        case left, right
    }
}

extension Piece: Equatable {}
extension Piece: Hashable {}

extension Piece: CustomStringConvertible {
    public var description: String {
        let symbol: Character
        
        switch (player, kind) {
        case (.white, .man):
            symbol = "w"
        case (.white, .king):
            symbol = "W"
        case (.black, .man):
            symbol = "b"
        case (.black, .king):
            symbol = "B"
        }
        
        return "\(symbol)\(square)"
    }
}
