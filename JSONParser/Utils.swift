prefix operator ! {}
public prefix func !<T>(f: T -> Bool) -> T -> Bool {
  return {!f($0)}
}