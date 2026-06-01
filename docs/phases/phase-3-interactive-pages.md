# Phase 3 — Built-in Interactive Pages

> Branch: `ios26_refactor`
> Status: In progress

## Objectives

- `Validation` — pure, testable input validation (email strict/lax, field
  completeness by content kind).
- `InputPageView` — renders `InputSpec` fields, live-validates, enables the
  primary button when valid, submits `.input([id: value])`.
- `PickerPageView` — option carousel (prev/next + select), respects per-option
  availability, submits `.picker(selectedID:)`.
- `ActionPageView` — already implemented in Phase 2; keep.
- Wire `WalkthroughPageView` to route `.input` and `.picker` to dedicated views.

## Risks / dependencies

- Local field state vs. model state: keep field text in `@State`, submit values
  through the proxy. Mitigation: single submit path; model owns StepState.
- Validation parity with the legacy strict email regex. Mitigation: unit tests
  covering valid/invalid addresses.

## Checklist

- [ ] `Validation` utility + `InputField`/`InputSpec` validity helpers.
- [ ] `InputPageView`.
- [ ] `PickerPageView`.
- [ ] Route kinds in `WalkthroughPageView`.
- [ ] Unit tests: email validation, field completeness, picker selection logic.
- [ ] `swift build` + `swift test` + iOS build green.

## Acceptance criteria

- Input pages validate and only enable submission when all required/typed fields
  are valid.
- Picker pages navigate options, disable selecting unavailable options, and
  submit the selected id.
- All tests pass; iOS Simulator build succeeds.
