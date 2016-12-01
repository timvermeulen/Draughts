public struct OrderedDictionary<Key: Equatable, Value> {
    public typealias Element = (key: Key, value: Value)
    
    fileprivate var contents: [Element]
    
    internal init() {
        self.contents = []
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return self.contents.first(where: { $0.key == key }).map { $0.value }
        }
        set {
            if let value = newValue {
                if let index = self.contents.index(where: { $0.key == key }) {
                    self.contents[index] = (key, value)
                } else {
                    self.contents.append((key, value))
                }
            } else if let index = self.contents.index(where: { $0.key == key }) {
                self.contents.remove(at: index)
            }
        }
    }
}

extension OrderedDictionary: RandomAccessCollection {
    public var startIndex: Int { return 0 }
    public var endIndex: Int { return self.contents.count }
    
    public func index(before index: Int) -> Int { return index - 1 }
    public func index(after index: Int) -> Int { return index + 1 }
    
    public subscript(index: Int) -> Element {
        return self.contents[index]
    }
    
    public func index(_ index: Int, offsetBy offset: Int) -> Int {
        return index + offset
    }
    
    public func distance(from start: Int, to end: Int) -> Int {
        return end - start
    }
    
    public var indices: CountableRange<Int> {
        return self.contents.indices
    }
}

extension OrderedDictionary: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        self.init()
        
        for (key, value) in elements {
            self[key] = value
        }
    }
}
