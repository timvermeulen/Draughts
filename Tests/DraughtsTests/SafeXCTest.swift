import XCTest

public func fail(_ message: String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    XCTFail(message, file: file, line: line)
    fatalError("Make sure to subclass `TestCase` instead of `XCTestCase`")
}

public func unwrapOrFail<T>(_ expression: @autoclosure () -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> T {
    let result = expression()
    XCTAssertNotNil(result, message(), file: file, line: line)
    
    guard let unwrapped = result else { fail(message(), file: file, line: line) }
    return unwrapped
}

public func tryOrFail<T>(_ expression: @autoclosure () throws -> T, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> T {
    let result: T
    
    do { result = try expression() }
    catch { fail(message(), file: file, line: line) }
    
    return result
}

open class TestCase: XCTestCase {
    override open func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    override open func tearDown() {
        self.continueAfterFailure = true
        super.tearDown()
    }
}
