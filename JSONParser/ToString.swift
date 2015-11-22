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
    case let .B(b): return String(b)
    case let .D(d): return String(d)
    case let .I(i): return String(i)
    case null     : return "null"
    }
  }
}