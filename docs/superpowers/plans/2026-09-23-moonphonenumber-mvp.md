# Moonphonenumber MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a tested MoonBit library for parsing, checking, formatting, and progressively formatting phone numbers in CN, FR, GB, and SG.

**Architecture:** Keep public types and API in the root package. Keep the four-region numbering rules in a private metadata table, with parsing and rendering helpers in focused files. The library has no runtime network dependency; a demo package depends only on the root package.

**Tech Stack:** MoonBit toolchain `0.1.20260915`; MoonBit core prelude; MoonBit package tests; Google libphonenumber metadata subset pinned to `v9.0.39` under Apache-2.0 attribution.

## Global Constraints

- GitHub module owner is explicitly `08170406`; never infer a user name from a cached login.
- Supported ISO regions are exactly CN, FR, GB, and SG in this release.
- Parse syntax is ASCII digits with `+` or `00` international prefix, common visual separators, and `ext`/`x` extension suffixes.
- E.164 output is limited to the standard 15-digit maximum and excludes extensions.
- “Possible” means supported length; “valid” means the selected subset's length and leading-digit rules match.
- Validity does not establish assignment, ownership, reachability, carrier, or SMS capability.
- As-you-type formatting covers mobile patterns for the four supported regions.
- Do not claim parity with Google's complete global libphonenumber metadata.

---

### Task 1: Scaffold the MoonBit module and lock the public API

**Files:**
- Create: `moon.mod`
- Create: `moon.pkg`
- Create: `moonphonenumber.mbt`
- Create: `moonphonenumber_test.mbt`
- Modify: `README.md`
- Create: `LICENSE`
- Create: `NOTICE`
- Create: `docs/superpowers/specs/2026-09-23-moonphonenumber-design.md`
- Create: `docs/superpowers/plans/2026-09-23-moonphonenumber-mvp.md`

**Interfaces:**
- Define `PhoneNumber { region : String, calling_code : String, national_number : String, extension : String? }`.
- Define `PhoneFormat { E164, International, National, Rfc3966 }`, `NumberType { Mobile, FixedLine, TollFree, PremiumRate, Voip, Unknown }`, and `ParseError { EmptyInput, InvalidCharacter, MissingRegion, UnsupportedRegion, UnsupportedCallingCode, MissingNationalNumber, TooLong }`.
- Define `parse(input : String, default_region? : String) -> Result[PhoneNumber, ParseError]` and the public method signatures used by later tasks.

- [x] **Step 1: Write the public API contract test first**

Add a test that parses `+33612345678` and asserts region `FR`, calling code `33`, NSN `612345678`, and no extension. Add one failure assertion for `+999123` returning `UnsupportedCallingCode`.

- [x] **Step 2: Run the contract test and confirm it fails because the module/API is absent**

Run: `moon test`
Expected: a MoonBit compile diagnostic for the missing module or missing `parse` API.

- [x] **Step 3: Scaffold with explicit ownership and add the smallest compiling public types/API**

Run: `moon new . --user 08170406 --name moonphonenumber` only after confirming it preserves the existing README; if it refuses the non-empty directory, create the two MoonBit config files directly using the generated template from a temporary `moon new` directory. Keep the existing initial README content and extend it rather than replacing it.

Implement the public data types and method declarations needed for the first test. Add Apache-2.0 `LICENSE` and a `NOTICE` that attributes the selected metadata to Google libphonenumber `v9.0.39`, `resources/PhoneNumberMetadata.xml`, with the upstream URL.

- [x] **Step 4: Run the first test and make the parser test pass**

Run: `moon test`
Expected: the API contract assertions pass; the implementation may initially recognize only international calling codes required by the test.

### Task 2: Parse supported international and national input

**Files:**
- Create: `parse.mbt`
- Create: `metadata.mbt`
- Modify: `moonphonenumber_test.mbt`

**Interfaces:**
- Consume: `PhoneNumber`, `ParseError`, and `parse` from Task 1.
- Produce: internal `RegionMetadata`, `metadata_for_region(region : String)`, `metadata_for_calling_code(code : String)`, and `normalize_input(input : String) -> Result[(Bool, String, String?), ParseError]`.

- [x] **Step 1: Add failing parse cases**

Cover local CN mobile `13800138000` with default `CN`; domestic GB `020 7031 3000` with `GB`; French `06 12 34 56 78 ext 42` with `FR`; Singapore `+65 9123 4567`; `0044 7700 900123`; missing default region; and unsupported region/calling code.

- [x] **Step 2: Run `moon test` and verify the new cases fail for missing behavior**

Expected: compile or assertion failures identify the absent regional parsing behavior.

- [x] **Step 3: Implement normalization and metadata-driven region resolution**

Strip only the documented separators, parse `ext`/`x` suffixes, interpret `00` as the international prefix, require an explicit supported region for national input, remove national trunk prefix according to region rules, and reject more than 15 E.164 digits. Do not reject a structurally parsed number solely because its plan length is not possible.

- [x] **Step 4: Run `moon test` and confirm every parse case passes**

Expected: all Task 1 and Task 2 cases pass and malformed characters return `InvalidCharacter`.

### Task 3: Implement E.164, international, national, and RFC 3966 formatting

**Files:**
- Create: `format.mbt`
- Modify: `moonphonenumber_test.mbt`

**Interfaces:**
- Consume: `PhoneNumber` and the region formatting rules from Task 2.
- Produce: `PhoneNumber::format(self : PhoneNumber, format : PhoneFormat) -> String`.

- [x] **Step 1: Add failing format assertions**

For `+33612345678 ext 42`, assert E.164 `+33612345678`, international `+33 6 12 34 56 78 ext. 42`, national `06 12 34 56 78 ext. 42`, and RFC 3966 `tel:+33-6-12-34-56-78;ext=42`. Add representative CN, GB, and SG formatting examples.

- [x] **Step 2: Run `moon test` and verify formatting fails**

Expected: missing method or wrong-format assertions.

- [x] **Step 3: Implement grouping and format selection**

Apply supported group patterns by region and number type: FR `1-2-2-2-2`; CN mobile `3-4-4`, CN geographic `2/3-rest`; GB mobile `4-6`, London geographic `2-4-4`, other supported geographic examples `3-3-4`; SG `4-4`. National output uses `0` for supported CN geographic, FR, and GB numbers; CN mobile omits the trunk `0`, and SG has none. E.164 never includes separators or extensions.

- [x] **Step 4: Run `moon test` and confirm all four formats pass**

Expected: output exactly matches the examples in Step 1.

### Task 4: Add possible/valid checks and number-type classification

**Files:**
- Create: `validation.mbt`
- Modify: `moonphonenumber_test.mbt`

**Interfaces:**
- Produce: `PhoneNumber::is_possible(self : PhoneNumber) -> Bool`, `PhoneNumber::is_valid(self : PhoneNumber) -> Bool`, and `PhoneNumber::number_type(self : PhoneNumber) -> NumberType`.

- [x] **Step 1: Add failing plan classification cases**

Cover CN `13800138000` as possible, valid, Mobile and `01012345678` as FixedLine; GB `7700900123` as valid Mobile, `2070313000` as FixedLine, `8001234567` as TollFree, and `7000000000` as possible but unrecognized; FR `612345678` as valid Mobile, `123456789` as FixedLine, and `800123456` as TollFree; SG `91234567` as valid Mobile, `61234567` as FixedLine, `31234567` as Voip, and `18001234567` as TollFree. Also cover a supported-length but disallowed prefix as possible yet invalid, and a wrong-length value as not possible.

- [x] **Step 2: Run `moon test` and verify the plan checks fail**

Expected: missing methods or incorrect classification.

- [x] **Step 3: Implement length and prefix rules from the pinned subset**

Keep the lengths and category prefix rules listed in the design document in `metadata.mbt`, classify the documented basic types, return `Unknown` for unmodeled ranges, and make `is_valid` false unless both possibility and a supported prefix/type rule match.

- [x] **Step 4: Run `moon test` and confirm classifications pass**

Expected: possibility, validity, and type are independently asserted for all four regions.

### Task 5: Add progressive mobile formatting and runnable demo

**Files:**
- Create: `as_you_type.mbt`
- Modify: `moonphonenumber_test.mbt`
- Create: `examples/demo/moon.pkg`
- Create: `examples/demo/main.mbt`

**Interfaces:**
- Produce: `format_as_you_type(input : String, region : String) -> String`.

- [x] **Step 1: Add failing incremental-format cases**

Assert partial CN mobile `1380` becomes `138 0`, FR `0612` becomes `06 12`, GB `07700` becomes `07700`, and SG `91234567` becomes `9123 4567`.

- [x] **Step 2: Run `moon test` and verify progressive grouping fails**

Expected: missing function or mismatched grouping.

- [x] **Step 3: Implement stateless regional mobile grouping and the demo**

Format only characters available so far, preserve `+` for international input, and do not mark an incomplete value as valid. The demo parses one number, prints E.164/validity/type, and prints progressive CN mobile samples.

- [x] **Step 4: Run `moon test` and the demo**

Run: `moon test`
Run: `moon run examples/demo`
Expected: all tests pass and the demo prints the documented examples.

### Task 6: Complete README, metadata attribution, and MoonBit verification

**Files:**
- Modify: `README.md`
- Modify: `NOTICE`
- Verify: all files from Tasks 1–5.

- [x] **Step 1: Document API examples, region coverage, provenance, limitations, and build/test/run commands**

README must show the four supported regions and clearly say that valid means numbering-plan match, not subscriber assignment or reachability.

- [x] **Step 2: Format and run full MoonBit checks**

Run: `moon fmt`
Run: `moon check`
Run: `moon test`
Run: `moon info`
Run: `moon run examples/demo`
Expected: every command exits 0 and generated interface changes match the intended public API.

- [x] **Step 3: Review the final diff and commit verified work**

Run: `git status --short`; `git diff --check`; `git diff --stat`; review `git diff` and confirm no synced `sources/` files were touched. Commit as `feat: add Moonphonenumber regional MVP` after verification.

---

## Follow-up quality milestones

These are separate user-facing improvements to carry the package beyond the initial MVP. Each milestone should remain an independently understandable commit; do not create empty or bookkeeping-only commits.

### Task 7: Parse global RFC 3966 telephone URIs

Accept global `tel:+...` input with an optional `;ext=<digits>` parameter, while keeping local `phone-context` URIs out of scope. Add failing tests before updating the parser and documentation.

- [x] Add a failing global URI parse/format round-trip case and reject local `phone-context` URIs.
- [x] Implement `tel:` prefix and `;ext=` normalization.
- [x] Update the public parsing documentation and verify the full test suite.

### Task 8: Normalize `00` access prefixes while formatting as you type

Recognize `00` as an international access prefix in progressive formatting, handle partial country-code entry, and preserve standard `+<code>` output. Add incremental tests first.

### Task 9: Validate region and calling-code consistency

Make possibility, validity, and type results require a supported region with its matching calling code. Cover manually constructed inconsistent public values with tests.

### Task 10: Pin classification boundaries for every supported region

Add regression cases around included and excluded prefixes, lengths, and overlapping categories. Keep the bounded coverage table and tests synchronized.


