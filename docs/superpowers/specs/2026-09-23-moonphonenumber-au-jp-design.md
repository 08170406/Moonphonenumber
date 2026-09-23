# Moonphonenumber Australia and Japan Coverage Design

## Goal

Extend the bounded phone-number subset from CN, FR, GB, and SG to include common Australian (AU) and Japanese (JP) mobile and fixed-line numbers. Keep the library dependency-free and make the limits visible in its documentation.

## Metadata baseline

Use Google libphonenumber `v9.0.39` as the metadata reference, matching the repository's existing `NOTICE`. The upstream metadata assigns AU calling code `61` and JP calling code `81`; both regions use national prefix `0`. The upstream data marks AU as the main region for calling code `61`, which is also used by Christmas Island and the Cocos (Keeling) Islands. Moonphonenumber will resolve `61` to AU as its canonical supported region and will not claim territory-level identification.

Reference: [v9.0.39 PhoneNumberMetadata.xml](https://raw.githubusercontent.com/google/libphonenumber/v9.0.39/resources/PhoneNumberMetadata.xml).

## Supported subset

Retain the current `supported_regions()` order and append the new regions, producing `CN`, `FR`, `GB`, `SG`, `AU`, `JP`.

| Region | Calling code | Possible NSN lengths | Recognized types and prefixes |
| --- | --- | --- | --- |
| AU | 61 | 9 | Mobile: 9 digits beginning `4`; fixed line: 9 digits beginning `2`, `3`, `7`, or `8` |
| JP | 81 | 9, 10 | Mobile: 10 digits beginning `60`, `70`, `80`, or `90`; fixed line subset: 9 digits beginning `31`–`39` or `61`–`69` (Tokyo and Osaka) |

Other prefixes with one of these lengths may be reported as possible but unknown. Special-service and variable-length numbers, including Australian 13/1300/1800 ranges and Japanese service ranges, are outside the recognized type set; if their length overlaps the supported lengths, they may be possible but unknown and will not be valid. Territory-level distinction for numbers sharing AU's calling code is also out of scope.

## Parsing and public API

No new public function or type is needed. Add AU and JP to the existing metadata lookup so that:

- `parse("+61 412 345 678")` resolves to AU with NSN `412345678`.
- `parse("0412 345 678", default_region="AU")` strips the domestic trunk prefix and produces the same normalized number.
- `parse("+81 90-1234-5678")` resolves to JP with NSN `9012345678`.
- `parse("090-1234-5678", default_region="JP")` strips the domestic trunk prefix and produces the same normalized number.
- `calling_code_for_region`, `region_for_calling_code`, and `supported_regions` return the new metadata.

The calling codes remain two digits, so this work does not change the parser's calling-code extraction algorithm.

## Classification and formatting

Use the existing `NumberType` enum. `is_possible()` uses the listed NSN lengths; `number_type()` recognizes only the listed mobile and fixed-line prefixes; `is_valid()` stays limited to those recognized types.

Apply the following common patterns:

| Region/type | International | National | RFC 3966 |
| --- | --- | --- | --- |
| AU mobile | `+61 412 345 678` | `0412 345 678` | `tel:+61-412-345-678` |
| AU fixed, area code 2/3/7/8 | `+61 2 1234 5678` | `02 1234 5678` | `tel:+61-2-1234-5678` |
| JP mobile | `+81 90-1234-5678` | `090-1234-5678` | `tel:+81-90-1234-5678` |
| JP fixed, Tokyo/Osaka subset | `+81 3-1234-5678` | `03-1234-5678` | `tel:+81-3-1234-5678` |

E.164 remains `+<calling-code><NSN>` and omits extensions. Existing extension rendering remains unchanged in the other formats.

Extend `format_as_you_type` only for the recognized AU and JP mobile ranges. It must retain partial input, group the domestic trunk-prefix form, support international `+` and `00` input, and leave unsupported prefixes unchanged.

## Documentation and tests

Update the README's region table, API coverage text, limitations, and progressive-format examples. Keep the existing public signatures and stable order of the four existing regions.

Tests cover metadata lookup, national and international parsing, trunk-prefix normalization, the listed possible lengths and included/excluded classification boundaries, all four formats with and without extensions, progressive partial mobile formatting, and unsupported service-number behavior.

## Acceptance criteria

1. AU and JP parse using both international input and a regional default.
2. Region and calling-code discovery recognizes AU and JP while preserving the old region-list prefix.
3. Possible, valid, and type results follow only the subset in this document.
4. Formatting matches the examples above, including country-specific separators and trunk prefixes.
5. Progressive formatting works for the listed AU and JP mobile ranges without changing existing-region behavior.
6. README and generated interface checks accurately show that no public API signature was added.
7. `moon check --target all`, `moon test`, `moon info`, and `moon run examples/demo` pass.

## Non-goals

Full AU/JP numbering-plan coverage, territory resolution under calling code `61`, non-geographic or special-service ranges, international calling-code matching for new code lengths, Unicode digit transliteration, and new public API types or functions.
