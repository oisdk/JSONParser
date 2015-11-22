extension CollectionType where Generator.Element : Equatable, Index : BidirectionalIndexType {
  internal func trim(c: Generator.Element) -> SubSequence? {
    guard let s = indexOfNot(c), e = lastIndexOfNot(c) else  { return nil }
    return self[s...e]
  }
}

extension CollectionType where Generator.Element : Hashable, Index : BidirectionalIndexType {
  internal func trim(cs: Set<Generator.Element>) -> SubSequence? {
    guard let s = indexOf(!cs.contains), e = lastIndexOf(!cs.contains)
      else  { return nil }
    return self[s...e]
  }
}

extension CollectionType where Generator.Element : Equatable {
  internal func indexOfNonEscaped(esc: Generator.Element, @noescape isC: Generator.Element throws -> Bool)
    rethrows -> Index? {
      for (var i = startIndex; i != endIndex; ++i) {
        let c = self[i]
        if c == esc && ++i == endIndex { break }
        else if try isC(c) { return i }
      }
      return nil
  }
}

extension CollectionType where Generator.Element : Equatable {
  internal func divideNonEscaped(esc: Generator.Element, @noescape isC: Generator.Element throws -> Bool)
    rethrows -> (SubSequence,SubSequence)? {
      guard let i = try indexOfNonEscaped(esc, isC: isC) else { return nil }
      return (prefixUpTo(i),suffixFrom(i.successor()))
  }
}

extension CollectionType where Index : BidirectionalIndexType {
  internal func lastIndexOf
    (@noescape isElement: Generator.Element throws -> Bool)
    rethrows -> Index? {
    for i in indices.reverse()
      where (try isElement(self[i])) {
        return i
    }
    return nil
  }
}

extension CollectionType {
  internal func divide
    (@noescape isElement: Generator.Element throws -> Bool)
    rethrows -> (SubSequence,SubSequence)? {
      for i in indices where try isElement(self[i]) {
        return (prefixUpTo(i), suffixFrom(i.successor()))
      }
      return nil
  }
}

extension CollectionType where Generator.Element : Equatable {
  internal func indexOfNot(e: Generator.Element) -> Index? {
    return indexOf(!{ o in o == e })
  }
  internal func divide(e: Generator.Element) -> (SubSequence,SubSequence)? {
    return divide { o in o == e }
  }
}

extension CollectionType where
  Index : BidirectionalIndexType, Generator.Element : Equatable {
  internal func lastIndexOfNot(e: Generator.Element) -> Index? {
    return lastIndexOf(!{ o in o == e })
  }
}