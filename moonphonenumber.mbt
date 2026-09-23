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
