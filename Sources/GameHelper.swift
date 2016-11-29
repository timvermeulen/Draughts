public final class GameHelper {
    public fileprivate(set) var game: Game
    fileprivate var ply: Ply {
        didSet { self.reloadMovePicker() }
    }
    fileprivate var indices: [(ply: Ply, index: Int)]
    fileprivate var movePicker: MovePicker
    
    public init(_ game: Game) {
        self.game = game
        self.ply = game.endPly
        self.indices = []
        self.movePicker = MovePicker(game.endPosition)
    }
}

extension Game {
    fileprivate mutating func setVariation<I: IteratorProtocol>(_ variation: Game, indices: I) where I.Element == (ply: Ply, index: Int) {
        var indices = indices
        
        if let (ply, index) = indices.next() {
            self.variations[ply][index].variation.setVariation(variation, indices: indices)
        } else {
            self = variation
        }
    }
}

extension GameHelper {
    fileprivate var variation: Game {
        get {
            return self.indices.reduce(self.game) { (game, pair) in
                game.variations[pair.ply][pair.index].variation
            }
        }
        set {
            self.game.setVariation(newValue, indices: self.indices.makeIterator())
        }
    }
    
    public var position: Position {
        return self.variation.positions[self.ply]
    }
    
    fileprivate func reloadMovePicker() {
        self.movePicker = MovePicker(self.variation.positions[self.ply])
    }
    
    /// returns: `true` if a variation could be popped, `false` otherwise
    @discardableResult
    public func play(_ move: Move) -> Bool {
        guard self.variation.positions[self.ply].moveIsValid(move) else { return false }
        
        if let index = self.variation.play(move, at: self.ply) {
            self.indices.append((self.ply, index))
        }
        
        guard self.forward() else { fatalError("this shouldn't happen") }
        return true
    }
}

extension GameHelper {
    /// returns: `true` if a variation could be popped, `false` otherwise
    @discardableResult
    internal func popVariation() -> Bool {
        guard let (ply, _) = self.indices.popLast() else { return false }
        
        self.ply = ply
        return true
    }
}

extension GameHelper {
    /// returns: `true` if success, `false` otherwise
    @discardableResult
    public func forward() -> Bool {
        guard self.ply < self.variation.endPly else { return false }
        
        self.ply = self.ply.successor
        return true
    }
    
    /// returns: `true` if success, `false` otherwise
    @discardableResult
    public func backward() -> Bool {
        if self.ply > self.variation.startPly {
            self.ply = self.ply.predecessor
            return true
        } else if !self.indices.isEmpty {
            self.indices.removeLast()
            self.ply = self.ply.predecessor
            return true
        } else {
            return false
        }
    }
}

extension GameHelper {
    /// returns: `true` if a move was played, `false` otherwise
    @discardableResult
    public func toggle(_ square: Square) -> Bool {
        guard let move = self.movePicker.toggle(square) else { return false }
        
        self.play(move)
        return true
    }
    
    /// returns: `true` if a move was played, `false` otherwise
    @discardableResult
    public func toggle<S: Sequence>(_ squares: S) -> Bool where S.Iterator.Element == Square {
        return squares.contains(where: self.toggle)
    }
    
    /// returns: `true` is a move was played, `false` otherwise
    @discardableResult
    public func move(from start: Square, to end: Square) -> Bool {
        guard let move = self.movePicker.onlyCandidate(from: start, to: end) else { return false }
        
        self.play(move)
        return true
    }
}

extension GameHelper: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        print("game:\n\(self.game.pdn)", to: &target)
        self.movePicker.write(to: &target)
    }
}
