extension Set {
    func filter(_ isIncluded: (Element) throws -> Bool) rethrows -> Set {
        var result: Set = []
        
        for element in self where try isIncluded(element) {
            result.insert(element)
        }
        
        return result
    }
}
