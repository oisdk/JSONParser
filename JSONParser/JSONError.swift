public enum JSONError : ErrorType { case UnBal(String), Parse(String), Empty }

extension JSONError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .UnBal(s): return "Unbalanced delimiters: " + s
    case let .Parse(s): return "Parse error on: " + s
    case .Empty       : return "Unexpected empty."
    }
  }
}