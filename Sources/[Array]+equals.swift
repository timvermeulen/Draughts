// TODO: Conditional Conformance
internal func == <T: Equatable> (left: [[T]], right: [[T]]) -> Bool {
    return left.count == right.count && !zip(left, right).contains(where: { $0.0 != $0.1 })
}
