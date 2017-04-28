import Foundation

extension Game {
    public var data: Data {
        let bytes: [UInt8] = zip(self.positions, self.moves).flatMap { $0.legalMoves.index(of: $1).map(numericCast) }
        return Data(bytes: bytes)
    }
}
