func uChr(n: UInt8) -> Character {
  return Character(UnicodeScalar(n))
}

func uStr<S : SequenceType where S.Generator.Element == UInt8>(s: S) -> String {
  return String(s.lazy.map(uChr))
}

extension CollectionType where Generator.Element == UInt8, SubSequence.Generator.Element == UInt8 {
  
  private func loc(from: Index) -> Int {
    return prefixUpTo(from).count(Code.newlin)
  }
  
  private func decodeNull(var from: Index) -> Result<(JSON,Index),String> {
    if (self[  from] == Code.u || self[from] == Code.U) &&
       (self[++from] == Code.l || self[from] == Code.L) &&
       (self[++from] == Code.l || self[from] == Code.L) {
        return Result<((JSON,Index)),String>.Some((JSON.null,from.successor()))
    }
    return .None("Line: \(loc(from)). Expecting null, found " + uStr(suffixFrom(from)))
  }
  
  private func decodeTrue(var from: Index) -> Result<(JSON,Index),String> {
    if (self[  from] == Code.r || self[from] == Code.R) &&
       (self[++from] == Code.u || self[from] == Code.U) &&
       (self[++from] == Code.e || self[from] == Code.E) {
        return Result<((JSON,Index)),String>.Some((JSON.JBool(true),from.successor()))
    }
    return .None("Line: \(loc(from)).Expecting true, found " + uStr(suffixFrom(from)))
  }
  
  private func decodeFalse(var from: Index) -> Result<(JSON,Index),String> {
    if (self[  from] == Code.a || self[from] == Code.A) &&
       (self[++from] == Code.l || self[from] == Code.L) &&
       (self[++from] == Code.s || self[from] == Code.S) &&
       (self[++from] == Code.e || self[from] == Code.E) {
        return Result<((JSON,Index)),String>.Some((JSON.JBool(false),from.successor()))
    }
    return .None("Line: \(loc(from)).Expecting false, found " + uStr(suffixFrom(from)))
  }
  
  private func decodeNum(from: Index) -> Result<(JSON,Index),String> {
    var isDouble = false
    for i in from..<endIndex {
      switch self[i] {
      case Code.Zero...Code.Nine, Code.plus, Code.hyphen: continue
      case Code.e, Code.E, Code.fullst: isDouble = true
      default:
        let s = uStr(self[from..<i])
        if let n = isDouble ? Double(s).map(JSON.JFloat) : Int(s).map(JSON.JInt) {
          return Result<((JSON,Index)),String>.Some((n,i))
        }
        return .None("Line: \(loc(from)).Expecting number, found: " + s)
      }
    }
    return .None("Unexpected eof when parsing number")
  }
  
  private func decodeString(var from: Index) -> Result<(String,Index),String> {
    var res = ""
    while true {
      switch self[from++] {
      case Code.quot:
        return Result<((String,Index)),String>.Some((res,from))
      case Code.bslash:
        guard let (a,b) = decodeEscaped(from)
          else { return .None(uStr(suffixFrom(from))) }
        res.append(a)
        from = b
      case let c: res.append(Character(UnicodeScalar(c)))
      }
    }
  }
  
  private func decodeEscaped(var from: Index) -> Result<(Character,Index),String> {
    switch self[from++] {
    case Code.quot  : return Result<((Character,Index)),String>.Some(("\"",from))
    case Code.fslash: return Result<((Character,Index)),String>.Some(("/",from))
    case Code.b: return Result<((Character,Index)),String>.Some(("\u{8}",from))
    case Code.f: return Result<((Character,Index)),String>.Some(("\u{12}",from))
    case Code.n: return Result<((Character,Index)),String>.Some(("\n",from))
    case Code.r: return Result<((Character,Index)),String>.Some(("\r",from))
    case Code.t: return Result<((Character,Index)),String>.Some(("\t",from))
    case Code.u:
      let end = from.advancedBy(4)
      let str = uStr(self[from..<end])
      guard let usc = UInt32(str, radix: 16) else {
        return .None("Line: \(loc(from)).Expecting unicode literal, found: " + str)
      }
      return Result<((Character,Index)),String>
        .Some((Character(UnicodeScalar(usc)),end))
    default: return .None(uStr(suffixFrom(from)))
    }
  }
  
  private func skipMany(from: Index, sep: UInt8, end: UInt8) -> Result<(Bool,Index),String> {
    for i in from..<endIndex {
      switch self[i] {
      case Code.space, Code.tab, Code.ret, Code.newlin, sep: continue
      case end: return .Some(true,i.successor())
      default: return .Some(false,i)
      }
    }
    return .None("Unexpected eof")
  }
  
  private func decodeArr(var from: Index) -> Result<([JSON],Index),String> {
    var res: [JSON] = []
    while let (e,i) = skipMany(from, sep: Code.comma, end: Code.squarC) {
      if e { return Result<(([JSON],Index)),String>.Some((res,i)) }
      guard let (a,j) = decode(i) else { return .None(uStr(suffixFrom(i))) }
      res.append(a)
      from = j
    }
    return .None("Line: \(loc(from)). Array not ended: " + uStr(suffixFrom(from)))
  }
  
  private func decodeObj(var from: Index) -> Result<([String:JSON],Index),String> {
    var res: [String:JSON] = [:]
    while let (e,i) = skipMany(from, sep: Code.comma, end: Code.curliC) {
      if e { return Result<(([String:JSON],Index)),String>.Some((res,i)) }
      guard let (key,j) = decodeString(i.successor()),
        (_,k) = skipMany(j, sep: Code.colon, end: Code.curliC),
        (val,l) = decode(k) else {
        return .None("Line: \(loc(from)): " + uStr(suffixFrom(i)))
      }
      res[key] = val
      from = l
    }
    return .None("Unexpected eof")
  }

  private func decode(from: Index) -> Result<(JSON,Index),String> {
    let i = from.successor()
    switch self[from] {
    case Code.squarO: return decodeArr(i).map { (a,b) in (.JArray(a),b) }
    case Code.curliO: return decodeObj(i).map { (a,b) in (.JObject(a),b) }
    case Code.quot: return decodeString(i).map { (a,b) in (.JString(a),b) }
    case Code.n, Code.N: return decodeNull(i)
    case Code.t, Code.T: return decodeTrue(i)
    case Code.f, Code.F: return decodeFalse(i)
    default: return decodeNum(from)
    }
  }

  public func asJSON() -> Result<JSON,String> {
    return decode(startIndex).map { (j,_) in j }
  }
}

extension String {
  public func asJSON() -> Result<JSON,String> {
    return Array(utf8).decode(0).map { (j,_) in j }
  }
}