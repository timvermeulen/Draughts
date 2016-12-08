import XCTest
@testable import Draughts

class DraughtsTests: SafeXCTestCase {
    func testOpeningMoves() {
        let position = Position.start
        
        let moves = Set(position.legalMoves.map { $0.notation })
        let expected: Set = ["31-26", "31-27", "32-27", "32-28", "33-28", "33-29", "34-29", "34-30", "35-30"]
        
        XCTAssertEqual(moves, expected)
    }
    
    func testReturnMoves() {
        let pos1 = Position.start
        let openingMoves = pos1.legalMoves
        let move = SafeXCTAssertNotNil(openingMoves.first)
        
        let pos2 = move.endPosition
        let returnMoves = Set(pos2.legalMoves.map { $0.notation })
        let expected: Set = ["16-21", "17-21", "17-22", "18-22", "18-23", "19-23", "19-24", "20-24", "20-25"]
        
        XCTAssertEqual(returnMoves, expected)
    }
    
    func testKingSlidingMoves() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:WK33:B"))
        
        let moves = Set(position.legalMoves.map { $0.notation })
        let expected: Set = ["33-28", "33-22", "33-17", "33-11", "33-6", "33-29", "33-24", "33-20", "33-15", "33-38", "33-42", "33-47", "33-39", "33-44", "33-50"]
        
        XCTAssertEqual(moves, expected)
    }

    func testCapture() {
        let pos1 = Position.start
        
        let openingMoves = pos1.legalMoves
        let firstMove = SafeXCTAssertNotNil(
            openingMoves.first(where: { $0.notation == "32-28" })
        )
        let pos2 = firstMove.endPosition
        
        let returnMoves = pos2.legalMoves
        let secondMove = SafeXCTAssertNotNil(
            returnMoves.first(where: { $0.notation == "19-23" })
        )
        let pos3 = secondMove.endPosition
        
        let returnReturnMoves = pos3.legalMoves
        let capture = SafeXCTAssertNotNil(returnReturnMoves.first)
        XCTAssertEqual(returnReturnMoves.count, 1)
        XCTAssertTrue(capture.isCapture)
        
        let pos4 = capture.endPosition
        
        XCTAssertEqual(pos4.pieces(of: .white).count, 20)
        XCTAssertEqual(pos4.pieces(of: .black).count, 19)
    }
    
    func testFEN() {
        do {
            let position = SafeXCTAssertNotNil(Position(fen: "W:W28,K29:BK22,23"))
            let expected = Position(
                pieces: [
                    Piece(player: .white, kind: .man, square: 28),
                    Piece(player: .white, kind: .king, square: 29),
                    Piece(player: .black, kind: .man, square: 23),
                    Piece(player: .black, kind: .king, square: 22)
                ]
            )
            
            XCTAssertEqual(position, expected)
            
            let copy = SafeXCTAssertNotNil(Position(fen: position.fen))
            XCTAssertEqual(position, copy)
        }
        
        do {
            let fen1 = "W:W20,24,30,33,40,43,47,:B7,10,12,22,27,29,36,"
            let fen2 = "W:W20,24,30,33,40,43,47:B7,10,12,22,27,29,36"
            
            let position = SafeXCTAssertNotNil(Position(fen: fen1))
            XCTAssertEqual(fen2, position.fen)
        }
    }
    
    func testCorrectedFEN() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:W6,1,K2:B45,50,K49"))
        let expected = SafeXCTAssertNotNil(Position(fen: "W:W6,K1,K2:B45,K50,K49"))
        
        XCTAssertEqual(position, expected)
    }
    
    func testRepeatedMove() {
        let position = SafeXCTAssertNotNil(Position(fen: "B:W6:B1"))
        let helper = GameHelper(position: position)
        
        helper.move(from: 1, to: 7)
        helper.backward()
        helper.move(from: 1, to: 7)
        
        let expected = SafeXCTAssertNotNil(Game(pdn: "1-7", position: position))
        XCTAssertEqual(helper.game, expected)
    }
    
    func testCoupTurc() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:WK26:B9,12,13,23,24"))
        let moves = position.legalMoves
        
        let move = SafeXCTAssertNotNil(moves.first)
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
    
    func testMillCapture() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:WK2:B7,13,32,34"))
        XCTAssertTrue(position.legalMoves.contains(where: { $0.startSquare == 2 && $0.endSquare == 2 }))
    }
    
    func testManIntermediateSquares() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:W48:B43,33,22,21"))
        
        let moves = position.legalMoves
        XCTAssertEqual(moves.count, 1)
        
        let move = SafeXCTAssertNotNil(moves.first)
        let expectedMove = Move(
            from: Piece(player: .white, kind: .man, square: 48),
            to: 26,
            over: position.pieces(of: .black).map { Piece(player: .black, kind: .man, square: $0) },
            position: position
        )
        XCTAssertEqual(move, expectedMove)
        
        let intermediateSquares = move.anyIntermediateSquares
        let expectedSquares: [Square] = [39, 28, 17]
        
        XCTAssertEqual(intermediateSquares, expectedSquares)
    }
    
    func testKingIntermediateSquares() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:WK46:B19,20,30,32,43"))
        let move = SafeXCTAssertNotNil(position.legalMoves.first)
        XCTAssert(position.legalMoves.count == 1)
        
        let intermediateSquares = move.allIntermediateSquares
        let expectedIntermediateSquares: [[Square]] = [[28, 23], [14], [25], [34, 39]]
        XCTAssert(intermediateSquares == expectedIntermediateSquares)
    }
    
    func testSlidingPromotion() {
        let pos1 = SafeXCTAssertNotNil(Position(fen: "W:W6:B45"))
        
        let move1 = SafeXCTAssertNotNil(pos1.legalMoves.first)
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
        
        let move2 = SafeXCTAssertNotNil(pos2.legalMoves.first)
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
    
    func testCapturingPromotion() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:W15:B10"))
        
        let move = SafeXCTAssertNotNil(position.legalMoves.first)
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
    
    func testMovePicker() {
        do {
            let position = Position.start
            let picker = MovePicker(position)
            XCTAssertNil(picker.onlyCandidate)
            picker.toggle(26)
            XCTAssertNotNil(picker.onlyCandidate)
        }
        
        do {
            let position = SafeXCTAssertNotNil(Position(fen: "W:WK46:B41,42,38,30"))
            let picker = MovePicker(position)
            XCTAssertNil(picker.onlyCandidate)
            
            picker.toggle(46)
            XCTAssertNil(picker.onlyCandidate)
            XCTAssertEqual(picker.candidates.count, 2)
            
            picker.toggle(37)
            XCTAssertNotNil(picker.onlyCandidate)
        }
        
        do {
            let position = SafeXCTAssertNotNil(Position(fen: "W:WK26:B7,9,12,13,29,32,34,37,40"))
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
    
    func testMovePickerIrrelevantToggle() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:W28:B13,14,23"))
        let picker = MovePicker(position)
        
        picker.toggle(28)
        XCTAssertNil(picker.onlyCandidate)
        XCTAssertNotEqual(picker.requirements, .empty)
        
        picker.toggle(50)
        XCTAssertNotEqual(picker.requirements, .empty)
    }
    
    func testMovePickerFromTo() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:W32:B7,8,9,10,18,19,28"))

        let picker = MovePicker(position)
        XCTAssertNil(picker.onlyCandidate)
        
        picker.toggle(32)
        picker.toggle(23)
        XCTAssertNotEqual(picker.requirements, .empty)
        XCTAssertNil(picker.onlyCandidate)
        
        XCTAssertNotNil(picker.onlyCandidate(from: 32, to: 23))
    }
    
    func testMovePickerOverride() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:W35,36:B20,21,22,30,31"))
        let picker = MovePicker(position)
        
        picker.toggle(27)
        XCTAssertNil(picker.onlyCandidate)
        XCTAssertNotNil(picker.onlyCandidate(from: 35, to: 15))
        
        picker.toggle(35)
        XCTAssertNotNil(picker.onlyCandidate)
    }
    
    func testMovePickerDifficult() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:WK46:B9,12,13,22,23,32"))
        let helper = GameHelper(position: position)
        
        XCTAssertFalse(helper.move(from: 46, to: 28))
        XCTAssertFalse(helper.toggle(9))
        XCTAssertTrue(helper.move(from: 46, to: 28))
    }
    
    func testUnambiguousNotation() {
        do {
            let position = SafeXCTAssertNotNil(Position(fen: "W:WK47:B42,43,39,40"))
            let moves = position.legalMoves.map { $0.unambiguousNotation }
            
            XCTAssertEqual(moves.count, 2)
            XCTAssert(moves.contains("47x35 (over 43)"))
            XCTAssert(moves.contains("47x35 (over 39)"))
        }
        
        do {
            let position = SafeXCTAssertNotNil(Position(fen: "W:WK21:B9,12,13,29,31,34"))
            let moves = position.legalMoves.map { $0.unambiguousNotation }
            
            XCTAssertEqual(moves.count, 4)
            XCTAssert(moves.contains("21x26 (over 13 and 34)"))
        }
    }
    
    func testMoveFromOne() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:WK1:B"))
        XCTAssertNotEqual(position.legalMoves.count, 0)
    }
    
    func testGameHelper() {
        do {
            let position = SafeXCTAssertNotNil(Position(fen: "B:W48,49:B2,3"))
            let helper = GameHelper(position: position)
            XCTAssertTrue(helper.game.moves.isEmpty)
            
            helper.toggle(9)
            XCTAssertEqual(helper.game.moves.count, 1)
            
            helper.move(from: 48, to: 43)
            XCTAssertEqual(helper.game.moves.count, 2)
        }
        
        do {
            let helper = GameHelper(position: .start)
            XCTAssertTrue(helper.game.moves.isEmpty)
            
            XCTAssertFalse(helper.toggle(30))
            XCTAssertTrue(helper.toggle(35))
            
            XCTAssertTrue(helper.move(from: 17, to: 21))
        }
        
        do {
            let helper = GameHelper(position: .start)
            
            XCTAssertTrue(helper.move(from: 32, to: 28))
            XCTAssertFalse(helper.forward())
            XCTAssertTrue(helper.backward())
            XCTAssertFalse(helper.backward())
            XCTAssertTrue(helper.move(from: 32, to: 27))
            XCTAssertTrue(helper.move(from: 19, to: 23))
            XCTAssertTrue(helper.backward())
            XCTAssertTrue(helper.move(from: 18, to: 23))
            XCTAssertFalse(helper.forward())
            
            XCTAssertEqual(helper.game.pdn, "1. 32-28 (1. 32-27 19-23 (1. ... 18-23))")
        }
    }
    
    func testGameHelperPosition() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:W47:B5"))
        let helper = GameHelper(position: position)
        
        XCTAssertTrue(helper.toggle(41))
        XCTAssertTrue(helper.toggle(10))
        
        XCTAssertEqual(helper.position, SafeXCTAssertNotNil(Position(fen: "W:W41:B10")))
        
        XCTAssertTrue(helper.backward())
        XCTAssertEqual(helper.position, SafeXCTAssertNotNil(Position(fen: "B:W41:B5")))
        
        XCTAssertTrue(helper.backward())
        XCTAssertEqual(helper.position, position)
        
        XCTAssertTrue(helper.toggle(42))
        XCTAssertEqual(helper.position, SafeXCTAssertNotNil(Position(fen: "B:W42:B5")))
    }
    
    func testPDN() {
        do {
            let gameHelper = GameHelper(position: SafeXCTAssertNotNil(Position(fen: "B:W37:B14")))
            
            XCTAssertTrue(gameHelper.move(from: 14, to: 19))
            XCTAssertTrue(gameHelper.move(from: 37, to: 31))
            
            XCTAssertEqual(gameHelper.game.pdn, "1. ... 14-19 2. 37-31")
        }
        
        do {
            let game = SafeXCTAssertNotNil(Game(pdn: "1. 32-28 19-23 2. 28x19 14x23"))
            
            XCTAssertEqual(game.moves.count, 4)
            XCTAssertEqual(game.endPosition.pieces(of: .white).count, 19)
            XCTAssertEqual(game.endPosition.pieces(of: .black).count, 19)
        }
        
        do {
            let raphael = SafeXCTAssertNotNil(Position(fen: "W:W27,28,32,37,38,33,34,48,49:B24,23,19,13,12,17,21,16,26"))
            let result = SafeXCTAssertNotNil(Position(fen: "B:W17:B7"))
            
            let notation = "1. 34-29 23x34 2. 28-23 19x39 3. 37-31 26x28 4. 49-44 21x43 5. 44x11 16x7 6. 48x17"
            let game = SafeXCTAssertNotNil(Game(pdn: notation, position: raphael))
            
            XCTAssertEqual(game.endPosition, result)
        }
        
        do {
            let pdn = "1. 32-28 (1. 32-27 19-23 (1. ... 18-23); 1. 31-26 16-21 2. 36-31)"
            let game = SafeXCTAssertNotNil(Game(pdn: pdn))
            XCTAssertEqual(game.pdn, pdn)
        }
        
        do {
            let fen = "W:W24,44,K5:B26,27,36,"
            let pdn = "1. 44-40 26-31 2. 40-35 27-32 3. 05x26 36-41 4. 26-42 (4. 26-12 41-47 5. 12-29) 41-47 5. 42-29 47-41 6. 29-23 41x30 7. 35x24"
            
            let position = SafeXCTAssertNotNil(Position(fen: fen))
            XCTAssertNotNil(Game(pdn: pdn, position: position))
        }
        
        do {
            let fen = "W:W20,24,30,33,40,43,47,:B7,10,12,22,27,29,36,"
            let pdn = "1. 20-15 29x49 2. 15x04 49x35 3. 47-41 36x47 4. 04-15 47x20 5. 15x38x16x02 35x24 6. 02x30 22-28 7. 30-25 28-32 8. 25-03 12-18 9. 03-09 18-23 10. 09-20"
            
            let position = SafeXCTAssertNotNil(Position(fen: fen))
            XCTAssertNotNil(Game(pdn: pdn, position: position))
        }
    }
    
    func testGameDelete() {
        do {
            var game = SafeXCTAssertNotNil(Game(pdn: "1. 32-28 (1. 32-27 16-21) 19-23"))
            game.remove(from: game.startPly.successor)
            
            let expected = SafeXCTAssertNotNil(Game(pdn: "1. 32-27 16-21"))
            XCTAssertEqual(game, expected)
        }
        
        do {
            var game = SafeXCTAssertNotNil(Game(pdn: "1. 32-28 (1. 32-27 16-21) 19-24 2. 37-32 14-19 (2. ... 13-19)"))
            game.remove(from: Ply(player: .white, number: 4))
            
            let expected = SafeXCTAssertNotNil(Game(pdn: "1. 32-28 (1. 32-27 16-21) 19-24 2. 37-32 13-19"))
            XCTAssertEqual(game, expected)
        }
    }
    
    func testGameHelperDelete() {
        do {
            let game = SafeXCTAssertNotNil(Game(pdn: "1. 32-28 (1. 32-27 16-21) 19-24 2. 37-32 14-19 (2. ... 24-30 35x24)"))
            let helper = GameHelper(game: game)
            
            helper.remove(from: helper.index)
            XCTAssertTrue(helper.forward())
            XCTAssertTrue(helper.forward())
            XCTAssertTrue(helper.move(from: 20, to: 29))
            
            let expected = SafeXCTAssertNotNil(Game(pdn: "1. 32-28 (1. 32-27 16-21) 19-24 2. 37-32 24-30 3. 35x24 20x29"))
            XCTAssertEqual(helper.game, expected)
        }
        
        do {
            let helper = GameHelper(position: .start)
            
            XCTAssertTrue(helper.move(from: 32, to: 28))
            XCTAssertTrue(helper.backward())
            XCTAssertTrue(helper.move(from: 33, to: 28))
            helper.remove(from: helper.index)
            
            let expected = SafeXCTAssertNotNil(Game(pdn: "1. 32-28"))
            XCTAssertEqual(helper.game, expected)
        }
    }
    
    func testLockedGame() {
        let helper = GameHelper(position: .start)
        
        XCTAssertTrue(helper.move(from: 32, to: 28))
        XCTAssertTrue(helper.move(from: 18, to: 23))
        
        helper.lock()
        
        XCTAssertTrue(helper.move(from: 38, to: 32))
        XCTAssertEqual(helper.game.pdn, "1. 32-28 18-23 (2. 38-32)")
        
        XCTAssertTrue(helper.backward())
        XCTAssertTrue(helper.backward())
        
        XCTAssertTrue(helper.move(from: 17, to: 21))
        XCTAssertEqual(helper.game.pdn, "1. 32-28 18-23 (1. ... 17-21) (2. 38-32)")
        
        XCTAssertTrue(helper.backward())
        XCTAssertTrue(helper.forward())
        XCTAssertFalse(helper.forward())
        
        XCTAssertTrue(helper.move(from: 38, to: 32))
        helper.remove(from: helper.index)
        XCTAssertEqual(helper.game.pdn, "1. 32-28 18-23 (1. ... 17-21)")
    }
    
    func testVariationPromotion() {
        let helper = GameHelper(position: .start)
        
        XCTAssertTrue(helper.move(from: 33, to: 28))
        XCTAssertTrue(helper.backward())
        XCTAssertTrue(helper.move(from: 32, to: 28))
        XCTAssertTrue(helper.move(from: 18, to: 23))
        
        helper.promote(at: helper.index)
        XCTAssertEqual(helper.game.pdn, "1. 32-28 (1. 33-28) 18-23")
    }
    
    func testDarkPosition() {
        let fens: [(fen: String, expected: String)] = [
            ("W:W28:B23,19,13,9", "W:W28:B23,19"),
            ("W:W28,24:B23,19,13,9", "W:W28,24:B23,19,13")
        ]
        
        for (fen, expected) in fens {
            let position = SafeXCTAssertNotNil(Position(fen: fen))
            let expectedDark = SafeXCTAssertNotNil(Position(fen: expected))
            XCTAssertEqual(position.darkPosition, expectedDark)
        }
    }
    
    func testDarkPositions() {
        let position = SafeXCTAssertNotNil(Position(fen: "B:W24,32,33:B2,10,13,14,23"))
        let game = SafeXCTAssertNotNil(Game(pdn: "2-8 33-28 14-19", position: position))
        
        let expected: [(white: String, black: String)] = [
            ("B:W24,32,33:B", "B:W:B2,10,13,14,23"),
            ("W:W24,32,33:B", "W:W:B8,10,13,14,23"),
            ("B:W24,28,32:B", "B:W28,32:B8,10,13,14,23"),
            ("W:W24,28,32:B13,19,23", "W:W28,32:B8,10,13,19,23")
        ]
        
        let darkPositions = game.positions.indices.map { game.darkPositions(at: Game.PositionIndex(ply: $0)) }
        
        for (expected, real) in zip(expected, darkPositions) {
            let white = SafeXCTAssertNotNil(Position(fen: expected.white))
            let black = SafeXCTAssertNotNil(Position(fen: expected.black))
            
            XCTAssertEqual(white, real.white)
            XCTAssertEqual(black, real.black)
        }
    }
    
    func testGameToPosition() {
        let helper = GameHelper(position: .start)
        
        helper.move(from: 32, to: 28)
        helper.move(from: 19, to: 23)
        helper.backward()
        helper.move(from: 18, to: 23)
        helper.move(from: 37, to: 32)
        helper.backward()
        helper.move(from: 38, to: 32)
        
        let game = helper.game.gameToPosition(at: helper.index)
        let expected = SafeXCTAssertNotNil(Game(pdn: "32-28 18-23 38-32"))
        XCTAssertEqual(game, expected)
    }
    
    func testTrace() {
        let game = SafeXCTAssertNotNil(Game(pdn: "32-28 19-23 28x19 14x23"))
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
    
    func testTraceNonLinear() {
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
    
    func testTraceRemoveAdd() {
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
                Piece(player: .black, kind: .man, square: 17): Piece(player: .black, kind: .man, square: 21),
                Piece(player: .black, kind: .man, square: 18): Piece(player: .black, kind: .man, square: 27)
            ],
            removed: [
                Piece(player: .white, kind: .man, square: 19)
            ],
            added: [
                Piece(player: .black, kind: .man, square: 19)
            ]
        )
        
        XCTAssertEqual(trace, expected)
    }
    
    func testTracePromote() {
        let position = SafeXCTAssertNotNil(Position(fen: "W:W10:B41"))
        let helper = GameHelper(position: position)
        
        let index1 = helper.index
        
        helper.toggle(5)
        helper.toggle(46)
        
        let index2 = helper.index
        let trace1 = helper.move(to: index1)
        
        let dest1 = SafeXCTAssertNotNil(trace1.destination(of: Piece(player: .white, kind: .king, square: 5)))
        XCTAssertEqual(dest1, Piece(player: .white, kind: .man, square: 10))
        
        let dest2 = SafeXCTAssertNotNil(trace1.destination(of: Piece(player: .black, kind: .king, square: 46)))
        XCTAssertEqual(dest2, Piece(player: .black, kind: .man, square: 41))
        
        let trace2 = helper.move(to: index2)
        
        let dest3 = SafeXCTAssertNotNil(trace2.destination(of: Piece(player: .white, kind: .man, square: 10)))
        XCTAssertEqual(dest3, Piece(player: .white, kind: .king, square: 5))
        
        let dest4 = SafeXCTAssertNotNil(trace2.destination(of: Piece(player: .black, kind: .man, square: 41)))
        XCTAssertEqual(dest4, Piece(player: .black, kind: .king, square: 46))
    }
}
