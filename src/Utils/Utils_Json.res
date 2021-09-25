let toInt = (obj: Js.Json.t): option<int> => {
  switch Js.Json.classify(obj) {
  | Js.Json.JSONNumber(obj) => Some(obj->Belt.Float.toInt)
  | _ => None
  }
}

let toString = (obj: Js.Json.t): option<string> => {
  switch Js.Json.classify(obj) {
  | Js.Json.JSONString(obj) => Some(obj)
  | _ => None
  }
}

let toObject = (obj: Js.Json.t): option<Js.Dict.t<Js.Json.t>> => {
  switch Js.Json.classify(obj) {
  | Js.Json.JSONObject(obj) => Some(obj)
  | _ => None
  }
}

let parse = (str: string): option<Js.Json.t> => {
  try Some(Js.Json.parseExn(str)) catch {
  | _ => None
  }
}

module Jzon = {
  /// Return codec to encode/decode int enum
  let int_enum = (enumToInt: 'a => int, intToEnum: int => option<'a>) =>
    Jzon.custom(
      x => Jzon.float->Jzon.encode(enumToInt(x)->Belt.Int.toFloat),
      json =>
        switch json->Js.Json.decodeNumber {
        | Some(x) =>
          switch x->Belt.Float.toInt->intToEnum {
          | Some(x) => Ok(x)
          | None =>
            Error(
              #UnexpectedJsonType(
                [],
                `int_enum (unexpected underlying enum value: ${x
                  ->Belt.Float.toInt
                  ->Js.Int.toString})`,
                json,
              ),
            )
          }
        | None => Error(#UnexpectedJsonType([], "string", json))
        },
    )
}
