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
