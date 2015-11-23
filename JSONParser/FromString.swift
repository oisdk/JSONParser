let wspace: Set<Character> = [" ", "\t", "\r", "\n"]
let wspccl: Set<Character> = [" ", "\t", "\r", "\n", ":"]
let wspccm: Set<Character> = [" ", "\t", "\r", "\n", ","]
let wspdlm: Set<Character> = [" ", "\t", "\r", "\n", "," ,"]", "}"]
let digs:   Set<Character> = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]

extension CollectionType where Generator.Element == Character, SubSequence.Generator.Element == Character {
  
  public func decodeAtom(var from: Index) -> Result<(JSON,Index),String> {
    switch self[from] {
    case "n", "N":
      if (self[++from] == "u" || self[from] == "U") &&
         (self[++from] == "l" || self[from] == "L") &&
         (self[++from] == "l" || self[from] == "L") {
          return Result<((JSON,Index)),String>.Some((JSON.null,++from))
      } else {
        return .None("Expecting null, found " + String(suffixFrom(from)))
      }
    case "t", "T":
      if (self[++from] == "r" || self[from] == "R") &&
         (self[++from] == "u" || self[from] == "U") &&
         (self[++from] == "e" || self[from] == "E") {
          return Result<((JSON,Index)),String>.Some((JSON.JBool(true),++from))
      } else {
        return .None("Expecting true, found " + String(suffixFrom(from)))
      }
    case "f", "F":
      if (self[++from] == "a" || self[from] == "A") &&
         (self[++from] == "l" || self[from] == "L") &&
         (self[++from] == "s" || self[from] == "S") &&
         (self[++from] == "e" || self[from] == "E") {
          return Result<((JSON,Index)),String>.Some((JSON.JBool(false),++from))
      } else {
        return .None("Expecting false, found " + String(suffixFrom(from)))
      }
    case let c where digs.contains(c):
      guard let i = indexOf(from.successor(), isElement: wspdlm.contains)
        else { return .None("Expecting delimiter, found " + String(suffixFrom(from))) }
      let str = String(self[from..<i])
      if let int = Int(str) {
        return Result<((JSON,Index)),String>.Some((JSON.JInt(int),i))
      } else if let flo = Double(str) {
        return Result<((JSON,Index)),String>.Some((JSON.JFloat(flo),i))
      }
      return .None("Expecting number, found " + String(suffixFrom(from)))
    default: return .None("Expecting literal, found " + String(suffixFrom(from)))
    }
  }
  
  public func decodeString(var from: Index) -> Result<(String,Index),String> {
    var res = ""
    while true {
      switch self[from++] {
      case "\"":
        return Result<((String,Index)),String>
          .Some((res,from))
      case "\\":
        guard let (a,b) = decodeEscaped(from)
          else { return .None(String(suffixFrom(from))) }
        res.append(a)
        from = b
      case let c: res.append(c)
      }
    }
  }
  
  func decodeEscaped(var from: Index) -> Result<(Character,Index),String> {
    switch self[from++] {
    case "\"": return Result<((Character,Index)),String>.Some(("\"",from))
    case "/" : return Result<((Character,Index)),String>.Some(("/",from))
    case "b" : return Result<((Character,Index)),String>.Some(("\u{8}",from))
    case "f" : return Result<((Character,Index)),String>.Some(("\u{12}",from))
    case "n" : return Result<((Character,Index)),String>.Some(("\n",from))
    case "r" : return Result<((Character,Index)),String>.Some(("\r",from))
    case "t" : return Result<((Character,Index)),String>.Some(("\t",from))
    case "u":
      let end = from.advancedBy(4)
      let str = String(self[from..<end])
      guard let usc = UInt32(str, radix: 16)
        else { return .None("Expecting unicode literal, found: " + str) }
      return Result<((Character,Index)),String>
        .Some((Character(UnicodeScalar(usc)),end))
    default: return .None(String(suffixFrom(from)))
    }
  }
  
  func decodeArr(var from: Index) -> Result<([JSON],Index),String> {
    var res: [JSON] = []
    while let i = indexOf(from, isElement: { c in !wspccm.contains(c) }) {
      if self[i] == "]" {
        return Result<(([JSON],Index)),String>.Some((res,i.successor()))
      }
      switch decode(i) {
      case let (j,x)?:
        res.append(j)
        from = x
      case let .None(s): return .None(s)
      }
    }
    return .None("Array not ended: " + String(suffixFrom(from)))
  }
  
  func decodeObj(var from: Index) -> Result<([String:JSON],Index),String> {
    var res: [String:JSON] = [:]
    while let i = indexOf(from, isElement: { c in !wspccm.contains(c) }) {
      if self[i] == "}" {
        return Result<(([String:JSON],Index)),String>.Some((res,i.successor()))
      }
      guard self[i] == "\"" else {
        return .None("Expecting beginning of dictionary key, found: " + String(suffixFrom(from)))
      }
      switch decodeString(i.successor()) {
      case let .None(s): return .None(s)
      case let .Some(key,ind):
        guard let valind = indexOf(ind, isElement: { c in !wspccl.contains(c) } )
          else { return .None("Expecting value in dictionary, found: " + String(suffixFrom(from))) }
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
    case "[": return decodeArr(i).map { (a,i) in (JSON.JArray(a),i) }
    case "{": return decodeObj(i).map { (o,i) in (JSON.JObject(o),i) }
    case "\"": return decodeString(i).map { (s,i) in (JSON.JString(s),i) }
    default: return decodeAtom(from)
    }
  }
  
  public func asJSON() -> Result<JSON,String> {
    return decode(startIndex).map { (j,_) in j }
  }
}

extension String {
  public func asJSON() -> Result<JSON,String> {
    return Array(characters).decode(0).map { (j,_) in j }
  }
}