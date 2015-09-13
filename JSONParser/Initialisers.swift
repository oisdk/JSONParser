extension JSON {
  public init(_ s: String)        { self = .S(s) }
  public init(_ d: Double)        { self = .D(d) }
  public init(_ i: Int)           { self = .I(i) }
  public init(_ b: Bool)          { self = .B(b) }
  public init(_ a: [JSON])        { self = .A(a) }
  public init(_ o: [String:JSON]) { self = .O(o) }
  public init()                   { self = .null }
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
    self.init(booleanLiteral)
  }
}
extension JSON: NilLiteralConvertible {
  public init(nilLiteral: ()) {
    self.init()
  }
}
extension JSON: StringLiteralConvertible {
  public init(stringLiteral: String) {
    self.init(stringLiteral)
  }
  public init(extendedGraphemeClusterLiteral: String) {
    self.init(extendedGraphemeClusterLiteral)
  }
  public init(unicodeScalarLiteral: String) {
    self.init(unicodeScalarLiteral)
  }
}
extension JSON: ArrayLiteralConvertible {
  public init(arrayLiteral: JSON...) {
    self.init(arrayLiteral)
  }
}
extension JSON: DictionaryLiteralConvertible {
  public init(dictionaryLiteral: (String,JSON)...) {
    var dict = [String:JSON]()
    for (k,v) in dictionaryLiteral { dict[k] = v }
    self.init(dict)
  }
}