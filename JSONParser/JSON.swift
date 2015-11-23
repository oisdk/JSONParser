public enum JSON {
  case JString(String), JFloat(Double), JInt(Int)
  case JArray([JSON]), JObject([String:JSON])
  case JBool(Bool), null
}

extension JSON:
  IntegerLiteralConvertible,
  FloatLiteralConvertible,
  BooleanLiteralConvertible,
  NilLiteralConvertible,
  StringLiteralConvertible,
  ArrayLiteralConvertible,
  DictionaryLiteralConvertible {
  
  public init(integerLiteral i: Int)                    { self = .JInt(i)    }
  public init(floatLiteral f: Double)                   { self = .JFloat(f)  }
  public init(booleanLiteral b: Bool)                   { self = .JBool(b)   }
  public init(nilLiteral: ())                           { self = .null       }
  public init(stringLiteral s: String)                  { self = .JString(s) }
  public init(extendedGraphemeClusterLiteral s: String) { self = .JString(s) }
  public init(unicodeScalarLiteral s: String)           { self = .JString(s) }
  public init(arrayLiteral a: JSON...)                  { self = .JArray(a)  }
  public init(dictionaryLiteral: (String,JSON)...) {
    var dict = [String:JSON]()
    for (k,v) in dictionaryLiteral { dict[k] = v }
    self = .JObject(dict)
  }
}

extension JSON: Equatable {}

public func ==(lhs: JSON,rhs:JSON) -> Bool {
  switch (lhs, rhs){
  case let (.JString(a),.JString(b)): return a == b
  case let (.JBool(a)  ,.JBool(b)  ): return a == b
  case let (.JInt(a)   ,.JInt(b)   ): return a == b
  case let (.JFloat(a) ,.JFloat(b) ): return a == b
  case let (.JArray(a) ,.JArray(b) ): return a == b
  case let (.JObject(a),.JObject(b)): return a == b
  case     (.null      ,.null      ): return true
  default: return false
  }
}

extension JSON {
  public var array: [JSON]? {
    if case let .JArray(a) = self { return a }
    return nil
  }
  public var object: [String:JSON]? {
    if case let .JObject(o) = self { return o }
    return nil
  }
  public var string: String? {
    if case let .JString(s) = self { return s }
    return nil
  }
  public var bool: Bool? {
    if case let .JBool(b) = self { return b }
    return nil
  }
  public var int: Int? {
    if case let .JInt(i) = self { return i }
    return nil
  }
  public var double: Double? {
    if case let .JFloat(d) = self { return d }
    return nil
  }
}
