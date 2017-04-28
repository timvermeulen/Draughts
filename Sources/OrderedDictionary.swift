// basically a dictionary that uses contiguous storage for performance reasons
public struct OrderedDictionary<Key: Equatable, Value> {
    public typealias Element = (key: Key, value: Value)
    
    fileprivate var contents: ArraySlice<Element>
    
    internal init(contents: ArraySlice<Element>) {
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
    
    @discardableResult
    public mutating func removeValue(forKey key: Key) -> Value? {
        guard let value = self[key] else { return nil }
        defer { self[key] = nil }
        return value
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
    
    public var indices: CountableRange<Int> {
        return self.contents.indices
    }
}

extension OrderedDictionary: ExpressibleByDictionaryLiteral {
    public init(dictionaryLiteral elements: (Key, Value)...) {
        contents = []
        
        for (key, value) in elements {
            self[key] = value
        }
    }
}

// TODO: Conditional Conformance
extension OrderedDictionary where Value: Equatable {
    public static func == (left: OrderedDictionary, right: OrderedDictionary) -> Bool {
        return left.contents.count == right.contents.count && !left.contents.contains(where: { right[$0] != $1 })
    }
    
    public static func != (left: OrderedDictionary, right: OrderedDictionary) -> Bool {
        return !(left == right)
    }
}
