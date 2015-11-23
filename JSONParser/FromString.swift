let wspace: Set<UInt8> = [Code.space, Code.tab, Code.ret, Code.newlin]              // [" ", "\t", "\r", "\n"]
let wspccl: Set<UInt8> = [Code.space, Code.tab, Code.ret, Code.newlin, Code.colon]          // [" ", "\t", "\r", "\n", ":"]
let wspccm: Set<UInt8> = [Code.space, Code.tab, Code.ret, Code.newlin, Code.comma]          // [" ", "\t", "\r", "\n", ","]
let wspdlm: Set<UInt8> = [Code.space, Code.tab, Code.ret, Code.newlin, Code.comma, Code.squarC, Code.curliC] // [" ", "\t", "\r", "\n", "," ,"]", "}"]
let digs:   Set<UInt8> = [48, 49, 50, 51, 52, 53, 54, 55, 56, 57]

func notWspccm(n: UInt8) -> Bool {
  switch n {
  case Code.space, Code.tab, Code.ret, Code.newlin, Code.comma: return false
  default: return true
  }
}

func uChr(n: UInt8) -> Character {
  return Character(UnicodeScalar(n))
}

func uStr<S : SequenceType where S.Generator.Element == UInt8>(s: S) -> String {
  return String(s.lazy.map(uChr))
}

extension CollectionType where Generator.Element == UInt8, SubSequence.Generator.Element == UInt8 {
  
  public func decodeAtom(var from: Index) -> Result<(JSON,Index),String> {
    switch self[from] {
    case Code.n, Code.N: // 'n", "N"
      if (self[++from] == Code.u || self[from] == Code.U) && // "u", "U"
         (self[++from] == Code.l || self[from] == Code.L) && // "l", "L"
         (self[++from] == Code.l || self[from] == Code.L) {  // "l", "L"
          return Result<((JSON,Index)),String>.Some((JSON.null,++from))
      }
      return .None("Expecting null, found " + uStr(suffixFrom(from)))
    case Code.t, Code.T: // "t", "T"
      if (self[++from] == Code.r || self[from] == Code.R) && // "r", "R"
         (self[++from] == Code.u || self[from] == Code.U) && // "u", "U"
         (self[++from] == Code.e || self[from] == Code.E) {  // "e", "E"
          return Result<((JSON,Index)),String>.Some((JSON.JBool(true),++from))
      }
      return .None("Expecting true, found " + uStr(suffixFrom(from)))
    case Code.f, Code.F: // f, F
      if (self[++from] == Code.a || self[from] == Code.A) &&  // "a", "A"
         (self[++from] == Code.l || self[from] == Code.L) && // "l", "L"
         (self[++from] == Code.s || self[from] == Code.S) && // "s", "S"
         (self[++from] == Code.e || self[from] == Code.E) {  // "e", "E"
          return Result<((JSON,Index)),String>.Some((JSON.JBool(false),++from))
      }
      return .None("Expecting false, found " + uStr(suffixFrom(from)))
    case let c where digs.contains(c):
      guard let i = indexOf(from.successor(), isElement: wspdlm.contains)
        else { return .None("Expecting delimiter, found " + uStr(suffixFrom(from))) }
      let str = uStr(self[from..<i])
      if let int = Int(str) {
        return Result<((JSON,Index)),String>.Some((JSON.JInt(int),i))
      } else if let flo = Double(str) {
        return Result<((JSON,Index)),String>.Some((JSON.JFloat(flo),i))
      }
      return .None("Expecting number, found " + uStr(suffixFrom(from)))
    default: return .None("Expecting literal, found " + uStr(suffixFrom(from)))
    }
  }
  
  public func decodeString(var from: Index) -> Result<(String,Index),String> {
    var res = ""
    while true {
      switch self[from++] {
      case Code.quot:
        return Result<((String,Index)),String>
          .Some((res,from))
      case Code.bslash:
        guard let (a,b) = decodeEscaped(from)
          else { return .None(uStr(suffixFrom(from))) }
        res.append(a)
        from = b
      case let c: res.append(uChr(c))
      }
    }
  }
  
  func decodeEscaped(var from: Index) -> Result<(Character,Index),String> {
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
      guard let usc = UInt32(str, radix: 16)
        else { return .None("Expecting unicode literal, found: " + str) }
      return Result<((Character,Index)),String>
        .Some((Character(UnicodeScalar(usc)),end))
    default: return .None(uStr(suffixFrom(from)))
    }
  }
  
  func decodeArr(var from: Index) -> Result<([JSON],Index),String> {
    var res: [JSON] = []
    while let i = indexOf(from, isElement: notWspccm) {
      if self[i] == Code.squarC {
        return Result<(([JSON],Index)),String>.Some((res,i.successor()))
      }
      switch decode(i) {
      case let (j,x)?:
        res.append(j)
        from = x
      case let .None(s): return .None(s)
      }
    }
    return .None("Array not ended: " + uStr(suffixFrom(from)))
  }
  
  func decodeObj(var from: Index) -> Result<([String:JSON],Index),String> {
    var res: [String:JSON] = [:]
    while let i = indexOf(from, isElement: notWspccm) {
      if self[i] == Code.curliC {
        return Result<(([String:JSON],Index)),String>.Some((res,i.successor()))
      }
      guard self[i] == Code.quot else {
        return .None("Expecting beginning of dictionary key, found: " + uStr(suffixFrom(from)))
      }
      switch decodeString(i.successor()) {
      case let .None(s): return .None(s)
      case let .Some(key,ind):
        guard let valind = indexOf(ind, isElement: { c in !wspccl.contains(c) } )
          else { return .None("Expecting value in dictionary, found: " + uStr(suffixFrom(from))) }
        switch decode(valind) {
        case let .None(s): return .None(s)
        case let (val,rind)?:
          res[key] = val
          from = rind
        }
      }
    }
    return .None("Object not ended: " + String(suffixFrom(from)))
  }
  
  func decode(from: Index) -> Result<(JSON,Index),String> {
    let i = from.successor()
    switch self[from] {
    case Code.squarO: return decodeArr(i).map { (a,i) in (JSON.JArray(a),i) }
    case Code.curliO: return decodeObj(i).map { (o,i) in (JSON.JObject(o),i) }
    case Code.quot  : return decodeString(i).map { (s,i) in (JSON.JString(s),i) }
    default : return decodeAtom(from)
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