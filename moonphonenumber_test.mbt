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
