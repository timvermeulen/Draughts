import XCTest
@testable import Draughts

let errorMessage = "`continueAfterFailure` should be set to `false` inside `setUp()`, and set to `true` inside `tearDown()`"

func XCTFatal(_ message: String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    XCTFail(message, file: file, line: line)
    fatalError(errorMessage)
}

func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> T {
    XCTAssertNotNil(try expression(), message(), file: file, line: line)
    guard let result = (try? expression()) ?? nil else { fatalError(errorMessage) }
    return result
}

class DraughtsTests: XCTestCase {
    override func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    override func tearDown() {
        self.continueAfterFailure = true
        super.tearDown()
    }
    
    func testOpeningMoves() {
        let position = Position.beginPosition
        
        let moves = Set(position.generateMoves().map { $0.notation })
        let expected: Set = ["31-26", "31-27", "32-27", "32-28", "33-28", "33-29", "34-29", "34-30", "35-30"]
        
        XCTAssertEqual(moves, expected)
    }
    
    func testReturnMoves() {
        let pos1 = Position.beginPosition
        let openingMoves = pos1.generateMoves()
        let move = XCTUnwrap(openingMoves.first)
        
        let pos2 = pos1.playing(move)
        let returnMoves = Set(pos2.generateMoves().map { $0.notation })
        let expected: Set = ["16-21", "17-21", "17-22", "18-22", "18-23", "19-23", "19-24", "20-24", "20-25"]
        
        XCTAssertEqual(returnMoves, expected)
    }
    
    func testKingSlidingMoves() {
        let fen = "W:WK33:B"
        let position = XCTUnwrap(Position(fen: fen))
        
        let moves = Set(position.generateMoves().map { $0.notation })
        let expected: Set = ["33-28", "33-22", "33-17", "33-11", "33-6", "33-29", "33-24", "33-20", "33-15", "33-38", "33-42", "33-47", "33-39", "33-44", "33-50"]
        
        XCTAssertEqual(moves, expected)
    }

    func testCapture() {
        let pos1 = Position.beginPosition
        
        let openingMoves = pos1.generateMoves()
        let firstMove = XCTUnwrap(
            openingMoves.first(where: { $0.notation == "32-28" })
        )
        let pos2 = pos1.playing(firstMove)
        
        let returnMoves = pos2.generateMoves()
        let secondMove = XCTUnwrap(
            returnMoves.first(where: { $0.notation == "19-23" })
        )
        let pos3 = pos2.playing(secondMove)
        
        let returnReturnMoves = pos3.generateMoves()
        let capture = XCTUnwrap(returnReturnMoves.first)
        XCTAssertEqual(returnReturnMoves.count, 1)
        XCTAssertTrue(capture.isCapture)
        
        let pos4 = pos3.playing(capture)
        
        XCTAssertEqual(pos4.pieces(of: .white).count, 20)
        XCTAssertEqual(pos4.pieces(of: .black).count, 19)
    }
    
    func testFEN() {
        let fen = "W:W28,K29:BK22,23"
        
        let position = XCTUnwrap(Position(fen: fen))
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
        let fen = "W:WK26:B9,12,13,23,24"
        let position = XCTUnwrap(Position(fen: fen))
        let moves = position.generateMoves()
        
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
        let fen = "W:W48:B43,33,22,21"
        let position = XCTUnwrap(Position(fen: fen))
        
        let moves = position.generateMoves()
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
