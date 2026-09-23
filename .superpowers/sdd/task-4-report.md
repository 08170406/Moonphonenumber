# Task 4 report: AU/JP mobile as-you-type formatting

## Status

Implemented the requested progressive grouping without changing the public `format_as_you_type(input, region)` signature.

## RED evidence

Added the nine specified AU/JP assertions to `moonphonenumber_test.mbt`, then ran `moon test` before changing production code. Exit code: 1.

```text
AU mobile numbers format progressively as typed failed:
  "0412345" != "0412 345"
JP mobile numbers format progressively as typed failed:
  "0901234" != "090-1234"
Total tests: 32, passed: 30, failed: 2.
```

Both failures were caused by missing AU/JP as-you-type prefix rules.

## GREEN evidence

Updated `group_partial` to accept a separator and extended region matching with AU and JP mobile prefixes and group sizes. Existing regions pass a space; JP passes a hyphen.

```text
moon test --filter '*mobile numbers format progressively as typed'
Total tests: 2, passed: 2, failed: 0.

moon test
Total tests: 32, passed: 32, failed: 0.
```

`git diff --check` produced no whitespace errors. Git printed only LF-to-CRLF working-copy notices.

## Files changed

- `as_you_type.mbt`: separator parameter; AU national `04` (4-3-3) and international `4` (3-3-3); JP national `060`/`070`/`080`/`090` (3-4-4) and international `60`/`70`/`80`/`90` (2-4-4).
- `moonphonenumber_test.mbt`: specified AU/JP partial, complete, international, and unrecognized-prefix examples.

## Self-review

- Public signature is unchanged.
- Existing CN, FR, GB, and SG rules continue to use spaces.
- Existing `+` and `00` normalization paths are untouched.
- Unrecognized AU/JP prefixes return the input unchanged.
- Repeated `next_group` sizes produce the final group for complete numbers.
- No known concerns.

## Final review fixes

- `moonphonenumber_test.mbt`: added direct JP as-you-type assertions for domestic `060`/`070`, international `60`/`70`/`80`, and a `00` international input. No production logic changed.
- `.superpowers/sdd/task-2-report.md`: removed the extra blank line at EOF.
- `moon test --filter '*JP mobile numbers format progressively as typed'`: `Total tests: 1, passed: 1, failed: 0.`
- `moon test`: `Total tests: 32, passed: 32, failed: 0.`
- `git diff --check`: exit 0, no whitespace errors; Git emitted only LF-to-CRLF working-copy warnings.
- Concerns: none.
