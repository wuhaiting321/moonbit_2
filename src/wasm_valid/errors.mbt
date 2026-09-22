// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Validation error types
pub suberror ValidError {
  InvalidFuncIndex(index~ : UInt, max~ : UInt)
  InvalidGlobalIndex(index~ : UInt, max~ : UInt)
  InvalidLocalIndex(index~ : UInt, max~ : UInt)
  InvalidLabelIndex(index~ : UInt, depth~ : UInt)
  TypeMismatch(expected~ : String, got~ : String, offset~ : Int)
  StackUnderflow(offset~ : Int, opcode~ : String)
  UnmatchedControl(offset~ : Int)
} derive(Debug, Eq)

///|
/// Validation result with optional errors
pub(all) struct ValidResult {
  errors : Array[String]
  mut is_valid : Bool
} derive(Debug)

///|
/// Create a successful validation result
pub fn ValidResult::ok() -> ValidResult {
  { errors: [], is_valid: true, }
}

///|
/// Create a failed validation result with one error
pub fn ValidResult::fail(msg : String) -> ValidResult {
  { errors: [msg], is_valid: false, }
}

///|
/// Merge another result into this one
pub fn ValidResult::merge(self : ValidResult, other : ValidResult) -> Unit {
  for e in other.errors {
    self.errors.push(e)
  }
  if !other.is_valid {
    self.is_valid = false
  }
}
