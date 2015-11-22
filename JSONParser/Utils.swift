prefix operator ! {}
public prefix func !<T>(f: T -> Bool) -> T -> Bool {
  return {!f($0)}
}

public func ~=<T>(lhs: T -> Bool, rhs: T) -> Bool {
  return lhs(rhs)
}