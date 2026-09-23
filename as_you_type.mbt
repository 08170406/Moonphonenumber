///|
fn group_partial(
  digits : String,
  first_group : Int,
  next_group : Int,
  separator : String,
) -> String {
  let mut result = ""
  let mut cursor = 0
  let length = digits.length()
  while cursor < length {
    let group_size = if cursor == 0 { first_group } else { next_group }
    let end = if cursor + group_size < length {
      cursor + group_size
    } else {
      length
    }
    if cursor > 0 {
      result += separator
    }
    result += digits.unsafe_substring(start=cursor, end~)
    cursor = end
  }
  result
}

///|
fn matches_mobile_prefix(number : String, prefixes : Array[String]) -> Bool {
  for prefix in prefixes {
    if number.has_prefix(prefix) || prefix.has_prefix(number) {
      return true
    }
  }
  false
}

///|
pub fn format_as_you_type(input : String, region : String) -> String {
  let code = match calling_code_for_region(region) {
    Some(value) => value
    None => return input
  }
  let chars = input.to_array()
  let mut international = false
  let mut digits = ""
  let mut index = 0
  while index < chars.length() {
    let ch = chars[index]
    if ch == '+' && index == 0 {
      international = true
      index += 1
    } else if ch >= '0' && ch <= '9' {
      digits += "\{ch}"
      index += 1
    } else if ch == ' ' || ch == '(' || ch == ')' || ch == '-' || ch == '.' {
      index += 1
    } else {
      return input
    }
  }
  if !international && digits == "00" {
    return input
  }
  if !international && digits.has_prefix("00") {
    international = true
    digits = digits.unsafe_substring(start=2, end=digits.length())
  }
  if digits == "" {
    return if international { "+" } else { "" }
  }
  let national = if international {
    if digits.has_prefix(code) {
      digits.unsafe_substring(start=code.length(), end=digits.length())
    } else if code.has_prefix(digits) {
      return "+\{digits}"
    } else {
      return input
    }
  } else {
    digits
  }
  if national == "" {
    return "+\{code}"
  }
  let (is_mobile_prefix, first_group, next_group, separator) = match region {
    "CN" =>
      (
        matches_mobile_prefix(national, [
          "13", "14", "15", "16", "17", "18", "19",
        ]),
        3,
        4,
        " ",
      )
    "FR" if international =>
      (
        matches_mobile_prefix(national, [
          "6", "73", "74", "75", "76", "77", "78", "79",
        ]),
        1,
        2,
        " ",
      )
    "FR" =>
      (
        matches_mobile_prefix(national, [
          "06", "073", "074", "075", "076", "077", "078", "079",
        ]),
        2,
        2,
        " ",
      )
    "GB" if international =>
      (
        matches_mobile_prefix(national, [
          "71", "72", "73", "74", "75", "77", "78", "79",
        ]),
        4,
        6,
        " ",
      )
    "GB" =>
      (
        matches_mobile_prefix(national, [
          "071", "072", "073", "074", "075", "077", "078", "079",
        ]),
        5,
        6,
        " ",
      )
    "SG" =>
      (
        matches_mobile_prefix(national, [
          "801", "802", "803", "804", "805", "806", "807", "808", "809", "81", "82",
          "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94",
          "95", "96", "97", "98",
        ]),
        4,
        4,
        " ",
      )
    "AU" if international =>
      (matches_mobile_prefix(national, ["4"]), 3, 3, " ")
    "AU" =>
      (matches_mobile_prefix(national, ["04"]), 4, 3, " ")
    "JP" if international =>
      (
        matches_mobile_prefix(national, ["60", "70", "80", "90"]),
        2,
        4,
        "-",
      )
    "JP" =>
      (
        matches_mobile_prefix(national, ["060", "070", "080", "090"]),
        3,
        4,
        "-",
      )
    "IN" if international =>
      (matches_mobile_prefix(national, ["9"]), 5, 5, " ")
    "IN" =>
      (matches_mobile_prefix(national, ["09"]), 6, 5, " ")
    _ => (false, 0, 0, " ")
  }
  if !is_mobile_prefix {
    return input
  }
  let formatted = group_partial(national, first_group, next_group, separator)
  if international {
    "+\{code} \{formatted}"
  } else {
    formatted
  }
}
