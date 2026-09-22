// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
test "parse_custom_section" {
  // Custom section: name="test", payload=0x01 0x02
  let payload : Bytes = b"\x04test\x01\x02"
  let cs = parse_custom_section(payload)
  inspect(cs.name, content="test")
  inspect(cs.payload.length(), content="2")
}

///|
test "parse_name_section_module_name" {
  // name section: subsection 0 (module name), size=5, name="hello"
  let payload : Bytes = b"\x04name\x00\x06\x05hello"
  let ns = parse_name_section(payload)
  match ns.module_name {
    Some(name) => inspect(name, content="hello")
    None => inspect("no_module_name", content="unexpected")
  }
}

///|
test "parse_name_section_function_names" {
  // Build name section with function names subsection
  // subsection 1: count=1, index=0, name="fn"
  // subsection content size: 1 (count) + 1 (index) + 1 (name_len) + 2 (name) = 5
  let parts : Array[Byte] = [
    b'\x04', b'n', b'a', b'm', b'e',
    b'\x01', b'\x05',
    b'\x01', b'\x00', b'\x02', b'f', b'n',
  ]
  let payload = Bytes::from_array(parts)
  let ns = parse_name_section(payload)
  inspect(ns.function_names.length(), content="1")
  inspect(ns.function_names[0].index, content="0")
  inspect(ns.function_names[0].name, content="fn")
}

///|
test "function_name_lookup" {
  let ns : NameSection = {
    module_name: None,
    function_names: [
      { index: 0, name: "init" },
      { index: 1, name: "process" },
      { index: 2, name: "cleanup" },
    ],
    local_names: [],
  }
  match ns.function_name(1) {
    Some(name) => inspect(name, content="process")
    None => inspect("not_found", content="unexpected")
  }
  match ns.function_name(99) {
    Some(_) => inspect("found", content="unexpected")
    None => inspect(true, content="true")
  }
}
