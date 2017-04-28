private enum OptionalError: Swift.Error {
    case noValue
}

extension Optional {
    internal func unwrap() throws -> Wrapped {
        guard let value = self else { throw OptionalError.noValue }
        return value
    }
}
