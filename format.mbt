///|
// The patterns below cover only the region examples supported by this package.
fn group_national_number(number : PhoneNumber, separator : String) -> String {
  let nsn = number.national_number
  let length = nsn.length()
  match number.region {
    "FR" if length == 9 =>
      "\{nsn.unsafe_substring(start=0, end=1)}\{separator}\{nsn.unsafe_substring(start=1, end=3)}\{separator}\{nsn.unsafe_substring(start=3, end=5)}\{separator}\{nsn.unsafe_substring(start=5, end=7)}\{separator}\{nsn.unsafe_substring(start=7, end=9)}"
    "CN" if number.number_type() is Mobile =>
      "\{nsn.unsafe_substring(start=0, end=3)}\{separator}\{nsn.unsafe_substring(start=3, end=7)}\{separator}\{nsn.unsafe_substring(start=7, end=11)}"
    "CN" if length == 10 && (nsn.has_prefix("10") || nsn.has_prefix("2")) =>
      "\{nsn.unsafe_substring(start=0, end=2)}\{separator}\{nsn.unsafe_substring(start=2, end=10)}"
    "CN" if length == 10 || length == 11 =>
      "\{nsn.unsafe_substring(start=0, end=3)}\{separator}\{nsn.unsafe_substring(start=3, end=length)}"
    "GB" if length == 10 && nsn.has_prefix("7") =>
      "\{nsn.unsafe_substring(start=0, end=4)}\{separator}\{nsn.unsafe_substring(start=4, end=10)}"
    "GB" if length == 10 && nsn.has_prefix("20") =>
      "\{nsn.unsafe_substring(start=0, end=2)}\{separator}\{nsn.unsafe_substring(start=2, end=6)}\{separator}\{nsn.unsafe_substring(start=6, end=10)}"
    "GB" if length == 10 && nsn.has_prefix("1") =>
      "\{nsn.unsafe_substring(start=0, end=3)}\{separator}\{nsn.unsafe_substring(start=3, end=6)}\{separator}\{nsn.unsafe_substring(start=6, end=10)}"
    "SG" if length == 8 =>
      "\{nsn.unsafe_substring(start=0, end=4)}\{separator}\{nsn.unsafe_substring(start=4, end=8)}"
    _ => nsn
  }
}

///|
pub fn PhoneNumber::format(self : PhoneNumber, format : PhoneFormat) -> String {
  let e164 = "+\{self.calling_code}\{self.national_number}"
  if format is E164 {
    return e164
  }
  let extension = match self.extension {
    Some(digits) => " ext. \{digits}"
    None => ""
  }
  match format {
    International =>
      "+\{self.calling_code} \{group_national_number(self, " ")}\{extension}"
    National => {
      let prefix = match metadata_for_region(self.region) {
        Some(_) if self.region == "CN" && self.number_type() is Mobile => ""
        Some(metadata) => metadata.national_prefix
        None => ""
      }
      "\{prefix}\{group_national_number(self, " ")}\{extension}"
    }
    Rfc3966 => {
      let extension = match self.extension {
        Some(digits) => ";ext=\{digits}"
        None => ""
      }
      "tel:+\{self.calling_code}-\{group_national_number(self, "-")}\{extension}"
    }
    E164 => e164
  }
}
