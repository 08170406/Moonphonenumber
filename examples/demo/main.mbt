///|
fn number_type_name(number_type : @phone.NumberType) -> String {
  match number_type {
    @phone.Mobile => "Mobile"
    @phone.FixedLine => "FixedLine"
    @phone.TollFree => "TollFree"
    @phone.PremiumRate => "PremiumRate"
    @phone.Voip => "Voip"
    @phone.Unknown => "Unknown"
  }
}

///|
fn main {
  match @phone.parse("+8613800138000") {
    Ok(number) => {
      println("E.164: \{number.format(@phone.E164)}")
      println("Valid: \{number.is_valid()}")
      println("Type: \{number_type_name(number.number_type())}")
    }
    Err(_) => println("Could not parse the demo number")
  }
  println("CN mobile as-you-type:")
  let sample = "13800138000"
  let mut length = 1
  while length <= sample.length() {
    let prefix = sample.unsafe_substring(start=0, end=length)
    println("\{prefix} -> \{@phone.format_as_you_type(prefix, "CN")}")
    length += 1
  }
}
