extension GeneratorType {
  mutating func peek(length: Int) -> [Element] {
    var res: [Element] = []
    for _ in 0..<length {
      guard let y = next() else { break }
      res.append(y)
    }
    return res
  }
}