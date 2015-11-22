extension String.CharacterView {
  private func brks(open: Character, _ close: Character)
    -> Result<(String.CharacterView, String.CharacterView),JSONError> {
    var count = 1
    return dropFirst().divideNonEscaped("\\") { c in
      if c == close { --count } else if c == open  { ++count }
      return count == 0
    }.map(Result.Some) ?? .Error(.UnBal(String(self)))
  }
}

private let expChr: Set<Character> = ["E", "e"]
private let wSpace: Set<Character> = [" ", ",", "\n"]

extension Double {
  init?(exp: String) {
    guard let (f,b) = exp.characters.divideNonEscaped("\\", isC: expChr.contains) else { return nil }
    guard let n = Double(String(f)), e = Int(String(b)) else { return nil }
    self = (0..<abs(e)).map { _ in 10 }.reduce(n, combine: (e < 0 ? (/) : (*)))
  }
}

extension String.CharacterView {
  private var asAt: Result<JSON,JSONError> {
    guard let t = trim(wSpace) else { return .Error(.Parse(String(self))) }
    switch String(t) {
    case "null" : return .Some(.null)
    case "true" : return .Some(.B(true))
    case "false": return .Some(.B(false))
    case let s: return
      Double(exp: s).map { d in .Some(.D(d)) } ??
      Int(s).map { i in .Some(.I(i)) } ??
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
        guard case let (v,d)?? =
          (b.indexOf(":")?.successor()).map(b.suffixFrom)?.nextDecoded
          else { return .Error(.Parse(String(b))) }
        result[String(k)] = v
        curr = d
      }
    }
    return .Some(result)
  }

  private var nextDecoded: Result<(JSON, String.CharacterView),JSONError> {
    guard let i = indexOf(!wSpace.contains) else { return .Error(.Empty) }
    let v = suffixFrom(i)
    switch self[i] {
    case "[" : return v.brks("[","]").flatMap { (f,b) in f.asAr.map { a in (.A(a),b) }}
    case "{" : return v.brks("{","}").flatMap { (f,b) in f.asOb.map { o in (.O(o),b) }}
    case "\"": return v.brks("\"","\"").map { (f,b) in (.S(String(f)),b) }
    default  : return v.divide(",").map { (f,b) in f.asAt.map { a in (a,b) }} ??
      v.asAt.map { a in (a,"".characters) }
    }
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
