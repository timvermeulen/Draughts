public final class GameHelper {
    public fileprivate(set) var game: Game
    internal var ply: Ply {
        didSet { self.reloadMovePicker() }
    }
    internal var index: Game.Index
    fileprivate var movePicker: MovePicker
    
    public init(game: Game) {
        self.game = game
        self.ply = game.endPly
        self.index = Game.Index()
        self.movePicker = MovePicker(game.endPosition)
    }
    
    public convenience init(position: Position) {
        self.init(game: Game(position: position))
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
            self.index.deviations.append(Game.Deviation(ply: self.ply, move: move))
        }
        
        guard self.forward() else { fatalError("this shouldn't happen") }
        return true
    }
}

extension GameHelper {
    /// returns: `true` if a variation could be popped, `false` otherwise
    @discardableResult
    internal func popVariation() -> Bool {
        guard let (parent, deviation) = self.index.parent else { return false }
        
        self.index = parent
        self.ply = deviation.ply
        
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
        guard self.ply > self.variation.startPly else { return self.popVariation() }
        
        self.ply = self.ply.predecessor
        return true
    }
    
    private func reloadIndex() {
        let formerIndex = self.index
        self.index.deviations.removeAll(keepingCapacity: true)
        
        var game = self.game
        
        for deviation in formerIndex.deviations {
            guard let variations = game.variations[checking: deviation.ply] else {
                self.ply = game.endPly
                break
            }
            
            guard let variation = variations[deviation.move] else {
                self.ply = deviation.ply
                break
            }
            
            game = variation
            
            self.index.deviations.append(deviation)
        }
        
        if !game.positions.indices.contains(self.ply) {
            self.ply = game.endPly
        }
    }
    
    public func delete(at index: Game.Index, from ply: Ply) {
        self.game.delete(at: index, from: ply)
        self.reloadIndex()
    }
    
    public func delete() {
        let index = self.index
        let ply = self.ply
        
        self.backward()
        self.game.delete(at: index, from: ply)
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
    
    /// Stops processing the given squares when a move is played.
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

extension GameHelper {
    public func lock() {
        self.game.isLocked = true
    }
    
    public func unlock() {
        self.game.isLocked = false
    }
}

extension GameHelper: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        print("game:\n\(self.game.pdn)", to: &target)
        self.movePicker.write(to: &target)
    }
}
