private let ind = "  "
extension JSON : CustomStringConvertible {
  public var description: String { return indented("") }
  private func indented(i: String) -> String {
    let lev = i + ind
    switch self {
    case let .JArray(a) :
      let inner = a.lazy.map { e in lev + e.indented(lev) }.joinWithSeparator(",\n")
      return "[\n" + inner + "\n" + i + "]"
    case let .JObject(o):
      let inner = o.lazy.map { (k,v) in lev + k.asJSONString + ": " + v.indented(lev)}
      return "{\n" + inner.joinWithSeparator(",\n") + "\n" + i + "}"
    case let .JString(s): return s.asJSONString
    case let .JBool(b)  : return String(b)
    case let .JFloat(d) : return String(d)
    case let .JInt(i)   : return String(i)
    case null           : return "null"
    }
  }
}

extension String {
  private var asJSONString: String {
    var res = "\""
    for c in unicodeScalars {
      switch c {
      case "\\"    : res.appendContentsOf("\\\\")
      case "\""    : res.appendContentsOf("\\\"")
      case "\u{8}" : res.appendContentsOf("\\b")
      case "\u{12}": res.appendContentsOf("\\f")
      case "\n"    : res.appendContentsOf("\\n")
      case "\r"    : res.appendContentsOf("\\r")
      case "\t"    : res.appendContentsOf("\\t")
      default      : res.append(c)
      }
    }
    return res + "\""
  }
}