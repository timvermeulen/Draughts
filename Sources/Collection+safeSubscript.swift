// TODO(swift4): remove generic constraints
// TODO(swift4): remove `Iterator`
extension Collection where Index == Indices.Iterator.Element {
    public subscript(checking index: Index) -> Iterator.Element? {
        guard indices.contains(index) else { return nil }
        return self[index]
    }
}

extension MutableCollection where Index == Indices.Iterator.Element {
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
