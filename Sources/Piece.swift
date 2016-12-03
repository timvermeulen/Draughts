public struct Piece {
    public enum Kind {
        case man, king
    }
    
    public let player: Player
    public var kind: Kind
    public var square: Square
    
    public init(player: Player, kind: Kind, square: Square) {
        self.player = player
        self.kind = kind
        self.square = square
    }
}

extension Piece {
    public enum Direction {
        case left, right
    }
}

extension Piece: Equatable {
    public static func == (left: Piece, right: Piece) -> Bool {
        return left.player == right.player && left.kind == right.kind && left.square == right.square
    }
}

extension Piece: Hashable {
    public var hashValue: Int {
        return self.player.hashValue ^ self.square.hashValue
    }
}

extension Piece: CustomStringConvertible {
    public var description: String {
        let symbol: Character
        
        switch (self.player, self.kind) {
        case (.white, .man): symbol = "w"
        case (.white, .king): symbol = "W"
        case (.black, .man): symbol = "b"
        case (.black, .king): symbol = "B"
        }
        
        return "\(symbol)\(self.square)"
    }
}
