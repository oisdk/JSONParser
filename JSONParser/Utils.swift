extension CollectionType {
  func indexOf(from: Index, @noescape isElement: Generator.Element -> Bool) -> Index? {
    for i in from..<endIndex {
      if isElement(self[i]) {
        return i
      }
    }
    return nil
  }
}

extension SequenceType where Generator.Element : Equatable {
  func count(e: Generator.Element) -> Int {
    var res = 0
    for x in self where x == e { ++res }
    return res
  }
}