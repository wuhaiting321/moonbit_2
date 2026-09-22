// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
test "parse_val_type_i32" {
  let r = @binary_reader.BinaryReader::new(b"\x7F")
  let vt = parse_val_type(r)
  inspect(vt.to_string(), content="i32")
}

///|
test "parse_val_type_i64" {
  let r = @binary_reader.BinaryReader::new(b"\x7E")
  let vt = parse_val_type(r)
  inspect(vt.to_string(), content="i64")
}

///|
test "parse_val_type_f32" {
  let r = @binary_reader.BinaryReader::new(b"\x7D")
  let vt = parse_val_type(r)
  inspect(vt.to_string(), content="f32")
}

///|
test "parse_val_type_f64" {
  let r = @binary_reader.BinaryReader::new(b"\x7C")
  let vt = parse_val_type(r)
  inspect(vt.to_string(), content="f64")
}

///|
test "parse_val_type_funcref" {
  let r = @binary_reader.BinaryReader::new(b"\x70")
  let vt = parse_val_type(r)
  inspect(vt.to_string(), content="funcref")
}

///|
test "parse_val_type_externref" {
  let r = @binary_reader.BinaryReader::new(b"\x6F")
  let vt = parse_val_type(r)
  inspect(vt.to_string(), content="externref")
}

///|
test "parse_val_type_invalid" {
  let rejected = try {
    let r = @binary_reader.BinaryReader::new(b"\x00")
    let _ = parse_val_type(r)
    false
  } catch {
    _ => true
  } noraise {
    _ => false
  }
  inspect(rejected, content="true")
}

///|
test "parse_func_type_simple" {
  // func () -> ()
  let r = @binary_reader.BinaryReader::new(b"\x60\x00\x00")
  let ft = parse_func_type(r)
  inspect(ft.params.length(), content="0")
  inspect(ft.results.length(), content="0")
}

///|
test "parse_func_type_with_params_and_results" {
  // func (i32, i64) -> (f64)
  let r = @binary_reader.BinaryReader::new(b"\x60\x02\x7F\x7E\x01\x7C")
  let ft = parse_func_type(r)
  inspect(ft.params.length(), content="2")
  inspect(ft.results.length(), content="1")
  inspect(ft.params[0].to_string(), content="i32")
  inspect(ft.params[1].to_string(), content="i64")
  inspect(ft.results[0].to_string(), content="f64")
}

///|
test "func_type_to_string" {
  let ft : FuncType = {
    params: [I32, I64],
    results: [F64],
  }
  inspect(ft.to_string(), content="(func (param i32 i64) (result f64))")
}

///|
test "parse_limits_no_max" {
  let r = @binary_reader.BinaryReader::new(b"\x00\x01")
  let lim = parse_limits(r)
  inspect(lim.min, content="1")
  match lim.max {
    Some(_) => inspect("has_max", content="unexpected")
    None => inspect(true, content="true")
  }
}

///|
test "parse_limits_with_max" {
  let r = @binary_reader.BinaryReader::new(b"\x01\x01\x0A")
  let lim = parse_limits(r)
  inspect(lim.min, content="1")
  match lim.max {
    Some(m) => inspect(m, content="10")
    None => inspect("no_max", content="unexpected")
  }
}

///|
test "parse_global_type_immutable" {
  let r = @binary_reader.BinaryReader::new(b"\x7F\x00")
  let gt = parse_global_type(r)
  inspect(gt.val_type.to_string(), content="i32")
  inspect(gt.to_string(), content="i32")
}

///|
test "parse_global_type_mutable" {
  let r = @binary_reader.BinaryReader::new(b"\x7E\x01")
  let gt = parse_global_type(r)
  inspect(gt.val_type.to_string(), content="i64")
  inspect(gt.to_string(), content="(mut i64)")
}

///|
test "parse_table_type" {
  let r = @binary_reader.BinaryReader::new(b"\x70\x00\x0A")
  let tt = parse_table_type(r)
  inspect(tt.to_string(), content="10 funcref")
}

///|
test "parse_block_type_empty" {
  let r = @binary_reader.BinaryReader::new(b"\x40")
  let bt = parse_block_type(r)
  match bt {
    Empty => inspect(true, content="true")
    _ => inspect("not_empty", content="unexpected")
  }
}

///|
test "parse_block_type_value" {
  let r = @binary_reader.BinaryReader::new(b"\x7F")
  let bt = parse_block_type(r)
  match bt {
    Value(I32) => inspect(true, content="true")
    _ => inspect("not_i32", content="unexpected")
  }
}
