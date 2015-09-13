public enum JSON {
  case S(String), D(Double), I(Int), B(Bool), A([JSON]), O([String:JSON]), null
}
extension JSON {
  public init(_ s: String)        { self = .S(s) }
  public init(_ d: Double)        { self = .D(d) }
  public init(_ i: Int)           { self = .I(i) }
  public init(_ b: Bool)          { self = .B(b) }
  public init(_ a: [JSON])        { self = .A(a) }
  public init(_ o: [String:JSON]) { self = .O(o) }
  public init()                   { self = .null }
}

public enum JSONError : ErrorType { case UnBal(String), Parse(String), Empty }

extension String.CharacterView {
  private func brks(open: Character, _ close: Character)
    -> Result<(String.CharacterView, String.CharacterView),JSONError> {
    var count = 1
    return dropFirst().divideNonEscaped{ c in
      if c == close { --count } else if c == open  { ++count }
      return count == 0
    }.map(Result.Some) ?? .Error(.UnBal(String(self)))
  }
}

private let wSpace: Set<Character> = [" ", ",", "\n"]

extension String.CharacterView {
  private var asAt: Result<JSON,JSONError> {
    switch String(trim(wSpace)) {
    case "null" : return .Some(JSON())
    case "true" : return .Some(JSON(true))
    case "false": return .Some(JSON(false))
    case let s: return
      Int(s)   .map(JSON.init).map(Result.Some) ??
      Double(s).map(JSON.init).map(Result.Some) ??
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
    guard let i = indexOfNot(wSpace.contains) else { return .Error(.Empty) }
    let v = suffixFrom(i)
    switch self[i] {
    case "[" : return v.brks("[","]").flatMap { (f,b) in f.asAr.map { a in (JSON(a),b) }}
    case "{" : return v.brks("{","}").flatMap { (f,b) in f.asOb.map { o in (JSON(o),b) }}
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
