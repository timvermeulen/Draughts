public enum Player {
    case white, black
    
    public var opponent: Player {
        switch self {
        case .white:
            return .black
        case .black:
            return .white
        }
    }
}
