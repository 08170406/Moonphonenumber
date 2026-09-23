///|
// Returns whether an international prefix was present, its digit sequence,
// and the optional extension digits.
fn normalize_input(
  input : String,
) -> Result[(Bool, String, String?), ParseError] {
  if input == "" {
    return Err(EmptyInput)
  }
  let normalized = input.to_lower()
  let is_tel_uri = normalized.has_prefix("tel:")
  let chars = normalized.to_array()
  let start_index = if is_tel_uri { 4 } else { 0 }
  if is_tel_uri && (chars.length() <= start_index || chars[start_index] != '+') {
    return Err(InvalidCharacter)
  }
  let mut international = false
  let mut digits = ""
  let mut extension_digits = ""
  let mut in_extension = false
  let mut i = start_index
  while i < chars.length() {
    let ch = chars[i]
    if ch == '+' && i == start_index {
      international = true
      i += 1
    } else if !in_extension &&
      digits != "" &&
      ch == ';' &&
      i + 4 < chars.length() &&
      chars[i + 1] == 'e' &&
      chars[i + 2] == 'x' &&
      chars[i + 3] == 't' &&
      chars[i + 4] == '=' {
      in_extension = true
      i += 5
    } else if !in_extension && digits != "" && ch == 'x' {
      in_extension = true
      i += 1
    } else if !in_extension &&
      digits != "" &&
      ch == 'e' &&
      i + 2 < chars.length() &&
      chars[i + 1] == 'x' &&
      chars[i + 2] == 't' {
      in_extension = true
      i += 3
    } else if ch >= '0' && ch <= '9' {
      if in_extension {
        extension_digits += "\{ch}"
      } else {
        digits += "\{ch}"
      }
      i += 1
    } else if ch == ' ' || ch == '(' || ch == ')' || ch == '-' || ch == '.' {
      i += 1
    } else {
      return Err(InvalidCharacter)
    }
  }
  if digits == "" {
    return Err(EmptyInput)
  }
  if in_extension && extension_digits == "" {
    return Err(InvalidCharacter)
  }
  let extension = if in_extension { Some(extension_digits) } else { None }
  if international {
    Ok((true, digits, extension))
  } else if digits.has_prefix("00") {
    Ok((true, digits.unsafe_substring(start=2, end=digits.length()), extension))
  } else {
    Ok((false, digits, extension))
  }
}

///|
pub fn parse(
  input : String,
  default_region? : String,
) -> Result[PhoneNumber, ParseError] {
  let (international, digits, extension) = match normalize_input(input) {
    Ok(value) => value
    Err(error) => return Err(error)
  }
  let (metadata, national) = if international {
    if digits.length() < 2 {
      return Err(UnsupportedCallingCode)
    }
    let code = digits.unsafe_substring(start=0, end=2)
    let metadata = match metadata_for_calling_code(code) {
      Some(value) => value
      None => return Err(UnsupportedCallingCode)
    }
    (metadata, digits.unsafe_substring(start=2, end=digits.length()))
  } else {
    let region = match default_region {
      Some(value) => value
      None => return Err(MissingRegion)
    }
    let metadata = match metadata_for_region(region) {
      Some(value) => value
      None => return Err(UnsupportedRegion)
    }
    (metadata, digits)
  }
  let national = if metadata.national_prefix != "" &&
    national.has_prefix(metadata.national_prefix) {
    national.unsafe_substring(
      start=metadata.national_prefix.length(),
      end=national.length(),
    )
  } else {
    national
  }
  if national == "" {
    return Err(MissingNationalNumber)
  }
  if metadata.calling_code.length() + national.length() > 15 {
    return Err(TooLong)
  }
  Ok({
    region: metadata.region,
    calling_code: metadata.calling_code,
    national_number: national,
    extension,
  })
}
