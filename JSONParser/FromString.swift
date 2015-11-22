private let wSpace: Set<Character> = [" ", ",", "\n"]
private let nullCh: [Character] = ["n","u","l","l"]
private let trueCh: [Character] = ["t","r","u","e"]
private let falsCh: [Character] = ["f","a","l","s","e"]

extension CollectionType where
  Generator.Element == Character,
  Index == Int,
  SubSequence == Self {
  private var asAt: Result<(JSON,Self),JSONError> {
    guard let t = indexOf(!wSpace.contains).map(suffixFrom)
      else { return .Error(.Parse(String(self))) }
    if t.startsWith(nullCh) { return .Some(.null, t.suffixFrom(4)) }
    if t.startsWith(trueCh) { return .Some(.B(true), t.suffixFrom(4)) }
    if t.startsWith(falsCh) { return .Some(.B(false), t.suffixFrom(5)) }
    let (a,b) = t.divide(",") ?? (t,t.suffixFrom(t.endIndex.predecessor()))
    guard let s = a.lastIndexOf(!wSpace.contains).map(a.prefixThrough).map(String.init)
      else { return .Error(.Parse(String(self))) }
    if let i = Int(s) { return Result.Some(JSON.I(i), b) }
    if let d = Double(s) { return .Some(.D(d), b) }
    return .Error(.Parse(s))
  }

  private var asAr: Result<([JSON],Self),JSONError> {
    var (curr,result): (SubSequence,[JSON]) = (self,[])
    for ;; {
      if let i = curr.indexOf(!wSpace.contains) where curr[i] == "]" {
        let tup: ([JSON],Self) = (result,curr.suffixFrom(i.successor()))
        return .Some(tup)
      }
      switch curr.nextDecoded {
      case let (f,b)?:
        curr = b
        result.append(f)
      case let .Error(e) : return .Error(e)
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
        guard case let (v,d)?? =
          (b.indexOf(":")?.successor()).map(b.suffixFrom)?.nextDecoded
          else { return .Error(.Parse(String(b))) }
        result[k] = v
        curr = d
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
    guard let i = indexOf(!wSpace.contains) else { return .Error(.Empty) }
    let v = suffixFrom(i.successor())
    switch self[i] {
    case "[" : return v.asAr.map { (a,b) in (.A(a),b) }
    case "{" : return v.asOb.map { (o,b) in (.O(o),b) }
    case "\"": return v.asString.map { (s,r) in (.S(s),r) }
    default  : return v.asAt
    }
  }
}

extension String {
  public func asJSON() -> Result<JSON,JSONError> {
    return ArraySlice(characters).nextDecoded.map { (j, _) in j}
  }
}
