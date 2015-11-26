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

public enum JSONError {
  case Lit(expecting: String, found: String)
  case Number(String)
  case NoClosingDelimArray(soFar: String, found: String)
  case NoClosingDelimObject(soFar: String, found: String)
  case NoClosingDelimString(soFar: String, found: String)
  case Empty
}

extension JSONError : CustomStringConvertible {
  public var description: String {
    switch self {
    case let .Lit(e,f):
      return "Malformed literal. Expecting: " + e + ", found: " + f
    case let .Number(n):
      return "Malformed number. Found: " + n
    case let .NoClosingDelimArray(f,s):
      return "Array without closing \"]\". In array: " + f + "at point: " + s
    case let .NoClosingDelimObject(f,s):
      return "Object without closing \"}\". In object: " + f + "at point: " + s
    case let .NoClosingDelimString(f,s):
      return "String without closing \". In string: " + f + "at point: " + s
    case .Empty: return "Empty string"
    }
  }
}