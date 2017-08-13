import XCTest
import Draughts

class TestCase: XCTestCase {
    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }
    
    override func tearDown() {
        continueAfterFailure = true
        super.tearDown()
    }
}

@discardableResult
func assertPositionExists(fen: String, file: StaticString = #file, line: UInt = #line) -> Position {
    return Position(fen: fen).unwrap("invalid fen", file: file, line: line)
}

@discardableResult
func assertGameExists(pdn: String, position: Position, file: StaticString = #file, line: UInt = #line) -> Game {
    return Game(pdn: pdn, position: position).unwrap("invalid pdn", file: file, line: line)
}

@discardableResult
func assertGameExists(pdn: String, fen: String, file: StaticString = #file, line: UInt = #line) -> Game {
    let position = assertPositionExists(fen: fen, file: file, line: line)
    return assertGameExists(pdn: pdn, position: position, file: file, line: line)
}

@discardableResult
func assertGameExists(pdn: String, file: StaticString = #file, line: UInt = #line) -> Game {
    return Game(pdn: pdn).unwrap("invalid pdn", file: file, line: line)
}

extension Optional {
    func unwrap(_ message: @autoclosure () -> String = "unexpectedly found nil", file: StaticString = #file, line: UInt = #line) -> Wrapped {
        guard let value = self else { XCTFail(message(), file: file, line: line); fatalError() }
        return value
    }
}
