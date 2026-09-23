# Moonphonenumber MVP Design

## Goal

Build a small, dependency-free MoonBit library for parsing, validating, formatting, identifying the broad type of, and progressively formatting phone numbers for a clearly bounded first release.

## Supported regions

The first release supports China (`CN`, calling code `86`), France (`FR`, `33`), the United Kingdom (`GB`, `44`), and Singapore (`SG`, `65`). This is country-level identification. It does not resolve territories sharing a calling code, such as Crown Dependencies under `+44`.

The supported metadata will be a small checked-in subset based on Google libphonenumber `v9.0.39` metadata. The repository will include the upstream Apache-2.0 license notice and identify the pinned upstream version and source file. It will not claim full libphonenumber coverage. Rules and formatting patterns outside the subset return conservative results and are documented.

The initial validation subset recognizes these common plan shapes:

| Region | Possible national lengths | Recognized number types |
| --- | --- | --- |
| CN | 10, 11 | Mobile: 11 digits beginning 13–19; common geographic numbers: 10 or 11 digits beginning with `10` or 2–9 (coarse subset) |
| FR | 9 | Mobile: beginning with `6` or 73–79; fixed line: 1–5; toll-free: 800–805 |
| GB | 9, 10 | Mobile: 71–75 or 77–79; geographic fixed line: first digit 1 or 2; toll-free: 800/808; premium: selected 842–845, 870–873, 90/91, and 982–989 ranges |
| SG | 8, 10, 11 | Mobile: 801–809, 81–89, or 90–98; fixed line: first digit 6; VoIP: 31, 32, or 666; toll-free: 800/1800; premium: 1900 |

These prefix summaries are the library's deliberately bounded recognition set. `is_possible` checks the lengths above; `is_valid` requires a matching recognized category. A number outside this set can still be assigned in a supported country and will be reported conservatively as unknown/invalid by this MVP.

## API and behavior

The public `PhoneNumber` stores an ISO region, calling code, national significant number, and optional extension. `parse(input, default_region?)` accepts ASCII digits, an optional leading `+` or `00`, spaces, parentheses, hyphens, dots, and common `ext`/`x` extension suffixes. Inputs without an international prefix require a supported default region. Parsing establishes number structure; it does not imply that the number is possible or valid.

The public API exposes:

- `parse(input : String, default_region? : String) -> Result[PhoneNumber, ParseError]`
- `PhoneNumber::is_possible(self) -> Bool`
- `PhoneNumber::is_valid(self) -> Bool`
- `PhoneNumber::number_type(self) -> NumberType`
- `PhoneNumber::format(self, format : PhoneFormat) -> String`
- `format_as_you_type(input : String, region : String) -> String`

Formats are E.164, international, national, and RFC 3966. E.164 strips extensions and emits `+<calling-code><national-number>`. International and national formats append ` ext. <digits>` when an extension is present. RFC 3966 emits `tel:+<calling-code>-<groups>` and appends `;ext=<digits>` when present. National formatting uses the selected region's domestic prefix and grouping rules.

Possible checks use supported national-number lengths. Valid checks additionally use the bounded leading-digit/type patterns. These checks describe numbering-plan plausibility only: they do not establish assignment, reachability, ownership, or SMS capability.

As-you-type formatting is stateless: callers pass the current input on each UI change. The first release supports mobile-number grouping for the four regions and preserves incomplete prefixes without claiming validity.

## Non-goals

No carrier lookup, geocoding, SMS/voice reachability, subscriber lookup, Unicode digit transliteration, vanity-number conversion, emergency/service short-code database, number portability, or full global metadata set. No network access is required at runtime.

## Acceptance criteria

1. The package builds as a MoonBit module explicitly owned by GitHub user `08170406`.
2. Tests cover supported and unsupported regions, national and international inputs, extensions, all four output formats, possible versus valid, number types, and incremental formatting.
3. Documentation contains the exact supported-region boundary, metadata provenance/version, limitations, and runnable examples.
4. A small runnable demo shows parse, E.164 output, validation/type, and progressive formatting.
