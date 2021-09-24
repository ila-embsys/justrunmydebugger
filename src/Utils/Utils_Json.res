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
    | _ => {
        Js.Console.error("Error parsing event JSON string")
        None
      }
    }
}
