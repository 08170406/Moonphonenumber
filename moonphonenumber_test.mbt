///|
test "French international parse public contract" {
  match parse("+33612345678") {
    Ok(number) => {
      assert_eq(number.region, "FR")
      assert_eq(number.calling_code, "33")
      assert_eq(number.national_number, "612345678")
      assert_eq(number.extension, None)
    }
    Err(_) => fail("expected French number")
  }
}

///|
test "unsupported international calling code" {
  match parse("+999123") {
    Err(UnsupportedCallingCode) => ()
    _ => fail("expected UnsupportedCallingCode")
  }
}

///|
test "CN national mobile parse" {
  match parse("13800138000", default_region="CN") {
    Ok(number) => {
      assert_eq(number.region, "CN")
      assert_eq(number.calling_code, "86")
      assert_eq(number.national_number, "13800138000")
    }
    Err(_) => fail("expected CN national number")
  }
}

///|
test "GB domestic trunk prefix" {
  match parse("020 7031 3000", default_region="GB") {
    Ok(number) => {
      assert_eq(number.region, "GB")
      assert_eq(number.calling_code, "44")
      assert_eq(number.national_number, "2070313000")
    }
    Err(_) => fail("expected GB national number")
  }
}

///|
test "French domestic extension" {
  match parse("06 12 34 56 78 ext 42", default_region="FR") {
    Ok(number) => {
      assert_eq(number.region, "FR")
      assert_eq(number.national_number, "612345678")
      assert_eq(number.extension, Some("42"))
    }
    Err(_) => fail("expected French number with extension")
  }
}

///|
test "x extension and documented separators" {
  match parse("+65 (9123)-4567.x42") {
    Ok(number) => {
      assert_eq(number.national_number, "91234567")
      assert_eq(number.extension, Some("42"))
    }
    _ => fail("expected number with x extension")
  }
}

///|
test "RFC 3966 global URI input" {
  match parse("tel:+33-6-12-34-56-78;ext=42") {
    Ok(number) => {
      assert_eq(number.region, "FR")
      assert_eq(number.national_number, "612345678")
      assert_eq(number.extension, Some("42"))
      assert_eq(number.format(Rfc3966), "tel:+33-6-12-34-56-78;ext=42")
    }
    Err(_) => fail("expected global RFC 3966 telephone URI")
  }
  match parse("tel:06-12-34-56-78;phone-context=+33", default_region="FR") {
    Err(InvalidCharacter) => ()
    _ => fail("expected local phone-context URI to remain unsupported")
  }
}

///|
test "Singapore international parse" {
  match parse("+65 9123 4567") {
    Ok(number) => {
      assert_eq(number.region, "SG")
      assert_eq(number.calling_code, "65")
      assert_eq(number.national_number, "91234567")
    }
    Err(_) => fail("expected Singapore number")
  }
}

///|
test "00 international access prefix" {
  match parse("0044 7700 900123") {
    Ok(number) => {
      assert_eq(number.region, "GB")
      assert_eq(number.national_number, "7700900123")
    }
    Err(_) => fail("expected GB international number")
  }
}

///|
test "national input needs region" {
  match parse("13800138000") {
    Err(MissingRegion) => ()
    _ => fail("expected MissingRegion")
  }
}

///|
test "unsupported national region" {
  match parse("2025550123", default_region="US") {
    Err(UnsupportedRegion) => ()
    _ => fail("expected UnsupportedRegion")
  }
}

///|
test "malformed characters are rejected" {
  match parse("+65 9123/4567") {
    Err(InvalidCharacter) => ()
    _ => fail("expected InvalidCharacter")
  }
}

///|
test "E164 length limit and structural parsing" {
  match parse("+33 12345678901234") {
    Err(TooLong) => ()
    _ => fail("expected TooLong")
  }
  match parse("123", default_region="SG") {
    Ok(number) => assert_eq(number.national_number, "123")
    _ => fail("expected structurally parsed short number")
  }
}

///|
test "French formatting and extension rendering" {
  match parse("+33612345678 ext 42") {
    Ok(number) => {
      assert_eq(number.format(E164), "+33612345678")
      assert_eq(number.format(International), "+33 6 12 34 56 78 ext. 42")
      assert_eq(number.format(National), "06 12 34 56 78 ext. 42")
      assert_eq(number.format(Rfc3966), "tel:+33-6-12-34-56-78;ext=42")
    }
    Err(_) => fail("expected French number with extension")
  }
}

///|
test "Chinese mobile and geographic formatting" {
  match parse("+8613800138000") {
    Ok(number) => {
      assert_eq(number.format(International), "+86 138 0013 8000")
      assert_eq(number.format(National), "138 0013 8000")
      assert_eq(number.format(Rfc3966), "tel:+86-138-0013-8000")
    }
    Err(_) => fail("expected Chinese mobile")
  }
  match parse("010 1234 5678", default_region="CN") {
    Ok(number) => {
      assert_eq(number.format(International), "+86 10 12345678")
      assert_eq(number.format(National), "010 12345678")
    }
    Err(_) => fail("expected Chinese geographic number")
  }
  match parse("0311 12345678", default_region="CN") {
    Ok(number) => assert_eq(number.format(National), "0311 12345678")
    Err(_) => fail("expected Chinese geographic number")
  }
}

///|
test "British mobile and geographic formatting" {
  match parse("+447700900123") {
    Ok(number) => {
      assert_eq(number.format(International), "+44 7700 900123")
      assert_eq(number.format(National), "07700 900123")
      assert_eq(number.format(Rfc3966), "tel:+44-7700-900123")
    }
    Err(_) => fail("expected British mobile")
  }
  match parse("020 7031 3000", default_region="GB") {
    Ok(number) => {
      assert_eq(number.format(International), "+44 20 7031 3000")
      assert_eq(number.format(National), "020 7031 3000")
    }
    Err(_) => fail("expected London number")
  }
  match parse("0161 234 5678", default_region="GB") {
    Ok(number) => assert_eq(number.format(National), "0161 234 5678")
    Err(_) => fail("expected British geographic number")
  }
}

///|
test "Singapore formatting has no national trunk prefix" {
  match parse("+65 9123 4567") {
    Ok(number) => {
      assert_eq(number.format(International), "+65 9123 4567")
      assert_eq(number.format(National), "9123 4567")
      assert_eq(number.format(Rfc3966), "tel:+65-9123-4567")
    }
    Err(_) => fail("expected Singapore number")
  }
}

///|
test "bounded plan validation classifies supported number types" {
  match parse("13800138000", default_region="CN") {
    Ok(number) => {
      assert_true(number.is_possible())
      assert_true(number.is_valid())
      assert_true(number.number_type() is Mobile)
    }
    Err(_) => fail("expected CN mobile")
  }
  match parse("01012345678", default_region="CN") {
    Ok(number) => assert_true(number.number_type() is FixedLine)
    Err(_) => fail("expected CN geographic number")
  }

  match parse("7700900123", default_region="GB") {
    Ok(number) => {
      assert_true(number.is_valid())
      assert_true(number.number_type() is Mobile)
    }
    Err(_) => fail("expected GB mobile")
  }
  match parse("2070313000", default_region="GB") {
    Ok(number) => assert_true(number.number_type() is FixedLine)
    Err(_) => fail("expected GB fixed line")
  }
  match parse("8001234567", default_region="GB") {
    Ok(number) => assert_true(number.number_type() is TollFree)
    Err(_) => fail("expected GB toll-free number")
  }
  match parse("09012345678", default_region="GB") {
    Ok(number) => {
      assert_true(number.is_valid())
      assert_true(number.number_type() is PremiumRate)
    }
    Err(_) => fail("expected GB premium-rate number")
  }
  match parse("7000000000", default_region="GB") {
    Ok(number) => {
      assert_true(number.is_possible())
      assert_false(number.is_valid())
      assert_true(number.number_type() is Unknown)
    }
    Err(_) => fail("expected structurally parsed GB number")
  }

  match parse("612345678", default_region="FR") {
    Ok(number) => assert_true(number.number_type() is Mobile)
    Err(_) => fail("expected French mobile")
  }
  match parse("123456789", default_region="FR") {
    Ok(number) => assert_true(number.number_type() is FixedLine)
    Err(_) => fail("expected French fixed line")
  }
  match parse("800123456", default_region="FR") {
    Ok(number) => assert_true(number.number_type() is TollFree)
    Err(_) => fail("expected French toll-free number")
  }

  match parse("91234567", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is Mobile)
    Err(_) => fail("expected Singapore mobile")
  }
  match parse("61234567", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is FixedLine)
    Err(_) => fail("expected Singapore fixed line")
  }
  match parse("31234567", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is Voip)
    Err(_) => fail("expected Singapore VoIP number")
  }
  match parse("66612345", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is Voip)
    Err(_) => fail("expected Singapore 666 VoIP number")
  }
  match parse("18001234567", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is TollFree)
    Err(_) => fail("expected Singapore toll-free number")
  }
  match parse("19001234", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is PremiumRate)
    Err(_) => fail("expected Singapore premium-rate number")
  }
}

///|
test "possible lengths and recognized prefixes are independent" {
  match parse("123456789012", default_region="CN") {
    Ok(number) => {
      assert_false(number.is_possible())
      assert_false(number.is_valid())
    }
    Err(_) => fail("expected structurally parsed CN number")
  }
  match parse("700000000", default_region="FR") {
    Ok(number) => {
      assert_true(number.is_possible())
      assert_false(number.is_valid())
      assert_true(number.number_type() is Unknown)
    }
    Err(_) => fail("expected structurally parsed French number")
  }
}

///|
test "validation rejects inconsistent region and calling code fields" {
  let number : PhoneNumber = {
    region: "CN",
    calling_code: "33",
    national_number: "13800138000",
    extension: None,
  }
  assert_false(number.is_possible())
  assert_false(number.is_valid())
  assert_true(number.number_type() is Unknown)
}

///|
test "regional prefix boundaries remain conservative" {
  match parse("19900123456", default_region="CN") {
    Ok(number) => assert_true(number.number_type() is Mobile)
    Err(_) => fail("expected upper CN mobile prefix")
  }
  match parse("12000123456", default_region="CN") {
    Ok(number) => {
      assert_true(number.is_possible())
      assert_false(number.is_valid())
      assert_true(number.number_type() is Unknown)
    }
    Err(_) => fail("expected unrecognized CN prefix")
  }
  match parse("2012345678", default_region="CN") {
    Ok(number) => assert_true(number.number_type() is FixedLine)
    Err(_) => fail("expected CN geographic prefix")
  }

  match parse("729999999", default_region="FR") {
    Ok(number) => assert_true(number.number_type() is Unknown)
    Err(_) => fail("expected excluded French mobile prefix")
  }
  match parse("739999999", default_region="FR") {
    Ok(number) => assert_true(number.number_type() is Mobile)
    Err(_) => fail("expected lower French mobile prefix")
  }
  match parse("799999999", default_region="FR") {
    Ok(number) => assert_true(number.number_type() is Mobile)
    Err(_) => fail("expected upper French mobile prefix")
  }
  match parse("806123456", default_region="FR") {
    Ok(number) => assert_true(number.number_type() is Unknown)
    Err(_) => fail("expected excluded French toll-free prefix")
  }

  match parse("7012345678", default_region="GB") {
    Ok(number) => assert_true(number.number_type() is Unknown)
    Err(_) => fail("expected excluded British mobile prefix")
  }
  match parse("7112345678", default_region="GB") {
    Ok(number) => assert_true(number.number_type() is Mobile)
    Err(_) => fail("expected lower British mobile prefix")
  }
  match parse("7612345678", default_region="GB") {
    Ok(number) => assert_true(number.number_type() is Unknown)
    Err(_) => fail("expected excluded British mobile prefix")
  }
  match parse("08421234567", default_region="GB") {
    Ok(number) => assert_true(number.number_type() is PremiumRate)
    Err(_) => fail("expected included British premium prefix")
  }
  match parse("08461234567", default_region="GB") {
    Ok(number) => {
      assert_true(number.is_possible())
      assert_false(number.is_valid())
    }
    Err(_) => fail("expected unrecognized British premium prefix")
  }

  match parse("80012345", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is TollFree)
    Err(_) => fail("expected Singapore toll-free prefix")
  }
  match parse("80112345", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is Mobile)
    Err(_) => fail("expected lower Singapore mobile prefix")
  }
  match parse("80912345", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is Mobile)
    Err(_) => fail("expected upper Singapore mobile prefix")
  }
  match parse("7000000000", default_region="SG") {
    Ok(number) => {
      assert_true(number.is_possible())
      assert_false(number.is_valid())
      assert_true(number.number_type() is Unknown)
    }
    Err(_) => fail("expected possible but unrecognized Singapore length")
  }
  match parse("99000000", default_region="SG") {
    Ok(number) => assert_true(number.number_type() is Unknown)
    Err(_) => fail("expected excluded Singapore mobile prefix")
  }
}

///|
test "as-you-type grouping follows recognized mobile prefixes" {
  assert_eq(format_as_you_type("1234", "CN"), "1234")
  assert_eq(format_as_you_type("0721234", "FR"), "0721234")
  assert_eq(format_as_you_type("0731234", "FR"), "07 31 23 4")
  assert_eq(format_as_you_type("+3372", "FR"), "+3372")
  assert_eq(format_as_you_type("070001", "GB"), "070001")
  assert_eq(format_as_you_type("076001", "GB"), "076001")
  assert_eq(format_as_you_type("+4470000", "GB"), "+4470000")
  assert_eq(format_as_you_type("80012345", "SG"), "80012345")
  assert_eq(format_as_you_type("99000000", "SG"), "99000000")
}

///|
test "supported region and calling-code discovery" {
  let regions = supported_regions()
  assert_eq(regions.length(), 6)
  assert_eq(regions[0], "CN")
  assert_eq(regions[1], "FR")
  assert_eq(regions[2], "GB")
  assert_eq(regions[3], "SG")
  assert_eq(regions[4], "AU")
  assert_eq(regions[5], "JP")
  assert_eq(calling_code_for_region("CN"), Some("86"))
  assert_eq(calling_code_for_region("FR"), Some("33"))
  assert_eq(calling_code_for_region("GB"), Some("44"))
  assert_eq(calling_code_for_region("SG"), Some("65"))
  assert_eq(calling_code_for_region("AU"), Some("61"))
  assert_eq(calling_code_for_region("JP"), Some("81"))
  assert_eq(calling_code_for_region("US"), None)
  assert_eq(region_for_calling_code("86"), Some("CN"))
  assert_eq(region_for_calling_code("33"), Some("FR"))
  assert_eq(region_for_calling_code("44"), Some("GB"))
  assert_eq(region_for_calling_code("65"), Some("SG"))
  assert_eq(region_for_calling_code("61"), Some("AU"))
  assert_eq(region_for_calling_code("81"), Some("JP"))
  assert_eq(region_for_calling_code("1"), None)
}

///|
test "AU and JP metadata and international parsing" {
  let regions = supported_regions()
  assert_eq(regions.length(), 6)
  assert_eq(regions[0], "CN")
  assert_eq(regions[1], "FR")
  assert_eq(regions[2], "GB")
  assert_eq(regions[3], "SG")
  assert_eq(regions[4], "AU")
  assert_eq(regions[5], "JP")
  assert_eq(calling_code_for_region("AU"), Some("61"))
  assert_eq(calling_code_for_region("JP"), Some("81"))
  assert_eq(region_for_calling_code("61"), Some("AU"))
  assert_eq(region_for_calling_code("81"), Some("JP"))
  match parse("+61 412 345 678") {
    Ok(number) => {
      assert_eq(number.region, "AU")
      assert_eq(number.national_number, "412345678")
    }
    Err(_) => fail("expected Australian number")
  }
  match parse("+81 90-1234-5678") {
    Ok(number) => {
      assert_eq(number.region, "JP")
      assert_eq(number.national_number, "9012345678")
    }
    Err(_) => fail("expected Japanese number")
  }
}

///|
test "AU and JP default-region parsing removes one trunk zero" {
  match parse("0412 345 678", default_region="AU") {
    Ok(number) => {
      assert_eq(number.region, "AU")
      assert_eq(number.national_number, "412345678")
    }
    Err(_) => fail("expected Australian national number")
  }
  match parse("090-1234-5678", default_region="JP") {
    Ok(number) => {
      assert_eq(number.region, "JP")
      assert_eq(number.national_number, "9012345678")
    }
    Err(_) => fail("expected Japanese national number")
  }
}

///|
test "progressive mobile formatting covers supported regions" {
  assert_eq(format_as_you_type("1380", "CN"), "138 0")
  assert_eq(format_as_you_type("0612", "FR"), "06 12")
  assert_eq(format_as_you_type("07700", "GB"), "07700")
  assert_eq(format_as_you_type("91234567", "SG"), "9123 4567")
  assert_eq(format_as_you_type("+861380", "CN"), "+86 138 0")
  assert_eq(format_as_you_type("+33612", "FR"), "+33 6 12")
  assert_eq(format_as_you_type("00447700900123", "GB"), "+44 7700 900123")
  assert_eq(format_as_you_type("0044", "GB"), "+44")
  assert_eq(format_as_you_type("00", "GB"), "00")
}
