public final class GameHelper {
    public fileprivate(set) var game: Game
    fileprivate var ply: Ply {
        didSet { self.reloadMovePicker() }
    }
    fileprivate var index: Game.Index
    fileprivate var movePicker: MovePicker
    
    public init(_ game: Game) {
        self.game = game
        self.ply = game.endPly
        self.index = Game.Index()
        self.movePicker = MovePicker(game.endPosition)
    }
}

extension GameHelper {
    fileprivate var variation: Game {
        get { return self.game[self.index] }
        set { self.game[self.index] = newValue }
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
        
        if self.variation.play(move, at: self.ply).inVariation {
            self.index.deviations.append((self.ply, move))
        }
        
        guard self.forward() else { fatalError("this shouldn't happen") }
        return true
    }
}

extension GameHelper {
    /// returns: `true` if a variation could be popped, `false` otherwise
    @discardableResult
    internal func popVariation() -> Bool {
        guard let (ply, _) = self.index.deviations.popLast() else { return false }
        
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
        guard self.ply > self.variation.startPly else { return false }
        
        self.ply = self.ply.predecessor
        
        if !self.index.deviations.isEmpty && self.ply == self.variation.startPly {
            self.index.deviations.removeLast()
        }
        
        return true
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
