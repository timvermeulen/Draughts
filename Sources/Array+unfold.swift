extension Array {
    /// Note: returns a non-empty array
    internal init(first: Element, next: (Element) throws -> Element?) rethrows {
        self = [first]
        var last = first
        
        while let nextElement = try next(last) {
            append(nextElement)
            last = nextElement
        }
    }
}
