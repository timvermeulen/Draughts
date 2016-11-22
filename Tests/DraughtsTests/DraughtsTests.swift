import XCTest
@testable import Draughts

let errorMessage = "`continueAfterFailure` should be set to `false` inside `setUp()`, and set to `true` inside `tearDown()`"

func XCTFatal(_ message: String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    XCTFail(message, file: file, line: line)
    fatalError(errorMessage)
}

func XCTUnwrap<T>(_ expression: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> T {
    XCTAssertNotNil(try expression(), message())
    guard let result = (try? expression()) ?? nil else { fatalError(errorMessage) }
    return result
}

class DraughtsTests: XCTestCase {
    override func setUp() {
        self.continueAfterFailure = false
    }
    
    override func tearDown() {
        self.continueAfterFailure = true
    }
    
    func testOpeningMoves() {
        let position = Position.beginPosition
        
        let moves = Set(position.generateMoves().map { $0.notation })
        let expected: Set = ["31-26", "31-27", "32-27", "32-28", "33-28", "33-29", "34-29", "34-30", "35-30"]
        
        XCTAssertEqual(moves, expected)
    }

    func testCapture() {
        var position = Position.beginPosition
        
        let openingMoves = position.generateMoves()
        let firstMove = XCTUnwrap(openingMoves.first(where: { $0.notation == "32-28" }))
        position.play(firstMove)
        
        let returnMoves = position.generateMoves()
        let secondMove = XCTUnwrap(returnMoves.first(where: { $0.notation == "19-23" }))
        position.play(secondMove)
        
        let returnReturnMoves = position.generateMoves()
        let capture = XCTUnwrap(returnReturnMoves.first)
        XCTAssertEqual(returnReturnMoves.count, 1)
        XCTAssertTrue(capture.isCapture)
        
        position.play(capture)
        
        XCTAssertEqual(position.pieces(of: .white).count, 20)
        XCTAssertEqual(position.pieces(of: .black).count, 19)
    }
    
    func testFEN() {
        let fen = "W:W33:BK28"
        
        let position = XCTUnwrap(Position(fen: fen))
        let expected = Position(
            pieces: [
                Piece(player: .white, kind: .man, square: 33),
                Piece(player: .black, kind: .king, square: 28)
            ]
        )
        
        XCTAssertEqual(position, expected)
    }
    
    func testCoupTurc() {
        let fen = "W:WK26:B9,12,13,23,24"
        let position = XCTUnwrap(Position(fen: fen))
        let moves = position.generateMoves()
        
        let move = XCTUnwrap(moves.first)
        XCTAssertEqual(moves.count, 1)
        
        let next = position.playing(move: move)
        let expected = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 18),
                Piece(player: .black, kind: .man, square: 13)
            ],
            ply: Ply(player: .black)
        )
        
        XCTAssertEqual(next, expected)
    }
}
