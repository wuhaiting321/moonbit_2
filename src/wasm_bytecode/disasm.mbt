// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Disassemble a single instruction to WAT-style text
pub fn disassemble_instruction(inst : Instruction) -> String {
  let buf = StringBuilder()
  buf.write_string(inst.opcode.to_string())

  match inst.opcode {
    Block | Loop | If =>
      match inst.block_type {
        Some(bt) =>
          match bt {
            @wasm_type.Empty => ()
            @wasm_type.Value(vt) => {
              buf.write_string(" (result ")
              buf.write_string(vt.to_string())
              buf.write_string(")")
            }
            @wasm_type.TypeIndex(idx) => {
              buf.write_string(" (type ")
              buf.write_string(idx.to_string())
              buf.write_string(")")
            }
          }
        None => ()
      }
    Br | BrIf =>
      if inst.label_indices.length() > 0 {
        buf.write_string(" ")
        buf.write_string(inst.label_indices[0].to_string())
      }
    BrTable => {
      for idx in inst.label_indices {
        buf.write_string(" ")
        buf.write_string(idx.to_string())
      }
      match inst.default_target {
        Some(d) => {
          buf.write_string(" ")
          buf.write_string(d.to_string())
        }
        None => ()
      }
    }
    Call =>
      match inst.func_index {
        Some(idx) => {
          buf.write_string(" ")
          buf.write_string(idx.to_string())
        }
        None => ()
      }
    CallIndirect => {
      match inst.type_index {
        Some(idx) => {
          buf.write_string(" (type ")
          buf.write_string(idx.to_string())
          buf.write_string(")")
        }
        None => ()
      }
    }
    LocalGet | LocalSet | LocalTee =>
      match inst.local_index {
        Some(idx) => {
          buf.write_string(" ")
          buf.write_string(idx.to_string())
        }
        None => ()
      }
    GlobalGet | GlobalSet =>
      match inst.global_index {
        Some(idx) => {
          buf.write_string(" ")
          buf.write_string(idx.to_string())
        }
        None => ()
      }
    I32Load | I64Load | F32Load | F64Load | I32Store | I64Store | F32Store | F64Store =>
      match inst.mem_arg {
        Some(ma) => {
          if ma.offset != 0 {
            buf.write_string(" offset=")
            buf.write_string(ma.offset.to_string())
          }
          buf.write_string(" align=")
          let align_val : UInt = 1
          let mut shift = ma.align
          let mut computed_align = align_val
          while shift > 0 {
            computed_align = computed_align * 2
            shift = shift - 1
          }
          buf.write_string(computed_align.to_string())
        }
        None => ()
      }
    I32Const =>
      match inst.i32_imm {
        Some(v) => {
          buf.write_string(" ")
          buf.write_string(v.to_string())
        }
        None => ()
      }
    I64Const =>
      match inst.i64_imm {
        Some(v) => {
          buf.write_string(" ")
          buf.write_string(v.to_string())
        }
        None => ()
      }
    _ => ()
  }

  buf.to_string()
}

///|
/// Disassemble an entire function body into WAT-style text lines
pub fn disassemble_function(
  code : Bytes,
) -> Array[String] raise Error {
  let reader = @binary_reader.BinaryReader::new(code)
  let lines : Array[String] = []
  let mut depth = 0

  while reader.remaining() > 0 {
    let inst = decode_instruction(reader)

    // Decrease indent for end/else
    match inst.opcode {
      End =>
        if depth > 0 {
          depth = depth - 1
        }
      Else => {
        if depth > 0 {
          depth = depth - 1
        }
      }
      _ => ()
    }

    let line_buf = StringBuilder()
    // Indent
    let mut indent = 0
    while indent < depth {
      line_buf.write_string("  ")
      indent = indent + 1
    }
    line_buf.write_string(disassemble_instruction(inst))
    lines.push(line_buf.to_string())

    // Increase indent for block starters
    match inst.opcode {
      Block | Loop | If | Else => depth = depth + 1
      _ => ()
    }
  }

  lines
}
