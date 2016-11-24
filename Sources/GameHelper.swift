public final class GameHelper {
    public var game: Game
    private var movePicker: MovePicker
    
    public init(_ game: Game) {
        self.game = game
        self.movePicker = MovePicker(game.endPosition)
    }
    
    private func play(_ move: Move) {
        self.game.play(move)
        self.movePicker = MovePicker(game.endPosition)
    }
    
    public func toggle(_ square: Square) {
        self.movePicker.toggle(square)
        
        if let move = self.movePicker.onlyCandidate {
            self.play(move)
        }
    }
    
    public func move(from start: Square, to end: Square) {
        if let move = movePicker.onlyCandidate(from: start, to: end) {
            self.play(move)
        }
    }
}
