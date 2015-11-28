func uChr(n: UInt8) -> Character { return Character(UnicodeScalar(n)) }
func uStr(s: [UInt8]) -> String { return String(s.lazy.map(uChr)) }

extension GeneratorType where Element == UInt8 {
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
    let desc = soFar
      .map { i in String(String(i).characters.prefix(5)) + "..."}
      .joinWithSeparator("\n    ")
    return JSONError.NoClosingDelimArray(
      soFar: "\n    " + desc,
      found: uStr(peek(5)))
  }
  private mutating func closingDelim(soFar: [String:JSON]) -> JSONError {
    let desc = soFar
      .map { (k,_) in k + ": ..."}
      .joinWithSeparator("\n    ")
    return JSONError.NoClosingDelimObject(
      soFar: "\n    " + desc,
      found: uStr(peek(5))
    )
  }
}

extension GeneratorType where Element == UInt8 {
  
  private mutating func decodeNull() -> Result<JSON,JSONError> {
    guard next() == Code.u else { return .None(error(lit: "null")) }
    guard next() == Code.l else { return .None(error(lit: "null")) }
    guard next() == Code.l else { return .None(error(lit: "null")) }
    return .Some(JSON.null)
  }
  
  private mutating func decodeTrue() -> Result<JSON,JSONError> {
    guard next() == Code.r else { return .None(error(lit: "true")) }
    guard next() == Code.u else { return .None(error(lit: "true")) }
    guard next() == Code.e else { return .None(error(lit: "true")) }
    return .Some(JSON.JBool(true))
  }
  
  private mutating func decodeFalse() -> Result<JSON,JSONError> {
    guard next() == Code.a else { return .None(error(lit: "false")) }
    guard next() == Code.l else { return .None(error(lit: "false")) }
    guard next() == Code.s else { return .None(error(lit: "false")) }
    guard next() == Code.e else { return .None(error(lit: "false")) }
    return .Some(JSON.JBool(false))
  }
  
  private mutating func decodeNum(n: UInt8) -> Result<JSON,JSONError> {
    var isDouble = false
    var arr: [UInt8] = [n]
    while let i = next() {
      switch i {
      case Code.e, Code.E, Code.fullst:
        isDouble = true
        fallthrough
      case Code.Zero...Code.Nine, Code.plus, Code.hyphen: arr.append(i)
      default:
        if let n = isDouble ?
          Double(uStr(arr)).map(JSON.JFloat) :
          Int(uStr(arr)).map(JSON.JInt) {
            return .Some(n)
        }
        return .None(numError(arr))
      }
    }
    return .None(numError(arr))
  }
  
  private mutating func decodeString() -> Result<String,JSONError> {
    var res = ""
    while let n = next() {
      switch n {
      case Code.quot: return .Some(res)
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
    case Code.b?     : return .Some("\u{8}")
    case Code.f?     : return .Some("\u{12}")
    case Code.n?     : return .Some("\n")
    case Code.r?     : return .Some("\r")
    case Code.t?     : return .Some("\t")
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
  
  private mutating func skipMany(sep: UInt8) -> Result<UInt8,JSONError> {
    while let i = next() {
      switch i {
      case Code.space, Code.tab, Code.ret, Code.newlin, sep: continue
      default: return .Some(i)
      }
    }
    return .None(.NoDivider(expecting: String(uChr(sep)), found: ""))
  }
  
  private mutating func decodeArr() -> Result<JSON,JSONError> {
    var res: [JSON] = []
    while let i = skipMany(Code.comma) {
      if i == Code.squarC { return .Some(.JArray(res)) }
      switch decode(i) {
      case let a?: res.append(a)
      case let .None(e): return .None(e)
      }
    }
    return .None(closingDelim(res))
  }
  
  private mutating func decodeObj() -> Result<JSON,JSONError> {
    var res: [String:JSON] = [:]
    while let i = skipMany(Code.comma) {
      if i == Code.curliC { return .Some(.JObject(res)) }
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
    case Code.squarO: return decodeArr()
    case Code.curliO: return decodeObj()
    case Code.quot  : return decodeString().map(JSON.JString)
    case Code.n     : return decodeNull()
    case Code.t     : return decodeTrue()
    case Code.f     : return decodeFalse()
    default         : return decodeNum(i)
    }
  }
  
  public mutating func asJSON() -> Result<JSON,JSONError> {
    guard let i = next() else { return .None(.Empty) }
    return decode(i)
  }
}

extension String {
  public func asJSON() -> Result<JSON,JSONError> {
    var g = utf8.generate()
    return g.asJSON()
  }
}