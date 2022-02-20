/// Return if string is empty
let empty = (s: string) => {
  s->String.length == 0
}

/// Convert sting to option<string>
///
/// Return None if string empty
let to_option = (s: string): option<string> => {
    if s->Js.String2.length > 0 {
        Some(s)
    }
    else {
        None
    }
}
