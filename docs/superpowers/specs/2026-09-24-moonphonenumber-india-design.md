# Moonphonenumber India Coverage Design

## Goal

Extend the existing bounded MoonBit phone-number subset with India (`IN`, calling code `91`) for a clearly defined mobile-number range. Keep the library dependency-free and state the supported boundary wherever coverage is described.

## Metadata baseline

Use Google libphonenumber `v9.0.39` as the pinned metadata reference, matching the repository's existing `NOTICE`. Its India metadata assigns calling code `91`, uses national prefix `0`, and describes 10-digit national numbers. The selected mobile subset is limited to national significant numbers that begin with `9`; the upstream metadata includes this prefix family and formats national numbers in two groups of five digits.

References:

- [India region and calling-code metadata](https://github.com/google/libphonenumber/blob/v9.0.39/resources/PhoneNumberMetadata.xml#L14592-L14599)
- [India 5-5 formatting rule](https://github.com/google/libphonenumber/blob/v9.0.39/resources/PhoneNumberMetadata.xml#L15332-L15341)
- [India mobile length and prefix patterns](https://github.com/google/libphonenumber/blob/v9.0.39/resources/PhoneNumberMetadata.xml#L15410-L15413)
- [India 9-prefix mobile pattern](https://github.com/google/libphonenumber/blob/v9.0.39/resources/PhoneNumberMetadata.xml#L15571-L15574)

## Supported subset

Append India to the existing stable region order, producing `CN`, `FR`, `GB`, `SG`, `AU`, `JP`, `IN`.

| Region | Calling code | Possible NSN lengths | Recognized types and prefixes |
| --- | --- | --- | --- |
| IN | 91 | 10 | Mobile subset: 10 digits beginning with `9` |

This milestone recognizes only the selected 9-leading mobile subset. A 10-digit number beginning with another digit remains possible by length, but its type is `Unknown` and `is_valid()` is false. The library does not classify Indian fixed-line, toll-free, premium, emergency, service, or other mobile ranges. These checks do not establish that a number is assigned, reachable, owned by a subscriber, or SMS-capable.

## Parsing and public API

No new public function or type is needed. Add India to the existing metadata lookup and preserve the order of all existing regions. The existing two-digit country-code extraction handles `91` without changing parser strategy.

Expected normalized values:

- `parse("+91 98765 43210")` produces region `IN`, calling code `91`, and NSN `9876543210`.
- `parse("09876543210", default_region="IN")` removes the domestic `0` prefix and produces the same normalized number.
- `calling_code_for_region("IN")` returns `"91"`, and `region_for_calling_code("91")` returns `"IN"`.

Parsing validates input structure and region support; callers use `is_possible()`, `number_type()`, and `is_valid()` for the bounded plan checks.

## Classification and formatting

Use the existing `NumberType` enum. A number is possible when it has a supported region/calling-code pair, ASCII digits, and 10 NSN digits. Within that length, only an NSN beginning with `9` is classified as `Mobile` and valid; all other prefixes remain `Unknown` and invalid.

| Format | Example for `+919876543210` |
| --- | --- |
| E.164 | `+919876543210` |
| International | `+91 98765 43210` |
| National | `098765 43210` |
| RFC 3966 | `tel:+91-98765-43210` |

E.164 omits extensions. International and national formats append the existing ` ext. <digits>` suffix when an extension is present; RFC 3966 appends `;ext=<digits>`.

Extend `format_as_you_type` for the selected mobile subset. Domestic input retains its trunk `0` and groups the first six digits (trunk prefix plus five NSN digits), then groups five digits. International input with `+91` or a normalized `00` access prefix groups the NSN as 5-5. Preserve incomplete recognized prefixes without claiming they are valid; leave unsupported prefixes unchanged.

Examples:

- `format_as_you_type("09876543210", "IN")` produces `098765 43210`.
- `format_as_you_type("+919876543210", "IN")` produces `+91 98765 43210`.
- `format_as_you_type("009198765", "IN")` produces `+91 98765`.
- A domestic input beginning with `08` remains unchanged because it is outside the selected prefix subset.

## Documentation and tests

Update the README's supported-region count and order, region table, limitations, formatting examples, and progressive-format examples. Update the demo to include one Indian example while retaining an example from existing regions. No public API signature changes are expected, so generated interface output should remain unchanged.

Tests should cover:

- India appended to the supported-region list and both calling-code lookups, in one consolidated discovery assertion.
- International `+91` and domestic `0` parsing, including normalized region, calling code, and NSN.
- The 9-prefix mobile case, a 10-digit non-9 prefix that is possible but unknown/invalid, and an unsupported length.
- E.164, international, national, and RFC 3966 formats, including extension behavior.
- Domestic, `+91`, and `00` as-you-type formatting, partial mobile input, and an unsupported prefix.
- Regression behavior for the existing six regions.

## Acceptance criteria

1. India is discoverable as `IN` / `91` and appears after the six existing regions in `supported_regions()`.
2. International and domestic parsing produce the same normalized 10-digit NSN.
3. Only the specified 9-leading 10-digit subset is classified as mobile and valid; other 10-digit prefixes are possible but unknown/invalid.
4. All four output formats match the examples, including the Indian 0 trunk prefix and 5-5 grouping.
5. Progressive formatting supports domestic, `+91`, and `00` entry for the selected subset without changing existing-region behavior.
6. README, demo, and tests describe the same bounded coverage and its limits.
7. MoonBit formatting, interface, checks, tests, demo, and diff verification pass.

## Non-goals

Full Indian numbering-plan coverage; Indian fixed-line, service, or special-number classification; regions sharing calling code `91`; external metadata lookup; assignment, carrier, reachability, or SMS checks; new public API signatures; Unicode digit transliteration; and runtime network access.
