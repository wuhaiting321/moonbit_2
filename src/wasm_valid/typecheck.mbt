// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Value stack entry for type checking (using symbolic types)
pub(all) enum StackVal {
  Known(@wasm_type.ValType)
  Unknown
} derive(Debug, Eq)

///|
/// Check if a stack value matches expected type
pub fn stack_val_matches(
  expected : @wasm_type.ValType,
  actual : StackVal,
) -> Bool {
  match actual {
    Known(vt) => vt == expected
    Unknown => true
  }
}

///|
/// Control frame for tracking block structure
pub(all) struct ControlFrame {
  opcode : @wasm_bytecode.Opcode
  start_types : Array[@wasm_type.ValType]
  end_types : Array[@wasm_type.ValType]
  stack_height : Int
  mut is_unreachable : Bool
} derive(Debug)

///|
/// Type checking context for function body validation
pub(all) struct TypeChecker {
  mut stack : Array[StackVal]
  mut control_stack : Array[ControlFrame]
  func_types : Array[@wasm_type.FuncType]
  local_types : Array[@wasm_type.ValType]
  num_imports : UInt
  num_funcs : UInt
  num_globals : UInt
  num_memories : UInt
  num_tables : UInt
} derive(Debug)

///|
/// Create a new type checker for a function body
pub fn TypeChecker::new(
  func_types : Array[@wasm_type.FuncType],
  local_types : Array[@wasm_type.ValType],
  num_imports : UInt,
  num_funcs : UInt,
  num_globals : UInt,
  num_memories : UInt,
  num_tables : UInt,
) -> TypeChecker {
  {
    stack: [],
    control_stack: [],
    func_types,
    local_types,
    num_imports,
    num_funcs,
    num_globals,
    num_memories,
    num_tables,
  }
}

///|
/// Push a value onto the type stack
pub fn TypeChecker::push(self : TypeChecker, val : StackVal) -> Unit {
  self.stack.push(val)
}

///|
/// Pop a value from the type stack
pub fn TypeChecker::pop(
  self : TypeChecker,
) -> StackVal raise ValidError {
  let current_frame = self.current_frame()
  match current_frame {
    Some(frame) => {
      if self.stack.length() <= frame.stack_height && !frame.is_unreachable {
        raise StackUnderflow(offset=0, opcode="pop")
      }
    }
    None => {
      if self.stack.length() == 0 {
        raise StackUnderflow(offset=0, opcode="pop")
      }
    }
  }
  if self.stack.length() == 0 {
    Unknown
  } else {
    match self.stack.pop() {
      Some(v) => v
      None => Unknown
    }
  }
}

///|
/// Pop and verify expected type
pub fn TypeChecker::pop_expect(
  self : TypeChecker,
  expected : @wasm_type.ValType,
  offset : Int,
) -> Unit raise ValidError {
  let actual = self.pop()
  if !stack_val_matches(expected, actual) {
    let actual_str = match actual {
      Known(vt) => vt.to_string()
      Unknown => "unknown"
    }
    raise TypeMismatch(
      expected=expected.to_string(),
      got=actual_str,
      offset~,
    )
  }
}

///|
/// Get current control frame
pub fn TypeChecker::current_frame(self : TypeChecker) -> ControlFrame? {
  if self.control_stack.length() == 0 {
    None
  } else {
    Some(self.control_stack[self.control_stack.length() - 1])
  }
}

///|
/// Push a control frame
pub fn TypeChecker::push_frame(
  self : TypeChecker,
  opcode : @wasm_bytecode.Opcode,
  start_types : Array[@wasm_type.ValType],
  end_types : Array[@wasm_type.ValType],
) -> Unit {
  self.control_stack.push({
    opcode,
    start_types,
    end_types,
    stack_height: self.stack.length(),
    is_unreachable: false,
  })
}

///|
/// Pop a control frame
pub fn TypeChecker::pop_frame(self : TypeChecker) -> ControlFrame raise ValidError {
  if self.control_stack.length() == 0 {
    raise UnmatchedControl(offset=0)
  }
  match self.control_stack.pop() {
    Some(f) => f
    None => raise UnmatchedControl(offset=0)
  }
}

///|
/// Get label type at given depth
pub fn ControlFrame::label_types(
  self : ControlFrame,
) -> Array[@wasm_type.ValType] {
  match self.opcode {
    @wasm_bytecode.Loop => self.start_types
    _ => self.end_types
  }
}

///|
/// Mark current frame as unreachable (for unconditional branches)
pub fn TypeChecker::mark_unreachable(self : TypeChecker) -> Unit {
  match self.current_frame() {
    Some(frame) => {
      // Trim stack to frame height
      while self.stack.length() > frame.stack_height {
        let _ = self.stack.pop()
      }
      frame.is_unreachable = true
    }
    None => ()
  }
}

///|
/// Validate a function index
pub fn TypeChecker::check_func_index(
  self : TypeChecker,
  index : UInt,
) -> Unit raise ValidError {
  let total = self.num_imports + self.num_funcs
  if index >= total {
    raise InvalidFuncIndex(index~, max=total)
  }
}

///|
/// Validate a global index
pub fn TypeChecker::check_global_index(
  self : TypeChecker,
  index : UInt,
) -> Unit raise ValidError {
  if index >= self.num_globals {
    raise InvalidGlobalIndex(index~, max=self.num_globals)
  }
}

///|
/// Validate a local index
pub fn TypeChecker::check_local_index(
  self : TypeChecker,
  index : UInt,
) -> Unit raise ValidError {
  let total = self.local_types.length().reinterpret_as_uint()
  if index >= total {
    raise InvalidLocalIndex(index~, max=total)
  }
}

///|
/// Validate a label index
pub fn TypeChecker::check_label_index(
  self : TypeChecker,
  index : UInt,
) -> Unit raise ValidError {
  let depth = self.control_stack.length().reinterpret_as_uint()
  if index >= depth {
    raise InvalidLabelIndex(index~, depth~)
  }
}
