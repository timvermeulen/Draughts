public final class GameHelper {
    public fileprivate(set) var game: Game
    public fileprivate(set) var index: Game.PositionIndex
    fileprivate var movePicker: MovePicker
    
    public init(game: Game) {
        self.game = game
        self.index = Game.PositionIndex(variationIndex: Game.VariationIndex(), ply: game.endPly)
        self.movePicker = MovePicker(game.endPosition)
    }
    
    public convenience init(position: Position) {
        self.init(game: Game(position: position))
    }
}

extension GameHelper {
    fileprivate var variation: Game {
        get { return self.game[self.index.variationIndex] }
        set { self.game[self.index.variationIndex] = newValue }
    }
    
    public var position: Position {
        return self.variation.positions[self.index.ply]
    }
    
    fileprivate func reloadMovePicker() {
        self.movePicker = MovePicker(self.variation.positions[self.index.ply])
    }
    
    /// returns: `true` if a variation could be popped, `false` otherwise
    @discardableResult
    public func play(_ move: Move) -> Bool {
        guard self.position.moveIsValid(move) else { return false }
        
        if self.variation.play(move, at: self.index.ply).inVariation {
            self.index.variationIndex.deviations.append(Game.Deviation(ply: self.index.ply, move: move))
        }
        
        guard self.forward() else { fatalError("this shouldn't happen") }
        return true
    }
}

extension GameHelper {
    /// returns: `true` if a variation could be popped, `false` otherwise
    @discardableResult
    internal func popVariation() -> Bool {
        guard let (parent, deviation) = self.index.variationIndex.parent else { return false }
        
        self.index.variationIndex = parent
        self.index.ply = deviation.ply
        self.reloadMovePicker()
        
        return true
    }
}

extension GameHelper {
    /// returns: `true` if success, `false` otherwise
    @discardableResult
    public func forward() -> Bool {
        guard self.index.ply < self.variation.endPly else { return false }
        
        self.index.ply.formSuccessor()
        self.reloadMovePicker()
        
        return true
    }
    
    /// returns: `true` if success, `false` otherwise
    @discardableResult
    public func backward() -> Bool {
        guard self.index.ply > self.variation.startPly else { return self.popVariation() }
        
        self.index.ply.formPredecessor()
        self.reloadMovePicker()
        
        return true
    }
    
    private func reloadIndex() {
        let formerIndex = self.index.variationIndex
        self.index.variationIndex.deviations.removeAll(keepingCapacity: true)
        
        var game = self.game
        
        for deviation in formerIndex.deviations {
            guard let variations = game.variations[checking: deviation.ply] else {
                self.index.ply = game.endPly
                break
            }
            
            guard let variation = variations[deviation.move] else {
                self.index.ply = deviation.ply
                break
            }
            
            game = variation
            
            self.index.variationIndex.deviations.append(deviation)
        }
        
        if !game.positions.indices.contains(self.index.ply) {
            self.index.ply = game.endPly
        }
        
        self.reloadMovePicker()
    }
    
    public func delete(from index: Game.PositionIndex) {
        self.game.delete(from: index)
        self.reloadIndex()
    }
    
    public func delete() {
        let index = self.index
        
        self.backward()
        self.game.delete(from: index)
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
