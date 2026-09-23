///|
pub(all) struct PhoneNumber {
  region : String
  calling_code : String
  national_number : String
  extension : String?
}

///|
pub(all) enum PhoneFormat {
  E164
  International
  National
  Rfc3966
}

///|
pub(all) enum NumberType {
  Mobile
  FixedLine
  TollFree
  PremiumRate
  Voip
  Unknown
}

///|
pub(all) enum ParseError {
  EmptyInput
  InvalidCharacter
  MissingRegion
  UnsupportedRegion
  UnsupportedCallingCode
  MissingNationalNumber
  TooLong
}

///|
pub fn PhoneNumber::is_possible(self : PhoneNumber) -> Bool {
  let _ = self
  false
}

///|
pub fn PhoneNumber::is_valid(self : PhoneNumber) -> Bool {
  let _ = self
  false
}

///|
pub fn PhoneNumber::number_type(self : PhoneNumber) -> NumberType {
  let _ = self
  Unknown
}

///|
pub fn PhoneNumber::format(self : PhoneNumber, format : PhoneFormat) -> String {
  let _ = format
  "+\{self.calling_code}\{self.national_number}"
}

///|
pub fn format_as_you_type(input : String, region : String) -> String {
  let _ = region
  input
}
