import XCTest
@testable import Draughts

class DraughtsTests: XCTestCase {
    func testOpeningMoves() {
        let position = Position.beginPosition
        
        let moves = Set(position.generateMoves().map { $0.notation })
        let expected: Set = ["31-26", "31-27", "32-27", "32-28", "33-28", "33-29", "34-29", "34-30", "35-30"]
        
        XCTAssertEqual(moves, expected)
    }

    func testCapture() {
        var position = Position.beginPosition
        
        let openingMoves = position.generateMoves()
        guard let firstMove = openingMoves.first(where: { $0.notation == "32-28" }) else { XCTFail(); return }
        position.play(firstMove)
        
        let returnMoves = position.generateMoves()
        guard let secondMove = returnMoves.first(where: { $0.notation == "19-23" }) else { XCTFail(); return }
        position.play(secondMove)
        
        let returnReturnMoves = position.generateMoves()
        XCTAssertEqual(returnReturnMoves.count, 1)
        let capture = returnReturnMoves.first!
        XCTAssertTrue(capture.isCapture)
        
        position.play(capture)
        
        XCTAssertEqual(position.pieces(of: .white).count, 20)
        XCTAssertEqual(position.pieces(of: .black).count, 19)
    }
    
    func testFEN() {
        let fen = "W:W33:BK28"
        guard let position = Position(fen: fen) else { XCTFail(); return }
        XCTAssertEqual(position, Position(pieces: [Piece(player: .white, kind: .man, square: 33), Piece(player: .black, kind: .king, square: 28)]))
    }
    
    func testCoupTurc() {
        let fen = "W:WK26:B9,12,13,23,24"
        guard let position = Position(fen: fen) else { XCTFail(); return }
        let moves = position.generateMoves()
        guard let move = moves.first, moves.count == 1 else { XCTFail(); return }
        
        let next = position.playing(move: move)
        let expected = Position(
            pieces: [Piece(player: .white, kind: .king, square: 18), Piece(player: .black, kind: .man, square: 13)],
            ply: Ply(player: .black)
        )
        
        XCTAssertEqual(next, expected)
    }
}
