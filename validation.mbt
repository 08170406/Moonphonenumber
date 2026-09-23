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
pub fn PhoneNumber::is_possible(self : PhoneNumber) -> Bool {
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
