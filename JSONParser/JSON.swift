public enum JSON : Equatable {
  case S(String), D(Double), I(Int), B(Bool), A([JSON]), O([String:JSON]), null
}

extension JSON: IntegerLiteralConvertible {
  public init(integerLiteral: Int) {
    self = .I(integerLiteral)
  }
}
extension JSON: FloatLiteralConvertible {
  public init(floatLiteral: Double) {
    self = .D(floatLiteral)
  }
}
extension JSON: BooleanLiteralConvertible {
  public init(booleanLiteral: Bool) {
    self = .B(booleanLiteral)
  }
}
extension JSON: NilLiteralConvertible {
  public init(nilLiteral: ()) {
    self = .null
  }
}
extension JSON: StringLiteralConvertible {
  public init(stringLiteral: String) {
    self = .S(stringLiteral)
  }
  public init(extendedGraphemeClusterLiteral: String) {
    self = .S(extendedGraphemeClusterLiteral)
  }
  public init(unicodeScalarLiteral: String) {
    self = .S(unicodeScalarLiteral)
  }
}
extension JSON: ArrayLiteralConvertible {
  public init(arrayLiteral: JSON...) {
    self = .A(arrayLiteral)
  }
}
extension JSON: DictionaryLiteralConvertible {
  public init(dictionaryLiteral: (String,JSON)...) {
    var dict = [String:JSON]()
    for (k,v) in dictionaryLiteral { dict[k] = v }
    self = .O(dict)
  }
}

public func ==(lhs: JSON,rhs:JSON) -> Bool {
  switch (lhs, rhs){
  case let (.S(a),.S(b)): return a == b
  case let (.B(a),.B(b)): return a == b
  case let (.I(a),.I(b)): return a == b
  case let (.D(a),.D(b)): return a == b
  case let (.A(a),.A(b)): return a == b
  case let (.O(a),.O(b)): return a == b
  case (.null,.null): return true
  default: return false
  }
}