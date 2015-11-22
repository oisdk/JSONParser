extension CollectionType where
  Generator.Element == Character,
  SubSequence: CollectionType,
  SubSequence.Generator.Element == Character {
  private func brks(open: Character, _ close: Character)
    -> Result<(SubSequence.SubSequence, SubSequence.SubSequence),JSONError> {
    var count = 1
    return dropFirst().divideNonEscaped("\\") { c in
      if c == close { --count } else if c == open  { ++count }
      return count == 0
    }.map(Result.Some) ?? .Error(JSONError.UnBal(String(reflecting: self)))
  }
}

private let wSpace: Set<Character> = [" ", ",", "\n"]

extension CollectionType where
  Generator.Element == Character,
  Index: BidirectionalIndexType,
  SubSequence == Self,
  SubSequence: CollectionType,
  SubSequence.Generator.Element == Character,
  SubSequence.Index : BidirectionalIndexType {
  private var asAt: Result<JSON,JSONError> {
    guard let t = trim(wSpace) else { return .Error(.Parse(String(self))) }
    switch String(t) {
    case "null" : return .Some(.null)
    case "true" : return .Some(.B(true))
    case "false": return .Some(.B(false))
    case let s: return
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
      case let .Some(k,b):
        guard case let (v,d)?? =
          (b.indexOf(":")?.successor()).map(b.suffixFrom)?.nextDecoded
          else { return .Error(.Parse(String(b))) }
        result[String(k)] = v
        curr = d
      }
    }
    return .Some(result)
  }

  private var nextDecoded: Result<(JSON, SubSequence),JSONError> {
    guard let i = indexOf(!wSpace.contains) else { return .Error(.Empty) }
    let v = suffixFrom(i)
    switch self[i] {
    case "[" : return v.brks("[","]").flatMap { (f,b) in f.asAr.map { a in (.A(a),b) }}
    case "{" : return v.brks("{","}").flatMap { (f,b) in f.asOb.map { o in (.O(o),b) }}
    case "\"": return v.brks("\"","\"").map { (f,b) in (.S(String(f)),b) }
    default  : return v.divide(",").map { (f,b) in f.asAt.map { a in (a,b) }} ??
      v.asAt.map { a in (a,self[startIndex..<startIndex]) }
    }
  }
}

extension String {
  public func asJSONThrow() throws -> JSON {
    switch ArraySlice(characters).nextDecoded {
    case let j?: return j.0
    case let .Error(e): throw e
    }
  }
  public func asJSONResult() -> Result<JSON,JSONError> {
    return ArraySlice(characters).nextDecoded.map { (j, _) in j}
  }
}
