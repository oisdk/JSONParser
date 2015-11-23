func notWspccl(n: UInt8) -> Bool {
  switch n {
  case Code.space, Code.tab, Code.ret, Code.newlin, Code.colon: return false
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
  
  private func decodeAtom(var from: Index) -> Result<(JSON,Index),String> {
    switch self[from] {
    case Code.n, Code.N:
      if (self[++from] == Code.u || self[from] == Code.U) &&
         (self[++from] == Code.l || self[from] == Code.L) &&
         (self[++from] == Code.l || self[from] == Code.L) {
          return Result<((JSON,Index)),String>.Some((JSON.null,from.successor()))
      }
      return .None("Expecting null, found " + uStr(suffixFrom(from)))
    case Code.t, Code.T:
      if (self[++from] == Code.r || self[from] == Code.R) &&
         (self[++from] == Code.u || self[from] == Code.U) &&
         (self[++from] == Code.e || self[from] == Code.E) {
          return Result<((JSON,Index)),String>.Some((JSON.JBool(true),from.successor()))
      }
      return .None("Expecting true, found " + uStr(suffixFrom(from)))
    case Code.f, Code.F:
      if (self[++from] == Code.a || self[from] == Code.A) &&
         (self[++from] == Code.l || self[from] == Code.L) &&
         (self[++from] == Code.s || self[from] == Code.S) &&
         (self[++from] == Code.e || self[from] == Code.E) {
          return Result<((JSON,Index)),String>.Some((JSON.JBool(false),from.successor()))
      }
      return .None("Expecting false, found " + uStr(suffixFrom(from)))
    default:
      var isDouble = false
      for i in from..<endIndex {
        switch self[i] {
        case Code.Zero...Code.Nine: continue
        case Code.e, Code.E: isDouble = true
        case Code.fullst: isDouble = true
        case Code.plus, Code.hyphen: continue
        default:
          let s = uStr(self[from..<i])
          if isDouble {
            guard let d = Double(s)
              else { return .None("Expecting floating-point number, found: " + s) }
            return Result<((JSON,Index)),String>.Some((JSON.JFloat(d),i))
          }
          guard let n = Int(s)
            else { return .None("Expecting integer, found: " + s) }
          return Result<((JSON,Index)),String>.Some((JSON.JInt(n),i))
        }
      }
      return .None("Unexpected eof when parsing number")
    }
  }
  
  private func decodeString(var from: Index) -> Result<(String,Index),String> {
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
      guard let usc = UInt32(str, radix: 16)
        else { return .None("Expecting unicode literal, found: " + str) }
      return Result<((Character,Index)),String>
        .Some((Character(UnicodeScalar(usc)),end))
    default: return .None(uStr(suffixFrom(from)))
    }
  }
  
  private func decodeArr(var from: Index) -> Result<([JSON],Index),String> {
    var res: [JSON] = []
    while from != endIndex {
      switch self[from] {
      case Code.squarC:
        return Result<(([JSON],Index)),String>.Some((res,from.successor()))
      case Code.space, Code.tab, Code.ret, Code.newlin, Code.comma:
        ++from
      default:
        switch decode(from) {
        case let (j,x)?:
          res.append(j)
          from = x
        case let .None(s): return .None(s)
        }
      }
    }
    return .None("Array not ended: " + uStr(suffixFrom(from)))
  }
  
  private func decodeObj(var from: Index) -> Result<([String:JSON],Index),String> {
    var res: [String:JSON] = [:]
    while from != endIndex {
      switch self[from++] {
      case Code.curliC:
        return Result<(([String:JSON],Index)),String>.Some((res,from))
      case Code.quot:
        switch decodeString(from) {
        case let .None(s): return .None(s)
        case let .Some(key,ind):
          guard let valind = indexOf(ind, isElement: notWspccl)
            else { return .None("Expecting value in dictionary, found: " + uStr(suffixFrom(from))) }
          switch decode(valind) {
          case let .None(s): return .None(s)
          case let (val,rind)?:
            res[key] = val
            from = rind
          }
        }
      default: continue
      }
    }
    return .None("Object not ended: " + String(suffixFrom(from)))
  }
  
  private func decode(from: Index) -> Result<(JSON,Index),String> {
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