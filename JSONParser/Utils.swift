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