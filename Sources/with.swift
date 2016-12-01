internal func with<T>(_ x: T, _ block: (inout T) throws -> Void) rethrows -> T {
    var copy = x
    try block(&copy)
    return copy
}
