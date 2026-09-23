///|
fn is_ascii_digits(value : String) -> Bool {
  if value == "" {
    return false
  }
  for ch in value.to_array() {
    if ch < '0' || ch > '9' {
      return false
    }
  }
  true
}

///|
fn region_matches_calling_code(region : String, calling_code : String) -> Bool {
  match metadata_for_region(region) {
    Some(metadata) => metadata.calling_code == calling_code
    None => false
  }
}

///|
pub fn PhoneNumber::is_possible(self : PhoneNumber) -> Bool {
  region_matches_calling_code(self.region, self.calling_code) &&
  is_ascii_digits(self.national_number) &&
  possible_length(self.region, self.national_number.length())
}

///|
pub fn PhoneNumber::number_type(self : PhoneNumber) -> NumberType {
  if !self.is_possible() {
    return Unknown
  }
  number_type_for_region(self.region, self.national_number)
}

///|
pub fn PhoneNumber::is_valid(self : PhoneNumber) -> Bool {
  if !self.is_possible() {
    return false
  }
  match self.number_type() {
    Unknown => false
    _ => true
  }
}
