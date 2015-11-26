public protocol PositionGenerator: GeneratorType {
  typealias Index: ForwardIndexType
  var i: Index { get }
}

public struct InfoIndexingGenerator<C : CollectionType>: PositionGenerator {
  private let c: C
  public var i: C.Index
  public mutating func next() -> C.Generator.Element? {
    return i == c.endIndex ? nil : c[i++]
  }
  public init(_ col: C) {
    c = col
    i = col.startIndex
  }
}

extension PositionGenerator {
  mutating func peek(length: Int) -> [Element] {
    var res: [Element] = []
    for _ in 0..<length {
      guard let y = next() else { break }
      res.append(y)
    }
    return res
  }
}