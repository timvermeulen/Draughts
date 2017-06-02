import Foundation

extension Game {
    public var data: Data {
        let bytes: [UInt8] = zip(positions, moves).flatMap { $0.0.legalMoves.index(of: $0.1).map(numericCast) }
        return Data(bytes: bytes)
    }
}
