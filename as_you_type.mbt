///|
fn group_partial(
  digits : String,
  first_group : Int,
  next_group : Int,
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
      result += " "
    }
    result += digits.unsafe_substring(start=cursor, end~)
    cursor = end
  }
  result
}

///|
fn calling_code_for_region(region : String) -> String? {
  match metadata_for_region(region) {
    Some(metadata) => Some(metadata.calling_code)
    None => None
  }
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
  let (is_mobile_prefix, first_group, next_group) = match region {
    "CN" => (national.has_prefix("1"), 3, 4)
    "FR" if international =>
      (national.has_prefix("6") || national.has_prefix("7"), 1, 2)
    "FR" => (national.has_prefix("06") || national.has_prefix("07"), 2, 2)
    "GB" if international => (national.has_prefix("7"), 4, 6)
    "GB" => (national.has_prefix("07"), 5, 6)
    "SG" => (national.has_prefix("8") || national.has_prefix("9"), 4, 4)
    _ => (false, 0, 0)
  }
  if !is_mobile_prefix {
    return input
  }
  let formatted = group_partial(national, first_group, next_group)
  if international {
    "+\{code} \{formatted}"
  } else {
    formatted
  }
}
