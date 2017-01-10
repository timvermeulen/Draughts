import XCTest

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

extension TestCase {
    private func shouldNotHappen() -> Never {
        fatalError("`continueAfterFailure` should not be set to `true`")
    }
    
    public func fail(_ message: String = "", file: StaticString = #file, line: UInt = #line) -> Never {
        XCTFail(message, file: file, line: line)
        shouldNotHappen()
    }
    
    public func unwrapOrFail<T>(_ expression: @autoclosure () -> T?, _ message: @autoclosure () -> String = "", file: StaticString = #file, line: UInt = #line) -> T {
        let optional = expression()
        XCTAssertNotNil(optional, message(), file: file, line: line)
        guard let result = optional else { shouldNotHappen() }
        return result
    }
    
    public func tryOrFail<T>(_ expression: @autoclosure () throws -> T, file: StaticString = #file, line: UInt = #line, _ message: (Error) -> String = String.init(describing:)) -> T {
        do { return try expression() }
        catch { fail(message(error), file: file, line: line) }
    }
}
