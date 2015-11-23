public enum Result<A,B> {
  case Some(A), None(B)
}

public extension Result {
  func map<C>(@noescape f: A -> C) -> Result<C,B> {
    switch self {
    case let x?: return .Some(f(x))
    case let .None(x): return .None(x)
    }
  }
  func flatMap<C>(@noescape f: A -> Result<C,B>) -> Result<C,B> {
    switch self {
    case let x?: return f(x)
    case let .None(x): return .None(x)
    }
  }
}

public func pure<A,B>(a:A) -> Result<A,B> { return .Some(a) }