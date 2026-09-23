///|
// Bounded country-level subset based on Google libphonenumber v9.0.39.
// See NOTICE for the upstream source and license attribution.
priv struct RegionMetadata {
  region : String
  calling_code : String
  national_prefix : String
}

///|
fn metadata_for_region(region : String) -> RegionMetadata? {
  match region {
    "CN" => Some({ region: "CN", calling_code: "86", national_prefix: "0", })
    "FR" => Some({ region: "FR", calling_code: "33", national_prefix: "0", })
    "GB" => Some({ region: "GB", calling_code: "44", national_prefix: "0", })
    "SG" => Some({ region: "SG", calling_code: "65", national_prefix: "", })
    _ => None
  }
}

///|
fn metadata_for_calling_code(code : String) -> RegionMetadata? {
  match code {
    "86" => metadata_for_region("CN")
    "33" => metadata_for_region("FR")
    "44" => metadata_for_region("GB")
    "65" => metadata_for_region("SG")
    _ => None
  }
}

///|
pub fn supported_regions() -> Array[String] {
  ["CN", "FR", "GB", "SG"]
}

///|
pub fn calling_code_for_region(region : String) -> String? {
  match metadata_for_region(region) {
    Some(metadata) => Some(metadata.calling_code)
    None => None
  }
}

///|
pub fn region_for_calling_code(code : String) -> String? {
  match metadata_for_calling_code(code) {
    Some(metadata) => Some(metadata.region)
    None => None
  }
}

///|
fn has_any_prefix(number : String, prefixes : Array[String]) -> Bool {
  for prefix in prefixes {
    if number.has_prefix(prefix) {
      return true
    }
  }
  false
}

///|
fn possible_length(region : String, length : Int) -> Bool {
  match region {
    "CN" => length == 10 || length == 11
    "FR" => length == 9
    "GB" => length == 9 || length == 10
    "SG" => length == 8 || length == 10 || length == 11
    _ => false
  }
}

///|
fn number_type_for_region(
  region : String,
  national_number : String,
) -> NumberType {
  let length = national_number.length()
  match region {
    "CN" if length == 11 &&
      has_any_prefix(national_number, ["13", "14", "15", "16", "17", "18", "19"]) =>
      Mobile
    "CN" if (length == 10 || length == 11) &&
      has_any_prefix(national_number, [
        "10", "2", "3", "4", "5", "6", "7", "8", "9",
      ]) => FixedLine
    "FR" if length == 9 &&
      has_any_prefix(national_number, ["800", "801", "802", "803", "804", "805"]) =>
      TollFree
    "FR" if length == 9 &&
      has_any_prefix(national_number, [
        "6", "73", "74", "75", "76", "77", "78", "79",
      ]) => Mobile
    "FR" if length == 9 &&
      has_any_prefix(national_number, ["1", "2", "3", "4", "5"]) => FixedLine
    "GB" if length == 10 &&
      has_any_prefix(national_number, [
        "71", "72", "73", "74", "75", "77", "78", "79",
      ]) => Mobile
    "GB" if length == 10 && has_any_prefix(national_number, ["800", "808"]) =>
      TollFree
    "GB" if length == 10 &&
      has_any_prefix(national_number, [
        "842", "843", "844", "845", "870", "871", "872", "873", "90", "91", "982",
        "983", "984", "985", "986", "987", "988", "989",
      ]) => PremiumRate
    "GB" if (length == 9 || length == 10) &&
      has_any_prefix(national_number, ["1", "2"]) => FixedLine
    "SG" if length == 11 && national_number.has_prefix("1800") => TollFree
    "SG" if length == 8 && national_number.has_prefix("800") => TollFree
    "SG" if length == 8 && national_number.has_prefix("1900") => PremiumRate
    "SG" if length == 8 && has_any_prefix(national_number, ["31", "32", "666"]) =>
      Voip
    "SG" if length == 8 && national_number.has_prefix("6") => FixedLine
    "SG" if length == 8 &&
      has_any_prefix(national_number, [
        "801", "802", "803", "804", "805", "806", "807", "808", "809", "81", "82",
        "83", "84", "85", "86", "87", "88", "89", "90", "91", "92", "93", "94", "95",
        "96", "97", "98",
      ]) => Mobile
    _ => Unknown
  }
}
