public struct Ply {
    public let player: Player
    public let number: Int
    
    public init(player: Player = .white, number: Int = 0) {
        self.player = player
        self.number = number
    }
}

extension Ply {
    public var predecessor: Ply {
        return Ply(player: self.player.opponent, number: self.number - 1)
    }
    
    public var successor: Ply {
        return Ply(player: self.player.opponent, number: self.number + 1)
    }
}

extension Ply {
    public var indicator: String {
        switch self.player {
        case .white: return "\((self.number + 1) / 2 + 1)."
        case .black: return "\(self.number / 2 + 1). ..."
        }
    }
}

extension Ply: Comparable {
    public static func < (left: Ply, right: Ply) -> Bool {
        return left.number < right.number
    }
    
    public static func == (left: Ply, right: Ply) -> Bool {
        return left.number == right.number
    }
}
