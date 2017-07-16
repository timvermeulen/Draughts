// TODO(swift4): use String as a Collection
extension String {
    func components(separatedByCharactersIn string: String) -> [String] {
        return characters.split(whereSeparator: string.characters.contains).map(String.init)
    }
    
    func substring(from index: Index) -> String {
        return String(characters.suffix(from: index))
    }
    
    func replacing(_ x: Character, with y: String) -> String {
        return characters
            .split(separator: x, omittingEmptySubsequences: false)
            .lazy
            .map(String.init)
            .joined(separator: y)
    }
}
