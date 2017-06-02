extension Collection {
    public subscript(checking index: Index) -> Iterator.Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

extension MutableCollection {
    public subscript(checking index: Index) -> Iterator.Element? {
        get {
            guard indices.contains(index) else { return nil }
            return self[index]
        }
        set {
            if indices.contains(index), let value = newValue {
                self[index] = value
            }
        }
    }
}
