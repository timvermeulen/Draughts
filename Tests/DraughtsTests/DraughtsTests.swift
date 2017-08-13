import XCTest
import Parser
@testable import Draughts

final class DraughtsTests: TestCase {
    func testOpeningMoves() throws {
        let position = Position.start
        
        let moves = Set(position.legalMoves.lazy.map { $0.notation })
        let expected: Set = ["31-26", "31-27", "32-27", "32-28", "33-28", "33-29", "34-29", "34-30", "35-30"]
        
        XCTAssertEqual(moves, expected)
    }
    
    func testReturnMoves() throws {
        let pos1 = Position.start
        let openingMoves = pos1.legalMoves
        let move = openingMoves.first.unwrap()
        
        let pos2 = move.endPosition
        let returnMoves = Set(pos2.legalMoves.lazy.map { $0.notation })
        let expected: Set = ["16-21", "17-21", "17-22", "18-22", "18-23", "19-23", "19-24", "20-24", "20-25"]
        
        XCTAssertEqual(returnMoves, expected)
    }
    
    func testKingSlidingMoves() throws {
        let position = assertPositionExists(fen: "W:WK33:B")
        
        let moves = Set(position.legalMoves.lazy.map { $0.notation })
        let expected: Set = ["33-28", "33-22", "33-17", "33-11", "33-6", "33-29", "33-24", "33-20", "33-15", "33-38", "33-42", "33-47", "33-39", "33-44", "33-50"]
        
        XCTAssertEqual(moves, expected)
    }

    func testCapture() throws {
        let pos1 = Position.start
        
        let openingMoves = pos1.legalMoves
        let firstMove = openingMoves.first(where: { $0.notation == "32-28" }).unwrap()
        let pos2 = firstMove.endPosition
        
        let returnMoves = pos2.legalMoves
        let secondMove = returnMoves.first(where: { $0.notation == "19-23" }).unwrap()
        let pos3 = secondMove.endPosition
        
        let returnReturnMoves = pos3.legalMoves
        let capture = returnReturnMoves.first.unwrap()
        XCTAssertEqual(returnReturnMoves.count, 1)
        XCTAssert(capture.isCapture)
        
        let pos4 = capture.endPosition
        
        XCTAssertEqual(pos4.pieces(of: .white).count, 20)
        XCTAssertEqual(pos4.pieces(of: .black).count, 19)
    }
    
    func testFEN() throws {
        do {
            let position = assertPositionExists(fen: "W:W28,K29:BK22,23")
            let expected = Position(
                pieces: [
                    Piece(player: .white, kind: .man, square: 28),
                    Piece(player: .white, kind: .king, square: 29),
                    Piece(player: .black, kind: .man, square: 23),
                    Piece(player: .black, kind: .king, square: 22)
                ]
            )
            
            XCTAssertEqual(position, expected)
            
            let copy = assertPositionExists(fen: position.fen)
            XCTAssertEqual(position, copy)
        }
        
        do {
            let fen1 = "W:W20,24,30,33,40,43,47,:B7,10,12,22,27,29,36,"
            let fen2 = "W:W20,24,30,33,40,43,47:B7,10,12,22,27,29,36"
            
            let position = assertPositionExists(fen: fen1)
            XCTAssertEqual(fen2, position.fen)
        }
    }
    
    func testCorrectedFEN() throws {
        let position = assertPositionExists(fen: "W:W6,1,K2:B45,50,K49")
        let expected = assertPositionExists(fen: "W:W6,K2:B45,K49")
        
        XCTAssertEqual(position, expected)
    }
    
    func testRepeatedMove() throws {
        let position = assertPositionExists(fen: "B:W6:B1")
        let helper = GameHelper(position: position)
        
        helper.move(from: 1, to: 7)
        helper.backward()
        helper.move(from: 1, to: 7)
        
        let expected = assertGameExists(pdn: "1-7", position: position)
        XCTAssertEqual(helper.game, expected)
    }
    
    func testCoupTurc() throws {
        let position = assertPositionExists(fen: "W:WK26:B9,12,13,23,24")
        let moves = position.legalMoves
        
        let move = moves.first.unwrap()
        XCTAssertEqual(moves.count, 1)
        
        let next = move.endPosition
        let expected = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 18),
                Piece(player: .black, kind: .man, square: 13)
            ],
            playerToMove: .black
        )
        
        XCTAssertEqual(next, expected)
    }
    
    func testMillCapture() throws {
        let position = assertPositionExists(fen: "W:WK2:B7,13,32,34")
        XCTAssert(position.legalMoves.contains(where: { $0.startSquare == 2 && $0.endSquare == 2 }))
    }
    
    func testManIntermediateSquares() throws {
        let position = assertPositionExists(fen: "W:W48:B43,33,22,21")
        
        let moves = position.legalMoves
        XCTAssertEqual(moves.count, 1)
        
        let move = moves.first.unwrap()
        let expectedMove = Move(
            from: Piece(player: .white, kind: .man, square: 48),
            to: 26,
            over: position.pieces(of: .black).serialized().map { Piece(player: .black, kind: .man, square: $0) },
            position: position
        )
        XCTAssertEqual(move, expectedMove)
        
        let intermediateSquares = move.anyIntermediateSquares
        let expectedSquares: [Square] = [39, 28, 17]
        
        XCTAssertEqual(intermediateSquares, expectedSquares)
    }
    
    func testKingIntermediateSquares() throws {
        let position = assertPositionExists(fen: "W:WK46:B19,20,30,32,43")
        let move = position.legalMoves.first.unwrap()
        XCTAssert(position.legalMoves.count == 1)
        
        let intermediateSquares = move.allIntermediateSquares
        let expectedIntermediateSquares: [[Square]] = [[28, 23], [14], [25], [34, 39]]
        XCTAssert(intermediateSquares == expectedIntermediateSquares)
    }
    
    func testSlidingPromotion() throws {
        let pos1 = assertPositionExists(fen: "W:W6:B45")
        
        let move1 = pos1.legalMoves.first.unwrap()
        XCTAssertEqual(pos1.legalMoves.count, 1)
        
        let pos2 = move1.endPosition
        let expected1 = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 1),
                Piece(player: .black, kind: .man, square: 45)
            ],
            playerToMove: .black
        )
        XCTAssertEqual(pos2, expected1)
        
        let move2 = pos2.legalMoves.first.unwrap()
        XCTAssertEqual(pos2.legalMoves.count, 1)
        
        let pos3 = move2.endPosition
        let expected2 = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 1),
                Piece(player: .black, kind: .king, square: 50)
            ],
            playerToMove: .white
        )
        XCTAssertEqual(pos3, expected2)
    }
    
    func testCapturingPromotion() throws {
        let position = assertPositionExists(fen: "W:W15:B10")
        
        let move = position.legalMoves.first.unwrap()
        XCTAssertEqual(position.legalMoves.count, 1)
        let expectedMove = Move(
            from: Piece(player: .white, kind: .man, square: 15),
            to: 4,
            over: [
                Piece(player: .black, kind: .man, square: 10)
            ],
            position: position
        )
        XCTAssertEqual(move, expectedMove)
        
        let result = move.endPosition
        let expectedResult = Position(
            pieces: [
                Piece(player: .white, kind: .king, square: 4)
            ],
            playerToMove: .black
        )
        XCTAssertEqual(result, expectedResult)
    }
    
    func testMovePicker() throws {
        do {
            let position = Position.start
            let picker = MovePicker(position)
            XCTAssertNil(picker.onlyCandidate)
            picker.toggle(26)
            XCTAssertNotNil(picker.onlyCandidate)
        }
        
        do {
            let position = assertPositionExists(fen: "W:WK46:B41,42,38,30")
            let picker = MovePicker(position)
            XCTAssertNil(picker.onlyCandidate)
            
            picker.toggle(46)
            XCTAssertNil(picker.onlyCandidate)
            XCTAssertEqual(picker.candidates.count, 2)
            
            picker.toggle(37)
            XCTAssertNotNil(picker.onlyCandidate)
        }
        
        do {
            let position = assertPositionExists(fen: "W:WK26:B7,9,12,13,29,32,34,37,40")
            XCTAssertEqual(position.legalMoves.count, 10)
            
            let picker = MovePicker(position)
            XCTAssertNil(picker.onlyCandidate)
            
            picker.toggle(40)
            XCTAssertEqual(picker.candidates.count, 4)
            
            picker.toggle(34)
            XCTAssertEqual(picker.candidates.count, 2)
            
            picker.toggle(16)
            XCTAssertNotNil(picker.onlyCandidate)
        }
    }
    
    func testMovePickerIrrelevantToggle() throws {
        let position = assertPositionExists(fen: "W:W28:B13,14,23")
        let picker = MovePicker(position)
        
        picker.toggle(28)
        XCTAssertNil(picker.onlyCandidate)
        XCTAssertNotEqual(picker.requirements, .empty)
        
        picker.toggle(50)
        XCTAssertNotEqual(picker.requirements, .empty)
    }
    
    func testMovePickerFromTo() throws {
        let position = assertPositionExists(fen: "W:W32:B7,8,9,10,18,19,28")

        let picker = MovePicker(position)
        XCTAssertNil(picker.onlyCandidate)
        
        picker.toggle(32)
        picker.toggle(23)
        XCTAssertNotEqual(picker.requirements, .empty)
        XCTAssertNil(picker.onlyCandidate)
        
        XCTAssertNotNil(picker.onlyCandidate(from: 32, to: 23))
    }
    
    func testMovePickerOverride() throws {
        let position = assertPositionExists(fen: "W:W35,36:B20,21,22,30,31")
        let picker = MovePicker(position)
        
        picker.toggle(27)
        XCTAssertNil(picker.onlyCandidate)
        XCTAssertNotNil(picker.onlyCandidate(from: 35, to: 15))
        
        picker.toggle(35)
        XCTAssertNotNil(picker.onlyCandidate)
    }
    
    func testMovePickerDifficult() throws {
        let position = assertPositionExists(fen: "W:WK46:B9,12,13,22,23,32")
        let helper = GameHelper(position: position)
        
        XCTAssertFalse(helper.move(from: 46, to: 28))
        XCTAssertFalse(helper.toggle(9))
        XCTAssert(helper.move(from: 46, to: 28))
    }
    
    func testUnambiguousNotation() throws {
        do {
            let position = assertPositionExists(fen: "W:WK47:B42,43,39,40")
            let moves = position.legalMoves.map { $0.unambiguousNotation }
            
            XCTAssertEqual(moves.count, 2)
            XCTAssert(moves.contains("47x35 (over 43)"))
            XCTAssert(moves.contains("47x35 (over 39)"))
        }
        
        do {
            let position = assertPositionExists(fen: "W:WK21:B9,12,13,29,31,34")
            let moves = position.legalMoves.map { $0.unambiguousNotation }
            
            XCTAssertEqual(moves.count, 4)
            XCTAssert(moves.contains("21x26 (over 13 and 34)"))
        }
    }
    
    func testMoveFromOne() throws {
        let position = assertPositionExists(fen: "W:WK1:B")
        XCTAssertNotEqual(position.legalMoves.count, 0)
    }
    
    func testGameHelper() throws {
        do {
            let position = assertPositionExists(fen: "B:W48,49:B2,3")
            let helper = GameHelper(position: position)
            XCTAssert(helper.game.moves.isEmpty)
            
            helper.toggle(9)
            XCTAssertEqual(helper.game.moves.count, 1)
            
            helper.move(from: 48, to: 43)
            XCTAssertEqual(helper.game.moves.count, 2)
        }
        
        do {
            let helper = GameHelper(position: .start)
            XCTAssert(helper.game.moves.isEmpty)
            
            XCTAssertFalse(helper.toggle(30))
            XCTAssert(helper.toggle(35))
            
            XCTAssert(helper.move(from: 17, to: 21))
        }
        
        do {
            let helper = GameHelper(position: .start)
            
            XCTAssert(helper.move(from: 32, to: 28))
            XCTAssertFalse(helper.forward())
            XCTAssert(helper.backward())
            XCTAssertFalse(helper.backward())
            XCTAssert(helper.move(from: 32, to: 27))
            XCTAssert(helper.move(from: 19, to: 23))
            XCTAssert(helper.backward())
            XCTAssert(helper.move(from: 18, to: 23))
            XCTAssertFalse(helper.forward())
            
            XCTAssertEqual(helper.game.pdn, "1. 32-28 (1. 32-27 19-23 (1. ... 18-23))")
        }
    }
    
    func testGameHelperPosition() throws {
        let position = assertPositionExists(fen: "W:W47:B5")
        let helper = GameHelper(position: position)
        
        XCTAssert(helper.toggle(41))
        XCTAssert(helper.toggle(10))
        
        XCTAssertEqual(helper.position, assertPositionExists(fen: "W:W41:B10"))
        
        XCTAssert(helper.backward())
        XCTAssertEqual(helper.position, assertPositionExists(fen: "B:W41:B5"))
        
        XCTAssert(helper.backward())
        XCTAssertEqual(helper.position, position)
        
        XCTAssert(helper.toggle(42))
        XCTAssertEqual(helper.position, assertPositionExists(fen: "B:W42:B5"))
    }
    
    func testPDN() throws {
        do {
            let gameHelper = GameHelper(position: assertPositionExists(fen: "B:W37:B14"))
            
            XCTAssert(gameHelper.move(from: 14, to: 19))
            XCTAssert(gameHelper.move(from: 37, to: 31))
            
            XCTAssertEqual(gameHelper.game.pdn, "1. ... 14-19 2. 37-31")
        }
        
        do {
            let game = assertGameExists(pdn: "1. 32-28 19-23 2. 28x19 14x23")
            
            XCTAssertEqual(game.moves.count, 4)
            XCTAssertEqual(game.endPosition.pieces(of: .white).count, 19)
            XCTAssertEqual(game.endPosition.pieces(of: .black).count, 19)
        }
        
        do {
            let raphael = assertPositionExists(fen: "W:W27,28,32,37,38,33,34,48,49:B24,23,19,13,12,17,21,16,26")
            let result = assertPositionExists(fen: "B:W17:B7")
            
            let notation = "1. 34-29 23x34 2. 28-23 19x39 3. 37-31 26x28 4. 49-44 21x43 5. 44x11 16x7 6. 48x17"
            let game = assertGameExists(pdn: notation, position: raphael)
            
            XCTAssertEqual(game.endPosition, result)
        }
        
        assertGameExists(pdn: "1. 32-28 (1. 32-27 19-23 (1. ... 18-23); 1. 31-26 16-21 2. 36-31)")
        assertGameExists(
            pdn: "1. 44-40 26-31 2. 40-35 27-32 3. 05x26 36-41 4. 26-42 (4. 26-12 41-47 5. 12-29) 41-47 5. 42-29 47-41 6. 29-23 41x30 7. 35x24",
            fen: "W:W24,44,K5:B26,27,36,"
        )
        assertGameExists(
            pdn: "1. 20-15 29x49 2. 15x04 49x35 3. 47-41 36x47 4. 04-15 47x20 5. 15x38x16x02 35x24 6. 02x30 22-28 7. 30-25 28-32 8. 25-03 12-18 9. 03-09 18-23 10. 09-20",
            fen: "W:W20,24,30,33,40,43,47,:B7,10,12,22,27,29,36,"
        )
        assertGameExists(
            pdn: "1. 32-27 17-22 (1... 17-21 2. 40-35 21x32 3. 37x28 26x30 4. 35x02 (4. 35x04)) 2. 37-32 26x30 3. 40-35 22x31 4. 35x04",
            fen: "W:W29,31,32,34,36,37,40,41,42,43:B3,8,9,12,16,17,18,19,20,26"
        )
    }
    
    func testGameDelete() throws {
        do {
            var game = assertGameExists(pdn: "1. 32-28 (1. 32-27 16-21) 19-23")
            game.remove(from: game.startPly.successor)
            
            let expected = assertGameExists(pdn: "1. 32-27 16-21")
            XCTAssertEqual(game, expected)
        }
        
        do {
            var game = assertGameExists(pdn: "1. 32-28 (1. 32-27 16-21) 19-24 2. 37-32 14-19 (2. ... 13-19)")
            game.remove(from: Ply(player: .white, number: 4))
            
            let expected = assertGameExists(pdn: "1. 32-28 (1. 32-27 16-21) 19-24 2. 37-32 13-19")
            XCTAssertEqual(game, expected)
        }
    }
    
    func testGameHelperDelete() throws {
        do {
            let game = assertGameExists(pdn: "1. 32-28 (1. 32-27 16-21) 19-24 2. 37-32 14-19 (2. ... 24-30 35x24)")
            let helper = GameHelper(game: game)
            
            helper.remove(from: helper.index)
            XCTAssert(helper.forward())
            XCTAssert(helper.forward())
            XCTAssert(helper.move(from: 20, to: 29))
            
            let expected = assertGameExists(pdn: "1. 32-28 (1. 32-27 16-21) 19-24 2. 37-32 24-30 3. 35x24 20x29")
            XCTAssertEqual(helper.game, expected)
        }
        
        do {
            let helper = GameHelper(position: .start)
            
            XCTAssert(helper.move(from: 32, to: 28))
            XCTAssert(helper.backward())
            XCTAssert(helper.move(from: 33, to: 28))
            helper.remove(from: helper.index)
            
            let expected = assertGameExists(pdn: "1. 32-28")
            XCTAssertEqual(helper.game, expected)
        }
    }
    
    func testLockedGame() throws {
        let helper = GameHelper(position: .start)
        
        XCTAssert(helper.move(from: 32, to: 28))
        XCTAssert(helper.move(from: 18, to: 23))
        
        helper.lock()
        
        XCTAssert(helper.move(from: 38, to: 32))
        XCTAssertEqual(helper.game.pdn, "1. 32-28 18-23 (2. 38-32)")
        
        XCTAssert(helper.backward())
        XCTAssert(helper.backward())
        
        XCTAssert(helper.move(from: 17, to: 21))
        XCTAssertEqual(helper.game.pdn, "1. 32-28 18-23 (1. ... 17-21) (2. 38-32)")
        
        XCTAssert(helper.backward())
        XCTAssert(helper.forward())
        XCTAssertFalse(helper.forward())
        
        XCTAssert(helper.move(from: 38, to: 32))
        helper.remove(from: helper.index)
        XCTAssertEqual(helper.game.pdn, "1. 32-28 18-23 (1. ... 17-21)")
    }
    
    func testVariationPromotion() throws {
        let helper = GameHelper(position: .start)
        
        XCTAssert(helper.move(from: 33, to: 28))
        XCTAssert(helper.backward())
        XCTAssert(helper.move(from: 32, to: 28))
        XCTAssert(helper.move(from: 18, to: 23))
        
        helper.promote(at: helper.index)
        XCTAssertEqual(helper.game.pdn, "1. 32-28 (1. 33-28) 18-23")
    }
    
    func testDarkPosition() throws {
        let fens: [(fen: String, expected: String)] = [
            ("W:W28:B23,19,13,9", "W:W28:B23,19"),
            ("W:W28,24:B23,19,13,9", "W:W28,24:B23,19,13")
        ]
        
        for (fen, expected) in fens {
            let position = assertPositionExists(fen: fen)
            let expectedDark = assertPositionExists(fen: expected)
            XCTAssertEqual(position.darkPosition, expectedDark)
        }
    }
    
    func testDarkPositions() throws {
        let position = assertPositionExists(fen: "B:W24,32,33:B2,10,13,14,23")
        let game = assertGameExists(pdn: "2-8 33-28 14-19", position: position)
        
        let expected: [(white: String, black: String)] = [
            ("B:W24,32,33:B", "B:W:B2,10,13,14,23"),
            ("W:W24,32,33:B", "W:W:B8,10,13,14,23"),
            ("B:W24,28,32:B", "B:W28,32:B8,10,13,14,23"),
            ("W:W24,28,32:B13,19,23", "W:W28,32:B8,10,13,19,23")
        ]
        
        let darkPositions = game.positions.indices.lazy.map { game.darkPositions(at: Game.PositionIndex(ply: $0)) }
        
        for (expected, real) in zip(expected, darkPositions) {
            let white = assertPositionExists(fen: expected.white)
            let black = assertPositionExists(fen: expected.black)
            
            XCTAssertEqual(white, real.white)
            XCTAssertEqual(black, real.black)
        }
    }
    
    func testGameToPosition() throws {
        let helper = GameHelper(position: .start)
        
        helper.move(from: 32, to: 28)
        helper.move(from: 19, to: 23)
        helper.backward()
        helper.move(from: 18, to: 23)
        helper.move(from: 37, to: 32)
        helper.backward()
        helper.move(from: 38, to: 32)
        
        let game = helper.game.gameToPosition(at: helper.index)
        let expected = assertGameExists(pdn: "32-28 18-23 38-32")
        XCTAssertEqual(game, expected)
    }
    
    func testTrace() throws {
        let game = assertGameExists(pdn: "32-28 19-23 28x19 14x23")
        let expected = Trace(
            moved: [
                Piece(player: .black, kind: .man, square: 14): Piece(player: .black, kind: .man, square: 23)
            ],
            removed: [
                Piece(player: .white, kind: .man, square: 32),
                Piece(player: .black, kind: .man, square: 19)
            ],
            added: []
        )
        
        XCTAssertEqual(game.trace, expected)
    }
    
    func testTraceNonLinear() throws {
        let helper = GameHelper(position: .start)
        
        helper.move(from: 32, to: 28)
        helper.move(from: 19, to: 24)
        
        let index1 = helper.index
        
        helper.backward()
        helper.move(from: 19, to: 23)
        
        let index2 = helper.index
        
        let trace = helper.game.trace(from: index1, to: index2)
        let expected = Trace(
            moved: [
                Piece(player: .black, kind: .man, square: 24): Piece(player: .black, kind: .man, square: 23)
            ],
            removed: [],
            added: []
        )
        
        XCTAssertEqual(trace, expected)
    }
    
    func testTraceRemoveAdd() throws {
        let helper = GameHelper(position: .start)
        
        helper.move(from: 32, to: 28)
        helper.move(from: 19, to: 23)
        helper.move(from: 28, to: 19)
        
        let index = helper.index
        
        helper.backward()
        helper.backward()
        helper.move(from: 17, to: 21)
        helper.move(from: 28, to: 22)
        helper.move(from: 18, to: 27)
        
        let trace = helper.move(to: index)
        let expected = Trace(
            moved: [
                Piece(player: .black, kind: .man, square: 21): Piece(player: .black, kind: .man, square: 17),
                Piece(player: .black, kind: .man, square: 27): Piece(player: .black, kind: .man, square: 18)
            ],
            removed: [
                Piece(player: .black, kind: .man, square: 19)
            ],
            added: [
                Piece(player: .white, kind: .man, square: 19)
            ]
        )
        
        XCTAssertEqual(trace, expected)
    }
    
    func testTracePromote() throws {
        let position = assertPositionExists(fen: "W:W10:B41")
        let helper = GameHelper(position: position)
        
        let index1 = helper.index
        
        helper.toggle(5)
        helper.toggle(46)
        
        let index2 = helper.index
        let trace1 = helper.move(to: index1)
        
        let dest1 = trace1.destination(of: Piece(player: .white, kind: .king, square: 5)).unwrap()
        XCTAssertEqual(dest1, Piece(player: .white, kind: .man, square: 10))
        
        let dest2 = trace1.destination(of: Piece(player: .black, kind: .king, square: 46)).unwrap()
        XCTAssertEqual(dest2, Piece(player: .black, kind: .man, square: 41))
        
        let trace2 = helper.move(to: index2)
        
        let dest3 = trace2.destination(of: Piece(player: .white, kind: .man, square: 10)).unwrap()
        XCTAssertEqual(dest3, Piece(player: .white, kind: .king, square: 5))
        
        let dest4 = trace2.destination(of: Piece(player: .black, kind: .man, square: 41)).unwrap()
        XCTAssertEqual(dest4, Piece(player: .black, kind: .king, square: 46))
    }
    
//    func testData() throws {
//        let pdn = """
//        1. 32-28 17-22 2. 28x17 11x22 3. 37-32 6-11 4. 41-37 12-17 5. 34-30 19-23
//        6. 46-41 7-12 7. 32-28 23x32 8. 37x28 22-27 9. 31x22 18x27 10. 30-24 20x29
//        11. 33x24 17-21 12. 38-32 27x38 13. 42x33 21-27 14. 43-38 16-21 15. 41-37 11-16
//        16. 37-32 1-6 17. 40-34 14-20 18. 45-40 20x29 19. 33x24 10-14 20. 39-33 5-10
//        21. 44-39 14-20 22. 50-45 20x29 23. 33x24 10-14 24. 39-33 12-18 25. 34-29 14-20
//        26. 48-42 20-25 27. 42-37 21-26 28. 32x21 26x17 29. 37-32 17-21 30. 40-34 6-11
//        31. 47-42 11-17 32. 42-37 18-22 33. 45-40 8-12 34. 49-43 3-8 35. 29-23 13-18
//        36. 34-29 21-27 37. 32x21 16x27
//        """
//        let game = Game(pdn: pdn).unwrap()
//        print(game)
//        print(Array(game.data))
//    }
}
