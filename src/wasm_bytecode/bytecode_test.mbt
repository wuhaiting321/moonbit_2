// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
test "decode_unreachable" {
  let r = @binary_reader.BinaryReader::new(b"\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="unreachable")
}

///|
test "decode_nop" {
  let r = @binary_reader.BinaryReader::new(b"\x01")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="nop")
}

///|
test "decode_i32_const" {
  // i32.const 42 (LEB128: 0x2A)
  let r = @binary_reader.BinaryReader::new(b"\x41\x2A")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="i32.const")
  match inst.i32_imm {
    Some(v) => inspect(v, content="42")
    None => inspect("missing_imm", content="unexpected")
  }
}

///|
test "decode_i32_const_negative" {
  // i32.const -1 (LEB128: 0x7F)
  let r = @binary_reader.BinaryReader::new(b"\x41\x7F")
  let inst = decode_instruction(r)
  match inst.i32_imm {
    Some(v) => inspect(v, content="-1")
    None => inspect("missing_imm", content="unexpected")
  }
}

///|
test "decode_i64_const" {
  // i64.const 100 (signed LEB128: 0xE4 0x00 to avoid sign extension)
  let r = @binary_reader.BinaryReader::new(b"\x42\xE4\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="i64.const")
  match inst.i64_imm {
    Some(v) => inspect(v, content="100")
    None => inspect("missing_imm", content="unexpected")
  }
}

///|
test "decode_local_get" {
  // local.get 0 (LEB128: 0x00)
  let r = @binary_reader.BinaryReader::new(b"\x20\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="local.get")
  match inst.local_index {
    Some(idx) => inspect(idx, content="0")
    None => inspect("missing_idx", content="unexpected")
  }
}

///|
test "decode_call" {
  // call 3 (LEB128: 0x03)
  let r = @binary_reader.BinaryReader::new(b"\x10\x03")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="call")
  match inst.func_index {
    Some(idx) => inspect(idx, content="3")
    None => inspect("missing_idx", content="unexpected")
  }
}

///|
test "decode_block_empty" {
  // block (empty) end
  let r = @binary_reader.BinaryReader::new(b"\x02\x40\x0B")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="block")
  match inst.block_type {
    Some(@wasm_type.Empty) => inspect(true, content="true")
    _ => inspect("wrong_bt", content="unexpected")
  }
}

///|
test "decode_i32_add" {
  let r = @binary_reader.BinaryReader::new(b"\x6A")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="i32.add")
}

///|
test "decode_br" {
  // br 0
  let r = @binary_reader.BinaryReader::new(b"\x0C\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="br")
  inspect(inst.label_indices.length(), content="1")
  inspect(inst.label_indices[0], content="0")
}

///|
test "disassemble_i32_add_sequence" {
  // local.get 0, local.get 1, i32.add, end
  let code : Bytes = b"\x20\x00\x20\x01\x6A\x0B"
  let lines = disassemble_function(code)
  inspect(lines.length(), content="4")
  inspect(lines[0], content="local.get 0")
  inspect(lines[1], content="local.get 1")
  inspect(lines[2], content="i32.add")
  inspect(lines[3], content="end")
}

///|
test "disassemble_block_indentation" {
  // block (empty) nop end end
  let code : Bytes = b"\x02\x40\x01\x0B\x0B"
  let lines = disassemble_function(code)
  inspect(lines.length(), content="4")
  inspect(lines[0], content="block")
  inspect(lines[1], content="  nop")
  inspect(lines[2], content="end")
  inspect(lines[3], content="end")
}

///|
test "disassemble_i32_const_text" {
  let code : Bytes = b"\x41\x2A\x0B"
  let lines = disassemble_function(code)
  inspect(lines.length(), content="2")
  inspect(lines[0], content="i32.const 42")
}

///|
test "decode_i32_load_with_memarg" {
  // i32.load align=2 offset=0
  let r = @binary_reader.BinaryReader::new(b"\x28\x02\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="i32.load")
  match inst.mem_arg {
    Some(ma) => {
      inspect(ma.align, content="2")
      inspect(ma.offset, content="0")
    }
    None => inspect("missing_memarg", content="unexpected")
  }
}

///|
test "decode_global_get" {
  // global.get 1
  let r = @binary_reader.BinaryReader::new(b"\x23\x01")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="global.get")
  match inst.global_index {
    Some(idx) => inspect(idx, content="1")
    None => inspect("missing_idx", content="unexpected")
  }
}

///|
test "decode_f32_const" {
  // f32.const followed by 4 bytes LE (e.g. 1.0f = 0x3F800000)
  let r = @binary_reader.BinaryReader::new(b"\x43\x00\x00\x80\x3F")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="f32.const")
  match inst.f32_imm {
    Some(bits) => inspect(bits, content="1065353216")
    None => inspect("missing_imm", content="unexpected")
  }
}

///|
test "decode_f64_const" {
  // f64.const followed by 8 bytes LE (e.g. 1.0 = 0x3FF0000000000000)
  let r = @binary_reader.BinaryReader::new(
    b"\x44\x00\x00\x00\x00\x00\x00\xF0\x3F",
  )
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="f64.const")
  match inst.f64_imm {
    Some(bits) => inspect(bits, content="4607182418800017408")
    None => inspect("missing_imm", content="unexpected")
  }
}

///|
test "decode_br_table" {
  // br_table with 2 targets (1, 2) and default 0
  // 0x0E, count=2, targets=[1, 2], default=0
  let r = @binary_reader.BinaryReader::new(b"\x0E\x02\x01\x02\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="br_table")
  inspect(inst.label_indices.length(), content="2")
  inspect(inst.label_indices[0], content="1")
  inspect(inst.label_indices[1], content="2")
  match inst.default_target {
    Some(d) => inspect(d, content="0")
    None => inspect("missing_default", content="unexpected")
  }
}

///|
test "decode_call_indirect" {
  // call_indirect type_idx=3, table_idx=0
  let r = @binary_reader.BinaryReader::new(b"\x11\x03\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="call_indirect")
  match inst.type_index {
    Some(idx) => inspect(idx, content="3")
    None => inspect("missing_type", content="unexpected")
  }
}

///|
test "decode_memory_size" {
  // memory.size 0
  let r = @binary_reader.BinaryReader::new(b"\x3F\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="memory.size")
  match inst.mem_index {
    Some(idx) => inspect(idx, content="0")
    None => inspect("missing_mem", content="unexpected")
  }
}

///|
test "decode_memory_grow" {
  // memory.grow 0
  let r = @binary_reader.BinaryReader::new(b"\x40\x00")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="memory.grow")
  match inst.mem_index {
    Some(idx) => inspect(idx, content="0")
    None => inspect("missing_mem", content="unexpected")
  }
}

///|
test "decode_i32_load8_s" {
  // i32.load8_s align=0 offset=4 (opcode 0x30)
  let r = @binary_reader.BinaryReader::new(b"\x30\x00\x04")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="i32.load8_s")
  match inst.mem_arg {
    Some(ma) => {
      inspect(ma.align, content="0")
      inspect(ma.offset, content="4")
    }
    None => inspect("missing_memarg", content="unexpected")
  }
}

///|
test "decode_i64_store32" {
  // i64.store32 align=2 offset=8 (opcode 0x3E)
  let r = @binary_reader.BinaryReader::new(b"\x3E\x02\x08")
  let inst = decode_instruction(r)
  inspect(inst.opcode.to_string(), content="i64.store32")
  match inst.mem_arg {
    Some(ma) => {
      inspect(ma.align, content="2")
      inspect(ma.offset, content="8")
    }
    None => inspect("missing_memarg", content="unexpected")
  }
}

///|
test "disassemble_f32_const" {
  let code : Bytes = b"\x43\x00\x00\x80\x3F\x0B"
  let lines = disassemble_function(code)
  inspect(lines.length(), content="2")
  inspect(lines[0], content="f32.const 0x1065353216")
}

///|
test "disassemble_memory_size" {
  let code : Bytes = b"\x3F\x00\x0B"
  let lines = disassemble_function(code)
  inspect(lines.length(), content="2")
  inspect(lines[0], content="memory.size 0")
}
