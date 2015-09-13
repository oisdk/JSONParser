extension JSON : CustomStringConvertible {
  public var description: String { return desWithInd("") }
  private func desWithInd(i: String) -> String {
    switch self {
    case let .A(a):
      let indntd = a.map { e in i + "    " + e.desWithInd(i + "    ") }
      let joined = indntd.joinWithSeparator(",\n")
      return "[\n" + joined + "\n" + i + "]"
    case let .O(o):
      let indntd = o.map { (k,v) in i + "    \"" + k + "\": " + v.desWithInd(i + "    ")}
      let joined = indntd.joinWithSeparator(",\n")
      return "{\n" + joined + "\n" + i + "}"
    case let .S(s): return "\"" + s + "\""
    case let .B(b): return b.description
    case let .D(d): return d.description
    case let .I(i): return i.description
    case null     : return "null"
    }
  }
}

extension JSONError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .UnBal(s): return "Unbalanced delimiters: " + s
    case let .Parse(s): return "Parse error on: " + s
    case .Empty       : return "Unexpected empty."
    }
  }
}