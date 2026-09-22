// Copyright 2026 wuhaiting321
// Apache License 2.0

///|
/// Command Line Arguments Configuration Options
pub(all) struct CliOptions {
  mut file_path : String
  mut show_sections : Bool
  mut show_types : Bool
  mut show_imports : Bool
  mut show_exports : Bool
  mut show_functions : Bool
  mut show_globals : Bool
  mut show_memories : Bool
  mut show_tables : Bool
  mut show_data : Bool
  mut show_elements : Bool
  mut show_code : Bool
  mut disassemble_func : UInt?
  mut do_validate : Bool
  mut output_format : String
  mut show_help : Bool
  mut show_version : Bool
  mut error : String?
} derive(Debug, Eq)

///|
/// Create default CliOptions instance
pub fn CliOptions::default() -> CliOptions {
  {
    file_path: "",
    show_sections: false,
    show_types: false,
    show_imports: false,
    show_exports: false,
    show_functions: false,
    show_globals: false,
    show_memories: false,
    show_tables: false,
    show_data: false,
    show_elements: false,
    show_code: false,
    disassemble_func: None,
    do_validate: false,
    output_format: "text",
    show_help: false,
    show_version: false,
    error: None,
  }
}

///|
fn parse_uint(value : String) -> UInt? {
  let trimmed = value.trim().to_owned()
  if trimmed.length() == 0 {
    return None
  }
  let mut result : UInt = 0
  for ch in trimmed {
    if ch is ('0'..='9') {
      result = result * 10 + (ch.to_int() - '0'.to_int()).reinterpret_as_uint()
    } else {
      return None
    }
  }
  Some(result)
}

///|
fn set_format(opts : CliOptions, format : String) -> Unit {
  let normalized = format.trim().to_lower().to_owned()
  if normalized == "text" || normalized == "markdown" || normalized == "json" {
    opts.output_format = normalized
  } else if opts.error is None {
    opts.error = Some("Unsupported format: \{format}")
  }
}

///|
/// Parse command line arguments array into CliOptions
pub fn parse_cli_args(args : Array[String]) -> CliOptions {
  let opts = CliOptions::default()
  let mut i = 0
  while i < args.length() {
    let arg = args[i]
    match arg {
      "--help" | "-?" => opts.show_help = true
      "--version" => opts.show_version = true
      "--sections" => opts.show_sections = true
      "--types" => opts.show_types = true
      "--imports" => opts.show_imports = true
      "--exports" => opts.show_exports = true
      "--functions" => opts.show_functions = true
      "--globals" => opts.show_globals = true
      "--memories" => opts.show_memories = true
      "--tables" => opts.show_tables = true
      "--data" => opts.show_data = true
      "--elements" => opts.show_elements = true
      "--code" => opts.show_code = true
      "--validate" => opts.do_validate = true
      "--disassemble" =>
        if i + 1 < args.length() {
          i += 1
          match parse_uint(args[i]) {
            Some(idx) => opts.disassemble_func = Some(idx)
            None =>
              if opts.error is None {
                opts.error = Some("Invalid function index: \{args[i]}")
              }
          }
        } else if opts.error is None {
          opts.error = Some("Missing value for --disassemble")
        }
      "--format" =>
        if i + 1 < args.length() {
          i += 1
          set_format(opts, args[i])
        } else if opts.error is None {
          opts.error = Some("Missing value for --format")
        }
      _ if arg.has_prefix("--format=") =>
        set_format(opts, arg.exact_view(start=9).to_owned())
      _ =>
        if arg.length() > 0 && arg[0] != '-' {
          if opts.file_path.length() == 0 {
            opts.file_path = arg
          } else if opts.error is None {
            opts.error = Some("Multiple input files are not supported")
          }
        } else if opts.error is None {
          opts.error = Some("Unknown option: \{arg}")
        }
    }
    i = i + 1
  }
  opts
}

///|
/// Parse the process arguments vector (skipping executable path)
pub fn parse_process_args(args : Array[String]) -> CliOptions {
  let user_args : Array[String] = []
  let mut i = if args.length() > 0 { 1 } else { 0 }
  while i < args.length() {
    user_args.push(args[i])
    i += 1
  }
  parse_cli_args(user_args)
}
