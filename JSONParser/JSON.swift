public enum JSONError : ErrorType { case UnBalancedBrackets, ParseError, Empty }

extension String.CharacterView {
  func bracketSplit(open: Character, _ close: Character)
    -> Result<(String.CharacterView, String.CharacterView),JSONError> {
    var count = 1
    for i in indices.dropFirst() {
      if self[i.predecessor()] == "\\" { continue }
      if self[i] == close { --count } else
      if self[i] == open  { ++count }
      if count == 0 {
        return .Some(self[startIndex.successor()..<i], suffixFrom(i.successor()))
      }
    }
    return .Error(.UnBalancedBrackets)
  }
}

public enum JSON {
  case S(String), D(Double), I(Int), B(Bool), A([JSON]), O([String:JSON]), null
}

extension String {
  private func decodeAsAtom() -> Result<JSON,JSONError> {
    switch self {
    case "null" : return .Some(.null)
    case "true" : return .Some(.B(true))
    case "false": return .Some(.B(false))
    case let s: return
      Int(s).map    { i in .Some(.I(i)) } ??
        Double(s).map { d in .Some(.D(d)) } ??
        .Error(.ParseError)
    }
  }
}

extension String.CharacterView {

  private func decodeAsArray() -> Result<[JSON],JSONError> {
    var (curr,result) = (self,[JSON]())
    for ;; {
      switch curr.decodeToDelim() {
      case let (f,b)?:
        curr = b
        result.append(f)
      case .Error(.Empty): return .Some(result)
      case let .Error(e) : return .Error(e)
      }
    }
  }

  private func decodeAsDict() -> Result<[String:JSON],JSONError> {
    var (curr,result) = (self,[String:JSON]())
    while let i = curr.indexOf("\"") {
      guard let (k,b) = curr.suffixFrom(i).bracketSplit("\"", "\"")
        else { return .Error(.UnBalancedBrackets) }
      guard let j = b.indexOf(":") else { return .Error(.ParseError) }
      guard let (v,d) = b.suffixFrom(j.successor()).decodeToDelim()
        else { return .Error(.ParseError) }
      result[String(k)] = v
      curr = d
    }
    return .Some(result)
  }
}

private let wSpace: Set<Character> = [" ", ",", "\n"]

extension String.CharacterView {
  private func decodeToDelim() -> Result<(JSON, String.CharacterView),JSONError> {
    guard let i = indexOfNot(wSpace.contains) else { return .Error(.Empty) }
    switch self[i] {
    case "[":
      guard let (f,b) = suffixFrom(i).bracketSplit("[", "]")
        else { return .Error(.UnBalancedBrackets) }
      switch f.decodeAsArray() {
      case let a?       : return .Some(.A(a), b)
      case let .Error(e): return .Error(e)
      }
    case "{":
      guard let (f,b) = suffixFrom(i).bracketSplit("{", "}")
        else { return .Error(.UnBalancedBrackets) }
      switch f.decodeAsDict() {
      case let o?       : return .Some(.O(o), b)
      case let .Error(e): return .Error(e)
      }
    case "\"":
      guard let (f,b) = suffixFrom(i).bracketSplit("\"", "\"")
        else { return .Error(.UnBalancedBrackets) }
      return .Some(.S(String(f)), b)
    default:
      let suff = suffixFrom(i)
      let j = suff.indexOf(",") ?? suff.endIndex
      guard let a = String(suff.prefixUpTo(j).trim(wSpace)).decodeAsAtom()
        else { return .Error(.ParseError) }
      return .Some(a, suff.suffixFrom(j))
    }
  }
}

extension JSON : CustomStringConvertible {
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
    case null:      return "null"
    }
  }
  public var description: String {
    return desWithInd("")
  }
}

extension String {
  public func asJSONThrow() throws -> JSON {
    switch characters.decodeToDelim() {
    case let j?: return j.0
    case let .Error(e): throw e
    }
  }
  public func asJSONResult() -> Result<JSON,JSONError> {
    switch characters.decodeToDelim() {
    case let j?: return .Some(j.0)
    case let .Error(e): return .Error(e)
    }
  }
}
