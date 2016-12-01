import XCTest

let errorMessage = "`continueAfterFailure` should be set to `false` inside `setUp()`, and set to `true` inside `tearDown()`"

public func SafeXCTFail(_ message: String = "", file: StaticString = #file, line: UInt = #line) -> Never {
    XCTFail(message, file: file, line: line)
    fatalError(errorMessage)
}

public func SafeXCTAssertNotNil<T>(_ expression: @autoclosure () throws -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> T {
    XCTAssertNotNil(try expression(), message(), file: file, line: line)
    
    do {
        guard let result = try expression() else { fatalError(errorMessage) }
        return result
    } catch {
        fatalError(errorMessage)
    }
}

open class SafeXCTestCase: XCTestCase {
    override open func setUp() {
        super.setUp()
        self.continueAfterFailure = false
    }
    
    override open func tearDown() {
        self.continueAfterFailure = true
        super.tearDown()
    }
}
