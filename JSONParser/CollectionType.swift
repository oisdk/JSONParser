extension CollectionType where Index : BidirectionalIndexType {
  internal func lastIndexOfNot(@noescape isNotElement: Generator.Element throws -> Bool) rethrows -> Index? {
    for i in indices.reverse()
      where (try !isNotElement(self[i])) {
        return i
    }
    return nil
  }
}

extension CollectionType {
  internal func indexOfNot(@noescape isNotElement: Generator.Element throws -> Bool) rethrows -> Index? {
    for i in indices
      where (try !isNotElement(self[i])) {
        return i
    }
    return nil
  }
}

extension CollectionType where Generator.Element : Equatable {
  internal func indexOfNot(e: Generator.Element) -> Index? {
    return indexOfNot { o in o == e }
  }
}

extension CollectionType where Index : BidirectionalIndexType, Generator.Element : Equatable {
  internal func lastIndexOfNot(e: Generator.Element) -> Index? {
    return lastIndexOfNot { o in o == e }
  }
}