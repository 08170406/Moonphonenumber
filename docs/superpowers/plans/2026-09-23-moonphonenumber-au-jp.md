# Australia and Japan Coverage Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development to implement this plan task-by-task with review after each task. Steps use checkbox (- [ ] ) syntax for tracking.

**Goal:** Add a bounded, documented subset of Australian and Japanese phone-number parsing, classification, formatting, and mobile as-you-type support.

**Architecture:** Extend the existing metadata table and per-region validation/formatting branches. Keep the public API and dependency-free design unchanged. Store national significant numbers without the domestic trunk 0; use region-specific rules for output grouping and progressive formatting.

**Tech Stack:** MoonBit, moon CLI, existing package metadata and tests.

## Global Constraints

- Base the selected rules on Google libphonenumber metadata v9.0.39.
- Keep supported_regions() ordered CN, FR, GB, SG, AU, JP so the existing order remains a prefix.
- Support AU mobile NSNs of 9 digits beginning 4 and fixed-line NSNs of 9 digits beginning 2, 3, 7, or 8.
- Support JP mobile NSNs of 10 digits beginning 60, 70, 80, or 90, and the 9-digit fixed-line subset beginning 31–39 or 61–69.
- Do not claim full AU/JP plan or territory coverage; unsupported types stay Unknown and fail is_valid().
- Preserve all existing region behavior, the current public API signatures, and the 15-digit E.164 limit.

---

## File map

- metadata.mbt: region metadata, calling-code metadata, and supported-region order.
- validation logic in metadata.mbt: possible lengths and type recognition.
- format.mbt: complete number grouping and output for all four formats.
- as_you_type.mbt: partial grouping for AU/JP mobile numbers.
- moonphonenumber_test.mbt: black-box tests for all new behavior.
- README.md: coverage table, boundaries, examples, and limitations.
- examples/demo/main.mbt: demonstrate AU/JP parsing and progressive input.
- docs/superpowers/plans/2026-09-23-moonphonenumber-mvp.md: record the completed follow-up milestone.
- pkg.generated.mbti: regenerate with moon info; public signatures should not change.
- .gitignore: exclude the repository-local .worktrees directory used for isolated implementation.

### Task 1: Add AU/JP region metadata and parsing

**Files:**
- Modify: metadata.mbt
- Test: moonphonenumber_test.mbt

**Interfaces:**
- Uses existing supported_regions(), calling_code_for_region(String), region_for_calling_code(String), and parse(String, default_region? : String).
- Adds no public signature.

- [ ] **Step 1: Add failing metadata and parse tests**

Append a test that checks the six-region ordering and both lookups, then parses these international examples: +61 412 345 678 to AU / 412345678, and +81 90-1234-5678 to JP / 9012345678. Add a second test for 0412 345 678 with default_region="AU" and 090-1234-5678 with default_region="JP"; each must remove one leading national 0.

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

- [ ] **Step 2: Run the tests and confirm the expected failures**

Run: moon test
Expected: the new cases fail because 61, 81, AU, and JP are not yet in metadata.

- [ ] **Step 3: Add the two metadata rows**

Add these match cases to metadata_for_region and metadata_for_calling_code, and append AU/JP after the existing four entries in supported_regions():

    "AU" => Some({ region: "AU", calling_code: "61", national_prefix: "0", })
    "JP" => Some({ region: "JP", calling_code: "81", national_prefix: "0", })

Map 61 to metadata_for_region("AU") and 81 to metadata_for_region("JP"). Do not change the parser's two-digit calling-code extraction.

- [ ] **Step 4: Run all tests and commit**

Run: moon test
Expected: all tests pass, including both new metadata/parsing cases.

    git add metadata.mbt moonphonenumber_test.mbt
    git commit -m "feat: add AU and JP region metadata"

### Task 2: Add possible-length and type boundaries

**Files:**
- Modify: metadata.mbt
- Test: moonphonenumber_test.mbt

**Interfaces:**
- Uses PhoneNumber::is_possible, PhoneNumber::number_type, and PhoneNumber::is_valid.
- Reuses the existing NumberType constructors; no public signature changes.

- [ ] **Step 1: Add failing classification tests**

Add assertions that +61412345678 and +61212345678 are valid AU Mobile and FixedLine numbers. Assert that +819012345678 and +816012345678 are valid JP Mobile numbers, and that +81312345678 and +81612345678 are valid JP FixedLine numbers.

Also test boundaries: +61512345678 and +81201234567 have supported lengths but unsupported type prefixes, so they are possible, Unknown, and invalid. +614123456789 is not possible because AU's supported NSN length is 9.

- [ ] **Step 2: Run moon test and confirm the new cases fail**

Expected: the existing possibility and type logic has no AU/JP branches.

- [ ] **Step 3: Add the minimal length and prefix branches**

In possible_length, add:

    "AU" => length == 9
    "JP" => length == 9 || length == 10

In number_type_for_region, add equivalent guards:

    "AU" if length == 9 && national_number.has_prefix("4") => Mobile
    "AU" if length == 9 && has_any_prefix(national_number, ["2", "3", "7", "8"]) => FixedLine
    "JP" if length == 10 && has_any_prefix(national_number, ["60", "70", "80", "90"]) => Mobile
    "JP" if length == 9 && has_any_prefix(national_number, [
      "31", "32", "33", "34", "35", "36", "37", "38", "39",
      "61", "62", "63", "64", "65", "66", "67", "68", "69",
    ]) => FixedLine

Leave all other prefixes as Unknown.

- [ ] **Step 4: Run all tests and commit**

Run: moon test
Expected: supported examples are possible and valid with the expected type; unsupported prefixes are possible but unknown and invalid.

    git add metadata.mbt moonphonenumber_test.mbt
    git commit -m "feat: classify AU and JP phone ranges"

### Task 3: Add complete-number formatting

**Files:**
- Modify: format.mbt
- Test: moonphonenumber_test.mbt

**Interfaces:**
- Uses existing PhoneNumber::format(PhoneFormat) -> String and PhoneFormat constructors.
- No public signature changes.

- [ ] **Step 1: Add failing four-format examples**

For +61412345678, assert E.164 +61412345678, International +61 412 345 678, National 0412 345 678, and RFC 3966 tel:+61-412-345-678. For +61212345678, assert the corresponding 2 1234 5678 area-code grouping and domestic 02 prefix.

For +819012345678, assert +819012345678, +81 90-1234-5678, 090-1234-5678, and tel:+81-90-1234-5678. For +81312345678, assert +81312345678, +81 3-1234-5678, 03-1234-5678, and tel:+81-3-1234-5678.

For +61412345678 ext 42, assert E.164 +61412345678, International +61 412 345 678 ext. 42, National 0412 345 678 ext. 42, and RFC 3966 tel:+61-412-345-678;ext=42. For +819012345678 ext 42, assert E.164 +819012345678, International +81 90-1234-5678 ext. 42, National 090-1234-5678 ext. 42, and RFC 3966 tel:+81-90-1234-5678;ext=42.

- [ ] **Step 2: Run moon test and confirm the grouping cases fail**

Expected: AU/JP values currently fall through to an ungrouped NSN.

- [ ] **Step 3: Add region-specific groups**

Add group_national_number branches for AU 9-digit mobile (3-3-3) and fixed line (1-4-4), and JP 10-digit mobile (2-4-4) and selected 9-digit fixed line (1-4-4). JP uses hyphens for International and National formats; RFC 3966 already uses hyphens. The existing format method continues to add national prefix 0 for AU and JP and keeps extension behavior unchanged.

Use these exact NSN slices, joining each group with the existing separator for AU and a hyphen for JP:

    AU mobile: nsn[0..3], nsn[3..6], nsn[6..9]
    AU fixed:  nsn[0..1], nsn[1..5], nsn[5..9]
    JP mobile: nsn[0..2], nsn[2..6], nsn[6..10]
    JP fixed:  nsn[0..1], nsn[1..5], nsn[5..9]

- [ ] **Step 4: Run all tests and commit**

Run: moon test
Expected: all four formats match the examples and extension behavior remains intact.

    git add format.mbt moonphonenumber_test.mbt
    git commit -m "feat: format AU and JP phone numbers"

### Task 4: Add AU/JP mobile as-you-type formatting

**Files:**
- Modify: as_you_type.mbt
- Test: moonphonenumber_test.mbt

**Interfaces:**
- Uses existing format_as_you_type(input : String, region : String) -> String.
- No public signature changes.

- [ ] **Step 1: Add failing partial-input tests**

Assert:

    format_as_you_type("0412345", "AU") == "0412 345"
    format_as_you_type("0412345678", "AU") == "0412 345 678"
    format_as_you_type("+61412345", "AU") == "+61 412 345"
    format_as_you_type("0901234", "JP") == "090-1234"
    format_as_you_type("09012345678", "JP") == "090-1234-5678"
    format_as_you_type("+81901234", "JP") == "+81 90-1234"
    format_as_you_type("08012345678", "JP") == "080-1234-5678"

Also assert that format_as_you_type("0512345678", "AU") and format_as_you_type("05012345678", "JP") return their inputs unchanged.

- [ ] **Step 2: Run moon test and confirm the new cases fail**

Expected: AU/JP mobile prefix rules are missing.

- [ ] **Step 3: Add region-specific progressive groups**

Pass the separator into group_partial so existing regions keep spaces and JP uses hyphens. For AU, use national prefix 04 with groups 4-3 and international NSN prefix 4 with groups 3-3. For JP, use national prefixes 060, 070, 080, 090 with groups 3-4 and international NSN prefixes 60, 70, 80, 90 with groups 2-4. Repeated groups complete the final group. Preserve current + and 00 handling.

- [ ] **Step 4: Run all tests and commit**

Run: moon test
Expected: the new partial and full values match, while all existing region formatting cases remain unchanged.

    git add as_you_type.mbt moonphonenumber_test.mbt
    git commit -m "feat: format AU and JP numbers as typed"

### Task 5: Update examples and run full verification

**Files:**
- Modify: README.md
- Modify: examples/demo/main.mbt
- Modify: docs/superpowers/plans/2026-09-23-moonphonenumber-mvp.md
- Regenerate/check: pkg.generated.mbti

**Interfaces:**
- Documentation reflects the existing API with two additional supported regions.
- No new public signatures are expected.

- [ ] **Step 1: Update README coverage and examples**

Document calling codes, possible lengths, recognized types, domestic and international examples, AU/JP mobile as-you-type output, and the special-service/territory limits from the approved design. Retain all existing limitations for other regions.

- [ ] **Step 2: Update the demo**

Keep the existing CN example and add one parsed AU mobile and one JP mobile. Print each normalized E.164 value, type, validity, and a short progressive-format sample.

- [ ] **Step 3: Mark this follow-up complete in the MVP plan**

Append Task 12 with checked boxes for tests first, metadata/classification, formats/as-you-type, and docs/full verification.

- [ ] **Step 4: Format and verify the full project**

Run, in order:

    moon fmt
    moon info
    moon check --target all
    moon test
    moon run examples/demo
    git diff --check

Expected: each command exits successfully; moon test reports zero failures; moon info leaves pkg.generated.mbti unchanged because no public signature was added. Review git diff and confirm no sources/ files changed.

- [ ] **Step 5: Commit documentation and demo**

    git add README.md examples/demo/main.mbt docs/superpowers/plans/2026-09-23-moonphonenumber-mvp.md
    git commit -m "docs: demonstrate AU and JP phone support"

### Task 6: Merge the completed feature to main

**Files:**
- No additional source files; use the configured remote https://github.com/08170406/Moonphonenumber.git.

- [ ] **Step 1: Push the feature branch and create a PR targeting main**

Use the active GitHub account 08170406; do not inspect or select historical cached accounts.

- [ ] **Step 2: Confirm PR author, target, mergeability, and checks**

Expected: author 08170406, base main, mergeable, and no failing required checks.

- [ ] **Step 3: Merge with a merge commit and clean up the feature branch**

Use the previously requested merge-to-main workflow; after GitHub confirms the merge, fast-forward the local main, verify tests and clean status, and delete the local and remote feature branch.
