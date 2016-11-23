import XCTest
import SafeXCTestCase
@testable import Draughts

class DraughtsTests: SafeXCTestCase {
    func testOpeningMoves() {
        let position = Position.beginPosition
        
        let moves = Set(position.legalMoves.map { $0.notation })
        let expected: Set = ["31-26", "31-27", "32-27", "32-28", "33-28", "33-29", "34-29", "34-30", "35-30"]
        
        XCTAssertEqual(moves, expected)
    }
    
    func testReturnMoves() {
        let pos1 = Position.beginPosition
        let openingMoves = pos1.legalMoves
        let move = XCTUnwrap(openingMoves.first)
        
        let pos2 = pos1.playing(move)
        let returnMoves = Set(pos2.legalMoves.map { $0.notation })
        let expected: Set = ["16-21", "17-21", "17-22", "18-22", "18-23", "19-23", "19-24", "20-24", "20-25"]
        
        XCTAssertEqual(returnMoves, expected)
    }
    
    func testKingSlidingMoves() {
        let position = XCTUnwrap(Position(fen: "W:WK33:B"))
        
        let moves = Set(position.legalMoves.map { $0.notation })
        let expected: Set = ["33-28", "33-22", "33-17", "33-11", "33-6", "33-29", "33-24", "33-20", "33-15", "33-38", "33-42", "33-47", "33-39", "33-44", "33-50"]
        
        XCTAssertEqual(moves, expected)
    }

    func testCapture() {
        let pos1 = Position.beginPosition
        
        let openingMoves = pos1.legalMoves
        let firstMove = XCTUnwrap(
            openingMoves.first(where: { $0.notation == "32-28" })
        )
        let pos2 = pos1.playing(firstMove)
        
        let returnMoves = pos2.legalMoves
        let secondMove = XCTUnwrap(
            returnMoves.first(where: { $0.notation == "19-23" })
        )
        let pos3 = pos2.playing(secondMove)
        
        let returnReturnMoves = pos3.legalMoves
        let capture = XCTUnwrap(returnReturnMoves.first)
        XCTAssertEqual(returnReturnMoves.count, 1)
        XCTAssertTrue(capture.isCapture)
        
        let pos4 = pos3.playing(capture)
        
        XCTAssertEqual(pos4.pieces(of: .white).count, 20)
        XCTAssertEqual(pos4.pieces(of: .black).count, 19)
    }
    
    func testFEN() {
        let position = XCTUnwrap(Position(fen: "W:W28,K29:BK22,23"))
        let expected = Position(
            pieces: [
                Piece(player: .white, kind: .man, square: 28),
                Piece(player: .white, kind: .king, square: 29),
                Piece(player: .black, kind: .man, square: 23),
                Piece(player: .black, kind: .king, square: 22)
            ]
        )
        
        XCTAssertEqual(position, expected)
        
        let copy = XCTUnwrap(Position(fen: position.fen))
        XCTAssertEqual(position, copy)
    }
    
    func testCoupTurc() {
        let position = XCTUnwrap(Position(fen: "W:WK26:B9,12,13,23,24"))
        let moves = position.legalMoves
        
        let move = XCTUnwrap(moves.first)
        XCTAssertEqual(moves.count, 1)
        
        let next = position.playing(move)
        let expected = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 18),
                Piece(player: .black, kind: .man, square: 13)
            ],
            ply: Ply(player: .black)
        )
        
        XCTAssertEqual(next, expected)
    }
    
    func testManIntermediateSquares() {
        let position = XCTUnwrap(Position(fen: "W:W48:B43,33,22,21"))
        
        let moves = position.legalMoves
        XCTAssertEqual(moves.count, 1)
        
        let move = XCTUnwrap(moves.first)
        let expectedMove = Move(
            from: Piece(player: .white, kind: .man, square: 48),
            to: 26,
            over: position.pieces(of: .black).squares.map { Piece(player: .black, kind: .man, square: $0) }
        )
        XCTAssertEqual(move, expectedMove)
        
        let intermediateSquares = move.intermediateSquares
        let expectedSquares: [Square] = [39, 28, 17]
        
        XCTAssertEqual(intermediateSquares, expectedSquares)
    }
    
    func testSlidingPromotion() {
        let pos1 = XCTUnwrap(Position(fen: "W:W6:B45"))
        
        let move1 = XCTUnwrap(pos1.legalMoves.first)
        XCTAssertEqual(pos1.legalMoves.count, 1)
        
        let pos2 = pos1.playing(move1)
        let expected1 = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 1),
                Piece(player: .black, kind: .man, square: 45)
            ],
            ply: Ply(player: .black)
        )
        XCTAssertEqual(pos2, expected1)
        
        let move2 = XCTUnwrap(pos2.legalMoves.first)
        XCTAssertEqual(pos2.legalMoves.count, 1)
        
        let pos3 = pos2.playing(move2)
        let expected2 = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 1),
                Piece(player: .black, kind: .king, square: 50)
            ],
            ply: Ply(player: .white)
        )
        XCTAssertEqual(pos3, expected2)
    }
    
    func testCapturingPromotion() {
        let position = XCTUnwrap(Position(fen: "W:W15:B10"))
        
        let move = XCTUnwrap(position.legalMoves.first)
        XCTAssertEqual(position.legalMoves.count, 1)
        let expectedMove = Move(
            from: Piece(player: .white, kind: .man, square: 15),
            to: 4,
            over: [
                Piece(player: .black, kind: .man, square: 10)
            ]
        )
        XCTAssertEqual(move, expectedMove)
        
        let result = position.playing(move)
        let expectedResult = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 4)
            ],
            ply: Ply(player: .black)
        )
        XCTAssertEqual(result, expectedResult)
    }
    
//    func testChoiceNotation() {
//        let fen = "W:WK47:B42,43,39,40"
//        let position = XCTUnwrap(Position(fen: fen))
//        let moves = position.generateMoves().map { $0.notation }
//        
//        XCTAssertEqual(moves.count, 2)
//        XCTAssert(moves.contains("47x35 (over 43)"))
//        XCTAssert(moves.contains("47x35 (over 39)"))
//    }
}
