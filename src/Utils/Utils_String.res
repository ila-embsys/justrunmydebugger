/// Return if string is empty
let empty = (s: string) => {
  s->String.length == 0
}

/// Convert string to option<string>
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

/// Convert option<string> to string
///
/// Return empty string if None
let from_option = (s: option<string>): string => {
    s->Belt.Option.getWithDefault("")
}
