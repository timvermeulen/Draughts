// basically a dictionary that uses contiguous storage for performance reasons
public struct OrderedDictionary<Key: Equatable, Value> {
    public typealias Element = (key: Key, value: Value)
    
    fileprivate var contents: ArraySlice<Element>
    
    internal init(contents: ArraySlice<Element>) {
        self.contents = contents
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return contents.first(where: { $0.key == key }).map { $0.value }
        }
        set {
            if let value = newValue {
                if let index = contents.index(where: { $0.key == key }) {
                    contents[index] = (key, value)
                } else {
                    contents.append((key, value))
                }
            } else if let index = contents.index(where: { $0.key == key }) {
                contents.remove(at: index)
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
    
    public var startIndex: Int { return contents.startIndex }
    public var endIndex: Int { return contents.endIndex }
    
    public func index(before index: Int) -> Int { return index - 1 }
    public func index(after index: Int) -> Int { return index + 1 }
    
    public subscript(index: Int) -> Element {
        return contents[index]
    }
    
    public subscript(range: Range<Int>) -> OrderedDictionary {
        return OrderedDictionary(contents: contents[range])
    }
    
    public var indices: CountableRange<Int> {
        return contents.indices
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
        return left.contents.count == right.contents.count && !left.contents.contains(where: { right[$0.key] != $0.value })
    }
    
    public static func != (left: OrderedDictionary, right: OrderedDictionary) -> Bool {
        return !(left == right)
    }
}
