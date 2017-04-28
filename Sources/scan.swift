extension Sequence {
    internal func scan<Result>(_ initial: Result, _ next: (Result, Iterator.Element) throws -> Result) rethrows -> [Result] {
        var result = [initial]
        var last = initial
        
        for element in self {
            last = try next(last, element)
            result.append(last)
        }
        
        return result
    }
}
