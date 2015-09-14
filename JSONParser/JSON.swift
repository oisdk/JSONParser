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

extension JSON {
  public var array: [JSON]? {
    guard case let .A(a) = self else { return nil }
    return a
  }
  public var object: [String:JSON]? {
    guard case let .O(o) = self else { return nil }
    return o
  }
  public var string: String? {
    guard case let .S(s) = self else { return nil }
    return s
  }
  public var bool: Bool? {
    guard case let .B(b) = self else { return nil }
    return b
  }
  public var int: Int? {
    guard case let .I(i) = self else { return nil }
    return i
  }
  public var double: Double? {
    guard case let .D(d) = self else { return nil }
    return d
  }
}

extension JSON {
  public subscript(i: Int) -> JSON? {
    get { return array?[i] }
    set {
      guard var a = array else { return }
      a[i] = newValue!
      self = .A(a)
    }
  }
  public subscript(s: String) -> JSON? {
    get { return object?[s] }
    set {
      guard var o = object else { return }
      o[s] = newValue!
      self = .O(o)
    }
  }
}