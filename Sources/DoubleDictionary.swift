internal struct DoubleDictionary<Key1: Hashable, Key2: Hashable> {
    fileprivate var forward: [Key1: Key2]
    fileprivate var backward: [Key2: Key1]
}

extension DoubleDictionary {
    internal init(_ dictionary: [Key1: Key2]) {
        self.forward = dictionary
        self.backward = Dictionary(dictionary.lazy.map { ($0.value, $0.key) })
    }
    
    internal init<S: Sequence>(_ sequence: S) where S.Iterator.Element == (Key1, Key2) {
        self = [:]
        
        for (key1, key2) in sequence {
            self.insert(key1, key2)
        }
    }
    
    internal subscript(key1 key: Key1) -> Key2? {
        return forward[key]
    }
    
    internal subscript(key2 key: Key2) -> Key1? {
        return backward[key]
    }
    
    internal mutating func insert(_ key1: Key1, _ key2: Key2) {
        if let existing = self.forward[key1] { self.backward[existing] = nil }
        if let existing = self.backward[key2] { self.forward[existing] = nil }
        
        self.forward[key1] = key2
        self.backward[key2] = key1
    }
    
    internal func reversed() -> DoubleDictionary<Key2, Key1> {
        return DoubleDictionary<Key2, Key1>(forward: self.backward, backward: self.forward)
    }
}

extension DoubleDictionary: Collection {
    internal typealias Element = (key1: Key1, key2: Key2)
    internal typealias Index = Dictionary<Key1, Key2>.Index
    
    internal var startIndex: Index { return self.forward.startIndex }
    internal var endIndex: Index { return self.forward.endIndex }
    
    internal func index(after index: Index) -> Index {
        return self.forward.index(after: index)
    }
    
    internal subscript(index: Index) -> Element {
        let (key1, key2) = self.forward[index]
        return (key1, key2)
    }
}

extension DoubleDictionary: Equatable {
    internal static func == (left: DoubleDictionary, right: DoubleDictionary) -> Bool {
        return left.forward == right.forward
    }
}

extension DoubleDictionary: ExpressibleByDictionaryLiteral {
    internal init(dictionaryLiteral elements: (Key1, Key2)...) {
        self.init([:])
        
        for (key1, key2) in elements {
            self.forward[key1] = key2
            self.backward[key2] = key1
        }
    }
}

extension DoubleDictionary: TextOutputStreamable {
    internal func write<Target: TextOutputStream>(to target: inout Target) {
        target.write("[")
        defer { target.write("]") }
        
        guard let (key1, key2) = self.first else {
            target.write(":")
            return
        }
        
        target.write("\(key1): \(key2)")
        
        for (key1, key2) in self.dropFirst() {
            target.write(", \(key1): \(key2)")
        }
    }
}
