extension Array {
    /// Note: returns a non-empty array
    internal init(first: Element, next: (Element) throws -> Element?) rethrows {
        self = [first]
        var last = first
        
        while let element = try next(last) {
            append(element)
            last = element
        }
    }
    
    init<State>(state: State, next: (inout State) throws -> Element?) rethrows {
        self = []
        var state = state
        
        while let element = try next(&state) {
            append(element)
        }
    }
}
