public final class GameHelper {
    public typealias Index = Game.PositionIndex
    
    public fileprivate(set) var game: Game
    public fileprivate(set) var index: Index
    fileprivate var movePicker: MovePicker
    
    public init(game: Game) {
        self.game = game
        index = Game.PositionIndex(variationIndex: Game.VariationIndex(), ply: game.endPly)
        movePicker = MovePicker(game.endPosition)
    }
    
    public init(_ helper: GameHelper) {
        game = helper.game
        index = helper.index
        movePicker = MovePicker(game[index])
    }
    
    public convenience init(position: Position) {
        self.init(game: Game(position: position))
    }
}

extension GameHelper {
    fileprivate var variation: Game {
        get { return game[index.variationIndex] }
        set { game[index.variationIndex] = newValue }
    }
    
    public var position: Position {
        return variation.positions[index.ply]
    }
    
    fileprivate func reloadMovePicker() {
        movePicker = MovePicker(game[index])
    }
    
    /// returns: `true` if a variation could be popped, `false` otherwise
    @discardableResult
    public func play(_ move: Move) -> Bool {
        guard position.moveIsValid(move) else { return false }
        
        if variation.play(move, at: index.ply).inVariation {
            index.variationIndex.deviations.append(Game.Deviation(ply: index.ply, move: move))
        }
        
        guard forward() else { fatalError("this shouldn't happen") }
        return true
    }
}

extension GameHelper {
    /// returns: `true` if a variation could be popped, `false` otherwise
    @discardableResult
    internal func popVariation() -> Bool {
        guard let (parent, deviation) = index.variationIndex.parent else { return false }
        
        index.variationIndex = parent
        index.ply = deviation.ply
        reloadMovePicker()
        
        return true
    }
}

extension GameHelper {
    /// returns: `true` if success, `false` otherwise
    @discardableResult
    public func forward() -> Bool {
        guard index.ply < variation.endPly else { return false }
        
        index.ply.formSuccessor()
        reloadMovePicker()
        
        return true
    }
    
    /// returns: `true` if success, `false` otherwise
    @discardableResult
    public func backward() -> Bool {
        guard let parentIndex = game.parentIndex(of: index) else { return false }
        
        index = parentIndex
        reloadMovePicker()
        
        return true
    }
    
    @discardableResult
    public func move(to index: Index) -> Trace<Piece> {
        defer {
            self.index = index
            reloadMovePicker()
        }
        
        return game.trace(from: self.index, to: index)
    }
    
    public func canRemove(from index: Index) -> Bool {
        return game.canRemove(from: index)
    }
    
    /// returns: `true` if removal was allowed, `false` otherwise
    @discardableResult
    public func remove(from index: Index) -> Bool {
        guard canRemove(from: index) else { return false }
        
        let parentIndex = game.parentIndex(of: index)
        game.remove(from: index)
        
        if index.isChild(of: self.index) {
            self.index = parentIndex ?? game.startIndex
        }
        
        reloadMovePicker()
        return true
    }
    
    public func canPromote(at index: Index) -> Bool {
        return game.canPromote(at: index.variationIndex)
    }
    
    /// returns: `true` if promotion was allowed, `false` otherwise
    @discardableResult
    public func promote(at index: Index) -> Bool {
        return game.promote(at: index.variationIndex)
    }
}

extension GameHelper {
    /// returns: `true` if a move was played, `false` otherwise
    @discardableResult
    public func toggle(_ square: Square) -> Bool {
        guard let move = movePicker.toggle(square) else { return false }
        
        play(move)
        return true
    }
    
    /// Stops processing the given squares when a move is played.
    /// returns: `true` if a move was played, `false` otherwise
    @discardableResult
    public func toggle<S: Sequence>(_ squares: S) -> Bool where S.Iterator.Element == Square {
        return squares.contains(where: toggle)
    }
    
    /// returns: `true` is a move was played, `false` otherwise
    @discardableResult
    public func move(from start: Square, to end: Square) -> Bool {
        guard let move = movePicker.onlyCandidate(from: start, to: end) else { return false }
        
        play(move)
        return true
    }
}

extension GameHelper {
    public func lock() {
        game.isLocked = true
    }
    
    public func unlock() {
        game.isLocked = false
    }
}

extension GameHelper: TextOutputStreamable {
    public func write<Target: TextOutputStream>(to target: inout Target) {
        print("game:\n\(game.pdn)", to: &target)
        movePicker.write(to: &target)
    }
}
