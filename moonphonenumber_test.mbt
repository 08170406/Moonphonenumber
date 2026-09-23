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
      assert_eq(number.format(National), "0138 0013 8000")
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
