public enum JSONError : ErrorType { case UnBal(String), Parse(String), Empty }

extension JSONError: CustomStringConvertible {
  public var description: String {
    switch self {
    case let .UnBal(s): return "Unbalanced delimiters: " + s
    case let .Parse(s): return "Parse error on: " + s
    case .Empty: return "Unexpected empty."
    }
  }
}

extension String.CharacterView {
  /// Splits a string into the contents of the first pair of balanced brackets and the 
  /// rest. Requires that the first character is the opening bracket.
  /// ```swift
  /// let str = "[1, 2, [3, 4], {"a":5, "b":6}, 7], "fugh", true, null"
  /// let ans = str.characters.bracks("[", "]")
  /// // "1, 2, [3, 4], {"a":5, "b":6}, 7"
  /// // , "fugh", true, null"
  /// ```
  private func brks(open: Character, _ close: Character)
    -> Result<(String.CharacterView, String.CharacterView),JSONError> {
    var count = 1
    let d = dropFirst()
    guard let i = d.indexOfNonEscaped({ c in
      if c == close { --count } else
      if c == open  { ++count }
      return count == 0
    }) else { return .Error(.UnBal(String(self))) }
    return .Some(d.prefixUpTo(i), d.suffixFrom(i.successor()))
  }
}

public enum JSON {
  case S(String), D(Double), I(Int), B(Bool), A([JSON]), O([String:JSON]), null
}

private let wSpace: Set<Character> = [" ", ",", "\n"]

extension String.CharacterView {
  private var asAt: Result<JSON,JSONError> {
    switch String(trim(wSpace)) {
    case "null" : return .Some(.null)
    case "true" : return .Some(.B(true))
    case "false": return .Some(.B(false))
    case let s: return
      Int(s).map    { i in .Some(.I(i)) } ??
      Double(s).map { d in .Some(.D(d)) } ??
      .Error(.Parse(s))
    }
  }

  private var asAr: Result<[JSON],JSONError> {
    var (curr,result) = (self,[JSON]())
    for ;; {
      switch curr.nextDecoded {
      case let (f,b)?:
        curr = b
        result.append(f)
      case .Error(.Empty): return .Some(result)
      case let .Error(e) : return .Error(e)
      }
    }
  }

  private var asOb: Result<[String:JSON],JSONError> {
    var (curr,result) = (self,[String:JSON]())
    while let i = curr.indexOf("\"") {
      switch curr.suffixFrom(i).brks("\"", "\"") {
      case let .Error(e) : return .Error(e)
      case let (k,b)?:
        guard let j = b.indexOf(":") else { return .Error(.Parse(String(b))) }
        guard let (v,d) = b.suffixFrom(j.successor()).nextDecoded
          else { return .Error(.Parse(String(b))) }
        result[String(k)] = v
        curr = d
      }
    }
    return .Some(result)
  }
}

extension String.CharacterView {
  private var nextDecoded: Result<(JSON, String.CharacterView),JSONError> {
    guard let i = indexOfNot(wSpace.contains) else { return .Error(.Empty) }
    let v = suffixFrom(i)
    switch self[i] {
    case "[" : return v.brks("[","]").flatMap { (f,b) in f.asAr.map { a in (.A(a),b) }}
    case "{" : return v.brks("{","}").flatMap { (f,b) in f.asOb.map { o in (.O(o),b) }}
    case "\"": return v.brks("\"","\"").map { (f,b) in (.S(String(f)),b) }
    default: return v.divide(",").map { (f,b) in f.asAt.map { a in (a,b) }} ??
      v.asAt.map { a in (a,"".characters) }
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
    switch characters.nextDecoded {
    case let j?: return j.0
    case let .Error(e): throw e
    }
  }
  public func asJSONResult() -> Result<JSON,JSONError> {
    return characters.nextDecoded.map { (j, _) in j}
  }
}
