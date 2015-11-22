private let wSpace: Set<Character> = [" ", ",", "\n"]
private let delims: Set<Character> = [" ", ",", "\n", "]", "}"]
private let nullCh: [Character] = ["n","u","l","l"]
private let trueCh: [Character] = ["t","r","u","e"]
private let falsCh: [Character] = ["f","a","l","s","e"]

extension CollectionType where
  Generator.Element == Character,
  Index: BidirectionalIndexType,
  SubSequence == Self {
  private var asAt: Result<(JSON,Self),JSONError> {
    if startsWith(nullCh) { return .Some(.null, dropFirst(4)) }
    if startsWith(trueCh) { return .Some(.B(true), dropFirst(4)) }
    if startsWith(falsCh) { return .Some(.B(false), dropFirst(5)) }
    guard let i = indexOf(wSpace.contains) else { return .Error(.Parse(String(self))) }
    let (s,b) = (String(prefixUpTo(i)),suffixFrom(i))
    if let i = Int(s) { return Result.Some(JSON.I(i), b) }
    if let d = Double(s) { return .Some(.D(d), b) }
    return .Error(.Parse(s))
  }

  private var asAr: Result<([JSON],Self),JSONError> {
    var (curr,result): (SubSequence,[JSON]) = (self,[])
    for ;; {
      switch curr.indexOf(!wSpace.contains) {
      case let i? where curr[i] == "]":
        let tup: ([JSON],Self) = (result,curr.suffixFrom(i.successor()))
        return .Some(tup)
      case nil: return .Error(.Parse(String(curr)))
      case let i?:
        switch curr.suffixFrom(i).nextDecoded {
        case let (f,b)?:
          curr = b
          result.append(f)
        case let .Error(e) : return .Error(e)
        }
      }
      
    }
  }

  private var asOb: Result<([String:JSON],Self),JSONError> {
    var (curr,result) = (self,[String:JSON]())
    while let i = curr.indexOf(!wSpace.contains) {
      if curr[i] == "}" {
        let tup: ([String:JSON],Self) = (result,curr.suffixFrom(i.successor()))
        return .Some(tup)
      }
      if curr[i] != "\"" { break }
      switch curr.suffixFrom(i.successor()).asString {
      case let .Error(e) : return .Error(e)
      case let (k,b)?:
        guard let col = b.indexOf(":")
          else { return .Error(.Parse("Expecting \":\", found: " + String(b))) }
        let c = b.suffixFrom(col.successor())
        switch c.indexOf(!wSpace.contains).map(c.suffixFrom)?.nextDecoded {
        case let .Error(e)?: return .Error(e)
        case let (v,d)??:
          result[k] = v
          curr = d
        case nil: return .Error(.Parse(String(c)))
        }
      }
    }
    return .Error(.UnBal(String(self)))
  }
  
  private var asString: Result<(String,Self),JSONError> {
    switch divideNonEscaped("\\", isC: { c in c == "\"" }) {
    case let (f,b)?: return .Some(String(f),b)
    case .None: return .Error(.UnBal(String(self)))
    }
  }

  private var nextDecoded: Result<(JSON, SubSequence),JSONError> {
    switch first! {
    case "[" : return dropFirst().asAr.map { (a,b) in (.A(a),b) }
    case "{" : return dropFirst().asOb.map { (o,b) in (.O(o),b) }
    case "\"": return dropFirst().asString.map { (s,r) in (.S(s),r) }
    default  : return asAt
    }
  }
}

extension String {
  public func asJSON() -> Result<JSON,JSONError> {
    return ArraySlice(characters).nextDecoded.map { (j, _) in j}
  }
}
