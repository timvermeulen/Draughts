extension Optional {
    internal init(_ value: Wrapped, where predicate: (Wrapped) -> Bool) {
        self = predicate(value) ? value : nil
    }
    
    internal init(_ optional: Optional, where predicate: (Wrapped) -> Bool) {
        self = optional.flatMap { Optional($0, where: predicate) }
    }
}
