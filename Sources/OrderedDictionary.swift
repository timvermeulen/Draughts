public struct OrderedDictionary<Key: Equatable, Value> {
    public typealias Element = (key: Key, value: Value)
    
    fileprivate var contents: ArraySlice<Element>
    
    internal init(contents: ArraySlice<Element> = []) {
        self.contents = contents
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
    public typealias SubSequence = OrderedDictionary
    
    public var startIndex: Int { return self.contents.startIndex }
    public var endIndex: Int { return self.contents.endIndex }
    
    public func index(before index: Int) -> Int { return index - 1 }
    public func index(after index: Int) -> Int { return index + 1 }
    
    public subscript(index: Int) -> Element {
        return self.contents[index]
    }
    
    public subscript(range: Range<Int>) -> OrderedDictionary {
        return OrderedDictionary(contents: self.contents[range])
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
        // TODO: figure out why `self.init()` isn't allowed
        self.init(contents: [])
        
        for (key, value) in elements {
            self[key] = value
        }
    }
}
