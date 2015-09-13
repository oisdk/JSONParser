extension String.CharacterView {
  internal func trim(c: Character) -> String.CharacterView {
    guard let s = indexOfNot(c), e = lastIndexOfNot(c) else  { return "".characters }
    return self[s...e]
  }
  internal func trim(cs: Set<Character>) -> String.CharacterView {
    guard let s = indexOfNot(cs.contains), e = lastIndexOfNot(cs.contains)
      else  { return "".characters }
    return self[s...e]
  }
  internal func indexOfNonEscaped(@noescape isC: Character throws -> Bool)
    rethrows -> Index? {
    let e = endIndex.predecessor()
    for (var i = startIndex; i != e; ++i) {
      let c = self[i]
      if c == "\\" { ++i } else
      if try isC(c) { return i }
    }
    return try isC(self[e]) ? e : nil
  }
  internal func divideNonEscaped(@noescape isC: Character throws -> Bool)
    rethrows -> (String.CharacterView,String.CharacterView)? {
      guard let i = try indexOfNonEscaped(isC) else { return nil }
      return (prefixUpTo(i),suffixFrom(i.successor()))
  }
}