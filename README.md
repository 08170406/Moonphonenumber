# Moonphonenumber

Moonphonenumber is a dependency-free MoonBit library for parsing, formatting, and
checking phone numbers in a clearly bounded set of four regions: China (`CN`),
France (`FR`), the United Kingdom (`GB`), and Singapore (`SG`). It is an
ecosystem-native starting point for MoonBit web forms, account systems, CRM tools,
and contact imports.

The first release implements structural parsing, E.164, international, national,
and RFC 3966 formatting, possible/valid checks, broad number types, and
stateless mobile as-you-type formatting. It is not a full port of Google
libphonenumber and does not include the complete global numbering metadata set.

## Quick start

Import the package from a MoonBit module:

```moonbit
import {
  "08170406/moonphonenumber" @phone,
}

fn main {
  match @phone.parse("+33612345678 ext 42") {
    Ok(number) => {
      println(number.format(@phone.E164))
      println(number.format(@phone.International))
      println("Valid: \{number.is_valid()}")
    }
    Err(_) => println("Could not parse the phone number")
  }
}
```

The same parser accepts domestic input when you provide one of the supported
regions:

```moonbit
match @phone.parse("06 12 34 56 78", default_region="FR") {
  Ok(number) => println(number.format(@phone.Rfc3966))
  Err(_) => println("Invalid input syntax")
}
```

## Discover supported regions

Use the metadata accessors to populate a region selector or map a calling code
without keeping a second copy of the library's coverage list:

```moonbit
for region in @phone.supported_regions() {
  match @phone.calling_code_for_region(region) {
    Some(code) => println("\{region}: +\{code}")
    None => ()
  }
}

match @phone.region_for_calling_code("65") {
  Some(region) => println("+65 is \{region}")
  None => println("Unsupported calling code")
}
```

## Parsing and formatting

`parse` accepts ASCII digits, an optional leading `+` or `00`, spaces,
parentheses, hyphens, dots, `ext`/`x` extension suffixes, and global RFC 3966
`tel:+...;ext=...` URIs. Local `tel:` URIs that depend on `phone-context` are not
supported. National input requires a supported `default_region`. Parsing
establishes a normalized number structure; it does not imply that the number is
possible or valid.

For `+33612345678 ext 42`, the formatters produce:

| Format | Output |
| --- | --- |
| E.164 | `+33612345678` |
| International | `+33 6 12 34 56 78 ext. 42` |
| National | `06 12 34 56 78 ext. 42` |
| RFC 3966 | `tel:+33-6-12-34-56-78;ext=42` |

E.164 output omits extensions. National output uses `0` for supported French,
British, and Chinese geographic numbers, omits it for Chinese mobile numbers,
and has no trunk prefix for Singapore.

## Supported numbering subset

Possible-number checks use the national significant number lengths listed here.
The type prefixes are a bounded recognition set, not an exhaustive description
of every number currently assigned in each country.

| Region | Possible lengths | Recognized type patterns |
| --- | --- | --- |
| CN | 10, 11 | Mobile: 11 digits starting 13–19; common geographic: 10 or 11 digits starting `10` or 2–9 |
| FR | 9 | Mobile: starting `6` or 73–79; fixed line: 1–5; toll-free: 800–805 |
| GB | 9, 10 | Mobile: 71–75 or 77–79; fixed line: first digit 1 or 2; toll-free: 800/808; selected premium prefixes: 842–845, 870–873, 90/91, 982–989 |
| SG | 8, 10, 11 | Mobile: 801–809, 81–89, 90–98; fixed line: starting `6`; VoIP: 31, 32, 666; toll-free: 800/1800; premium: 1900 |

`is_possible()` checks that the supported region and calling code agree, the
national number contains only ASCII digits, and its length is supported.
`number_type()` returns `Unknown` when the number falls outside the recognized
type patterns or has an impossible length. `is_valid()` requires both a
supported length and a recognized type pattern. A `true` result means only that
the number matches this library's numbering-plan subset; it does **not** confirm
subscriber assignment, ownership, reachability, carrier, or SMS capability.

## As-you-type formatting

`format_as_you_type(input, region)` formats the current input on each UI change.
It supports common mobile prefixes for the four regions, keeps partial input
incomplete, preserves a leading `+`, and normalizes the international `00`
access prefix to `+` once a country code starts. It groups only prefixes inside
the supported mobile ranges; other input is returned as entered.

```moonbit
@phone.format_as_you_type("1380", "CN")     // "138 0"
@phone.format_as_you_type("0612", "FR")     // "06 12"
@phone.format_as_you_type("07700", "GB")    // "07700"
@phone.format_as_you_type("91234567", "SG") // "9123 4567"
@phone.format_as_you_type("0044", "GB")     // "+44"
```

## Build, test, and run the demo

With the MoonBit toolchain installed:

```sh
moon check
moon test
moon run examples/demo
```

The demo prints parse, E.164, validity, number type, and every progressive prefix
of a sample Chinese mobile number.

## Metadata and license

The selected rules are a small, manually constrained subset based on Google
libphonenumber `v9.0.39` and its `resources/PhoneNumberMetadata.xml`. The upstream
project is licensed under Apache-2.0; attribution and license details are in
[`NOTICE`](NOTICE) and [`LICENSE`](LICENSE). This repository does not claim
compatibility with the full upstream metadata or behavior.
