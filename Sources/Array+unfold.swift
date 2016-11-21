extension Array {
    internal init(first: Element, next: (Element) throws -> Element?) rethrows {
        self = [first]
        var last = first
        
        while let nextElement = try next(last) {
            self.append(nextElement)
            last = nextElement
        }
    }
}
