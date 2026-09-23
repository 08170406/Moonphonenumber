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
fn print_mobile_example(
  label : String,
  input : String,
  region : String,
  partial : String,
  complete : String,
) -> Unit {
  match @phone.parse(input, default_region=region) {
    Ok(number) => {
      println("\{label} E.164: \{number.format(@phone.E164)}")
      println("\{label} Valid: \{number.is_valid()}")
      println("\{label} Type: \{number_type_name(number.number_type())}")
      println("\{partial} -> \{@phone.format_as_you_type(partial, region)}")
      println("\{complete} -> \{@phone.format_as_you_type(complete, region)}")
    }
    Err(_) => println("Could not parse the \{label} demo number")
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
  print_mobile_example("AU", "0412 345 678", "AU", "0412345", "0412345678")
  print_mobile_example("JP", "090-1234-5678", "JP", "0901234", "09012345678")
  print_mobile_example("IN", "09876543210", "IN", "0987654", "09876543210")
}
