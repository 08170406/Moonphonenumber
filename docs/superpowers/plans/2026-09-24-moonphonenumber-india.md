# Moonphonenumber India Coverage Implementation Plan

> **For agentic workers:** Use the executing-plans workflow to implement this plan task-by-task. Steps use checkbox syntax for progress.

**Goal:** Add the approved bounded India (`IN`, `+91`) mobile subset for 10-digit NSNs beginning with `9`, with parsing, classification, all four formats, and stateless as-you-type grouping.

**Architecture:** Reuse the existing region metadata table and generic parser so the `91` calling code and `0` trunk prefix require no new parser behavior. Extend the region-specific length/type, complete-number grouping, and progressive-format branches; keep the public API and dependencies unchanged.

**Tech Stack:** MoonBit, existing `moon` command suite, Markdown README and demo.

## Global Constraints

- Recognize only 10-digit Indian NSNs beginning with `9` as Mobile and valid.
- Treat other 10-digit prefixes as possible by length, with type Unknown and validity false.
- Preserve the existing supported-region order and append IN as the seventh region.
- Do not add public API signatures, dependencies, network access, or non-mobile Indian classifications.
- Use Google libphonenumber `v9.0.39` as the pinned metadata reference.
- Preserve behavior for the existing six regions.

---

### Task 1: Add India discovery, parsing, and classification

**Files:**
- Modify: `moonphonenumber_test.mbt`
- Modify: `metadata.mbt`

**Interfaces:**
- Consumes: `parse(input, default_region?)`, `supported_regions()`, `calling_code_for_region(region)`, `region_for_calling_code(code)`, `PhoneNumber::is_possible()`, `PhoneNumber::number_type()`, and `PhoneNumber::is_valid()`.
- Produces: metadata for `IN` / calling code `91` / national prefix `0`; possible NSN length 10; Mobile classification only for 10-digit NSNs starting `9`.

- [x] **Step 1: Extend the consolidated discovery assertion and add failing India parse/classification cases**

In the existing `supported region and calling-code discovery` test, expect 7 entries in order `CN, FR, GB, SG, AU, JP, IN`, check the `IN` lookup as `Some("91")`, and check calling code `91` resolves to `Some("IN")`.

Add a test that asserts `parse("+919876543210")` and `parse("09876543210", default_region="IN")` both normalize to region `IN`, code `91`, and NSN `9876543210`; both are possible, valid, and `Mobile`. In the same test, assert `parse("+918765432109")` is possible, not valid, and `Unknown`, while `parse("+91987654321")` is not possible, not valid, and `Unknown`.

- [x] **Step 2: Run the tests and confirm the feature is missing**

Run: `moon test`
Expected: new India cases fail because calling code `91` is unsupported, while existing tests remain passing.

- [x] **Step 3: Add only the required metadata and classification rules**

In `metadata_for_region`, add `"IN" => Some({ region: "IN", calling_code: "91", national_prefix: "0", })`. In `metadata_for_calling_code`, map `"91"` through `metadata_for_region("IN")`. Append `"IN"` to `supported_regions()`. In `possible_length`, accept length 10 for `IN`. In `number_type_for_region`, classify `IN` as `Mobile` only when length is 10 and the NSN has prefix `"9"`; otherwise return the existing `Unknown` fallback.

- [x] **Step 4: Run the tests and confirm parsing/classification pass**

Run: `moon test`
Expected: all existing and new tests pass.

- [x] **Step 5: Commit the completed parsing/classification slice**

```powershell
git add moonphonenumber_test.mbt metadata.mbt
git commit -m "feat: add bounded India number parsing"
```

### Task 2: Format complete Indian numbers

**Files:**
- Modify: `moonphonenumber_test.mbt`
- Modify: `format.mbt`

**Interfaces:**
- Consumes: the `IN` metadata and `NumberType::Mobile` result from Task 1; existing `PhoneNumber::format` for E164, International, National, and Rfc3966.
- Produces: 5-5 NSN grouping, with national prefix `0` and existing extension conventions.

- [x] **Step 1: Add failing format and extension assertions**

For `parse("+919876543210 ext 42")`, assert E164 `+919876543210`, International `+91 98765 43210 ext. 42`, National `098765 43210 ext. 42`, and Rfc3966 `tel:+91-98765-43210;ext=42`.

- [x] **Step 2: Run the tests and confirm India is not grouped yet**

Run: `moon test`
Expected: the Indian format assertions fail on the current ungrouped NSN outputs.

- [x] **Step 3: Add the Indian 5-5 grouping branch**

In `group_national_number`, when region is `IN`, NSN length is 10, and `number.number_type()` is `Mobile`, return NSN digits `0..5`, the supplied separator, then digits `5..10`. The existing `PhoneNumber::format` logic supplies the international space, national `0` prefix from metadata, and RFC3966 hyphen, and handles extensions.

- [x] **Step 4: Run the complete test suite**

Run: `moon test`
Expected: Indian format and extension cases pass without changing other region formats.

- [x] **Step 5: Commit complete-number formatting**

```powershell
git add moonphonenumber_test.mbt format.mbt
git commit -m "feat: format Indian mobile numbers"
```

### Task 3: Format Indian mobile input progressively

**Files:**
- Modify: `moonphonenumber_test.mbt`
- Modify: `as_you_type.mbt`

**Interfaces:**
- Consumes: existing `format_as_you_type(input, region)` and `matches_mobile_prefix(number, prefixes)`.
- Produces: domestic `09` candidate matching grouped as 6 then 5 digits (trunk plus first five NSN digits); international `9` candidate matching grouped as 5 then 5 digits with the existing `+91` and `00` handling.

- [x] **Step 1: Add failing domestic, international, 00, partial, and excluded-prefix examples**

Assert `format_as_you_type("09876543210", "IN") == "098765 43210"`, `format_as_you_type("0987654", "IN") == "098765 4"`, `format_as_you_type("+919876543210", "IN") == "+91 98765 43210"`, `format_as_you_type("+9198765", "IN") == "+91 98765"`, and `format_as_you_type("00919876543210", "IN") == "+91 98765 43210"`. Assert `format_as_you_type("0812345", "IN") == "0812345"`.

- [x] **Step 2: Run the tests and confirm progressive India formatting is missing**

Run: `moon test`
Expected: Indian progressive-format examples fail while existing progressive examples pass.

- [x] **Step 3: Add the two Indian progressive-format branches**

In `format_as_you_type`, add an `IN` case to the region match. When international, use `matches_mobile_prefix(national, ["9"])`, first group 5, next group 5, separator space. When domestic, use `matches_mobile_prefix(national, ["09"])`, first group 6, next group 5, separator space. Reuse existing international normalization and `group_partial`.

- [x] **Step 4: Run the complete test suite**

Run: `moon test`
Expected: new domestic/`+91`/`00` cases pass and all prior region tests remain passing.

- [x] **Step 5: Commit progressive formatting**

```powershell
git add moonphonenumber_test.mbt as_you_type.mbt
git commit -m "feat: format Indian numbers as typed"
```

### Task 4: Update coverage documentation and demo

**Files:**
- Modify: `README.md`
- Modify: `examples/demo/main.mbt`

**Interfaces:**
- Consumes: implemented `IN` parse, format, type, validation, and as-you-type behavior.
- Produces: discoverable documentation of seven-region coverage, India limits and examples; an Indian mobile in the demo.

- [x] **Step 1: Update README coverage and examples**

Change the supported count from six to seven and append IN / +91 to the numbering subset table. Document the 10-digit `9`-prefix Mobile subset and possible-but-unknown behavior for other 10-digit prefixes. Add Indian outputs for `+919876543210` to all four format examples and domestic `09876543210` parsing. Add `IN` examples for domestic, `+91`, and unsupported-prefix as-you-type behavior. Keep the existing metadata version, assignment limitations, and all other region boundaries accurate.

- [x] **Step 2: Add an Indian sample to the demo**

Add `print_mobile_example("IN", "09876543210", "IN", "098765", "09876543210")` alongside the AU and JP calls, preserving the existing CN demo.

- [x] **Step 3: Run tests and the runnable demo**

Run: `moon test` and `moon run examples/demo`
Expected: the suite passes and demo output includes Indian E.164, validity/type, and progressive formatting.

- [x] **Step 4: Commit documentation and demo**

```powershell
git add README.md examples/demo/main.mbt
git commit -m "docs: demonstrate bounded India phone support"
```

### Task 5: Run final MoonBit and repository verification

**Files:**
- Verify all files modified in Tasks 1–4.

**Interfaces:**
- Consumes: complete India implementation and docs.
- Produces: clean formatting, generated interface consistency, passing package checks/tests/demo, and a reviewed diff.

- [ ] **Step 1: Run MoonBit format and checks**

Run: `moon fmt`; `moon check --target all`; `moon test`; `moon info`; `moon run examples/demo`.
Expected: every command exits successfully and generated interface output contains no public API changes.

- [ ] **Step 2: Review the final diff**

Run: `git diff --check`; `git status --short`; `git diff --stat`; inspect all changes. Confirm no files under `sources/` changed and only India-scoped implementation/docs changed.

- [ ] **Step 3: Commit any formatter-only changes with the relevant feature task and prepare integration**

Ensure no changes remain uncommitted after the feature commits. Use the authorized GitHub identity `08170406` for any later remote operations.
