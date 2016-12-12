extension Dictionary {
    internal init<S: Sequence>(_ elements: S) where S.Iterator.Element == (Key, Value) {
        self.init()
        
        for (key, value) in elements {
            self[key] = value
        }
    }
}
