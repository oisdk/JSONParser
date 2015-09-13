public enum Result<T,E> { case Some(T), Error(E) }

extension Result {
  func map<U>(f: T -> U) -> Result<U,E> {
    switch self {
    case let .Error(e): return .Error(e)
    case let x?: return .Some(f(x))
    }
  }
  func flatMap<U>(f: T -> Result<U,E>) -> Result<U,E> {
    switch self {
    case let .Error(e): return .Error(e)
    case let x?: return f(x)
    }
  }
}