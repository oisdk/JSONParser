public enum Result<T,E> { case Some(T), Error(E) }

extension Result {
  public func map<U>(@noescape f: T -> U) -> Result<U,E> {
    switch self {
    case let .Error(e): return .Error(e)
    case let x?: return .Some(f(x))
    }
  }
  public func flatMap<U>(@noescape f: T -> Result<U,E>) -> Result<U,E> {
    switch self {
    case let .Error(e): return .Error(e)
    case let x?: return f(x)
    }
  }
}