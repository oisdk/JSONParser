extension CollectionType where Index : BidirectionalIndexType {
  internal func lastIndexOfNot
    (@noescape isNotElement: Generator.Element throws -> Bool)
    rethrows -> Index? {
    for i in indices.reverse()
      where (try !isNotElement(self[i])) {
        return i
    }
    return nil
  }
}

extension CollectionType {
  internal func indexOfNot
    (@noescape isNotElement: Generator.Element throws -> Bool)
    rethrows -> Index? {
    for i in indices
      where (try !isNotElement(self[i])) {
        return i
    }
    return nil
  }
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
    return indexOfNot { o in o == e }
  }
  internal func divide(e: Generator.Element) -> (SubSequence,SubSequence)? {
    return divide { o in o == e }
  }
}

extension CollectionType where
  Index : BidirectionalIndexType, Generator.Element : Equatable {
  internal func lastIndexOfNot(e: Generator.Element) -> Index? {
    return lastIndexOfNot { o in o == e }
  }
}