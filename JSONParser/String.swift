extension String.CharacterView {
  internal func trim(c: Character) -> String.CharacterView {
    guard let s = indexOfNot(c), e = lastIndexOfNot(c) else  { return "".characters }
    return self[s...e]
  }
  internal func trim(cs: Set<Character>) -> String.CharacterView {
    guard let s = indexOfNot(cs.contains), e = lastIndexOfNot(cs.contains) else  { return "".characters }
    return self[s...e]
  }
  internal func trim(c0: Character, _ c1: Character, _ rest: Character...) -> String.CharacterView {
    return trim(Set([c0, c1] + rest))
  }
}