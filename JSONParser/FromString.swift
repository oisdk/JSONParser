func uChr(n: UInt8) -> Character {
  return Character(UnicodeScalar(n))
}

func uStr<S : SequenceType where S.Generator.Element == UInt8>(s: S) -> String {
  return String(s.lazy.map(uChr))
}

extension PositionGenerator where Element == UInt8 {
  private mutating func error(lit lit: String) -> JSONError {
    return JSONError.Lit(expecting: lit, found: uStr(peek(5)))
  }
  private mutating func numError(soFar: [UInt8]) -> JSONError {
    return JSONError.Number(uStr(soFar) + uStr(peek(5)))
  }
  private mutating func closingDelim(soFar: String) -> JSONError {
    return JSONError.NoClosingDelimString(soFar: soFar, found: uStr(peek(5)))
  }
  private mutating func closingDelim(soFar: [JSON]) -> JSONError {
    return JSONError.NoClosingDelimArray(
      soFar: soFar
        .map { i in String(String(i).characters.prefix(5)) + "..."}
        .joinWithSeparator("\n"),
      found: uStr(peek(5)))
  }
  private mutating func closingDelim(soFar: [String:JSON]) -> JSONError {
    return JSONError.NoClosingDelimObject(
      soFar: soFar
        .map { (k,_) in k + ": ..."}
        .joinWithSeparator("\n"),
      found: uStr(peek(5))
    )
  }
}

extension PositionGenerator where Element == UInt8 {

  private mutating func decodeNull() -> Result<JSON,JSONError> {
    var n = next()
    if n != Code.u && n != Code.U { return .None(error(lit: "null")) }
    n = next()
    if n != Code.l && n != Code.L { return .None(error(lit: "null")) }
    n = next()
    if n != Code.l && n != Code.L { return .None(error(lit: "null")) }
    return Result<JSON,JSONError>.Some(JSON.null)
  }
  
  private mutating func decodeTrue() -> Result<JSON,JSONError> {
    var n = next()
    if n != Code.r && n != Code.R { return .None(error(lit: "true")) }
    n = next()
    if n != Code.u && n != Code.U { return .None(error(lit: "true")) }
    n = next()
    if n != Code.e && n != Code.E { return .None(error(lit: "true")) }
    return Result<JSON,JSONError>.Some(JSON.JBool(true))
  }
  
  private mutating func decodeFalse() -> Result<JSON,JSONError> {
    var n = next()
    if n != Code.a && n != Code.A { return .None(error(lit: "true")) }
    n = next()
    if n != Code.l && n != Code.L { return .None(error(lit: "true")) }
    n = next()
    if n != Code.s && n != Code.S { return .None(error(lit: "true")) }
    n = next()
    if n != Code.e && n != Code.E { return .None(error(lit: "true")) }
    n = next()
    return Result<JSON,JSONError>.Some(JSON.JBool(false))
  }
  
  private mutating func decodeNum(n: UInt8) -> Result<JSON,JSONError> {
    var isDouble = false
    var bytes: [UInt8] = [n]
    while let i = next() {
      switch i {
      case Code.e, Code.E, Code.fullst:
        isDouble = true
        fallthrough
      case Code.Zero...Code.Nine, Code.plus, Code.hyphen:
        bytes.append(i)
      default:
        let s = uStr(bytes)
        if let n = isDouble ? Double(s).map(JSON.JFloat) : Int(s).map(JSON.JInt) {
          return .Some(n)
        }
        return .None(numError(bytes))
      }
    }
    return .None(numError(bytes))
  }
  
  private mutating func decodeString() -> Result<String,JSONError> {
    var res = ""
    while let n = next() {
      switch n {
      case Code.quot:
        return Result<String,JSONError>.Some(res)
      case Code.bslash:
        switch decodeEscaped() {
        case let a?: res.appendContentsOf(a)
        case let .None(e): return .None(e)
        }
      case let c: res.append(Character(UnicodeScalar(c)))
      }
    }
    return .None(closingDelim(res))
  }
  
  private mutating func decodeEscaped() -> Result<String,JSONError> {
    switch next() {
    case Code.quot?  : return .Some("\"")
    case Code.fslash?: return .Some("/")
    case Code.b?: return .Some("\u{8}")
    case Code.f?: return .Some("\u{12}")
    case Code.n?: return .Some("\n")
    case Code.r?: return .Some("\r")
    case Code.t?: return .Some("\t")
    case Code.u?:
      guard let a = next(), b = next(), c = next(), d = next() else {
        fallthrough
      }
      guard let s = UInt32(uStr([a,b,c,d]), radix: 16)
        .map({String(Character(UnicodeScalar($0)))}) else {
          fallthrough
      }
      return .Some(s)
    default: return .None(error(lit: "Unicode"))
    }
  }
  
  private mutating func skipMany(sep: UInt8) -> UInt8? {
    while let i = next() {
      switch i {
      case Code.space, Code.tab, Code.ret, Code.newlin, sep: continue
      default: return i
      }
    }
    return nil
  }
  
  private mutating func decodeArr() -> Result<[JSON],JSONError> {
    var res: [JSON] = []
    while let i = skipMany(Code.comma) {
      if i == Code.squarC { return .Some(res) }
      switch decode(i) {
      case let a?: res.append(a)
      case let .None(e): return .None(e)
      }
    }
    return .None(closingDelim(res))
  }
  
  private mutating func decodeObj() -> Result<[String:JSON],JSONError> {
    var res: [String:JSON] = [:]
    while let i = skipMany(Code.comma) {
      if i == Code.curliC { return .Some(res) }
      let (key,val): (String,JSON)
      switch decodeString() {
      case let s?: key = s
      case let .None(e): return .None(e)
      }
      guard let i = skipMany(Code.colon) else {
        return .None(closingDelim(res))
      }
      switch decode(i) {
      case let v?: val = v
      case let .None(e): return .None(e)
      }
      res[key] = val
    }
    return .None(closingDelim(res))
  }

  private mutating func decode(i: UInt8) -> Result<JSON,JSONError> {
    switch i {
    case Code.squarO: return decodeArr().map(JSON.JArray)
    case Code.curliO: return decodeObj().map(JSON.JObject)
    case Code.quot: return decodeString().map(JSON.JString)
    case Code.n, Code.N: return decodeNull()
    case Code.t, Code.T: return decodeTrue()
    case Code.f, Code.F: return decodeFalse()
    default: return decodeNum(i)
    }
  }

  public mutating func asJSON() -> Result<JSON,JSONError> {
    guard let i = next() else { return .None(.Empty) }
    return decode(i)
  }
}

extension String {
  public func asJSON() -> Result<JSON,JSONError> {
    var g = InfoIndexingGenerator(utf8)
    return g.asJSON()
  }
}