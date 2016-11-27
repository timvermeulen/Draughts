public final class GameHelper {
    public var game: Game
    fileprivate var movePicker: MovePicker
    
    public init(_ game: Game) {
        self.game = game
        self.movePicker = MovePicker(game.endPosition)
    }
    
    private func reloadMovePicker() {
        self.movePicker = MovePicker(game.endPosition)
    }
    
    private func play(_ move: Move) {
        self.game.play(move)
        self.reloadMovePicker()
    }
    
    /// returns: a Bool indicating whether a move was picked or not
    @discardableResult
    public func toggle(_ square: Square) -> Bool {
        self.movePicker.toggle(square)
        
        if let move = self.movePicker.onlyCandidate {
            self.play(move)
            return true
        } else {
            return false
        }
    }
    
    /// returns: a Bool indicating whether a move was picked or not
    @discardableResult
    public func toggle<S: Sequence>(_ squares: S) -> Bool where S.Iterator.Element == Square {
        return squares.contains(where: self.toggle)
    }
    
    /// returns: a Bool indicating whether a move was picked or not
    @discardableResult
    public func move(from start: Square, to end: Square) -> Bool {
        if let move = movePicker.onlyCandidate(from: start, to: end) {
            self.play(move)
            return true
        } else {
            return false
        }
    }
}
