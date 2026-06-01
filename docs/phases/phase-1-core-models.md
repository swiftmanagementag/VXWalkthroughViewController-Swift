# Phase 1 — Core Domain Models

> Branch: `ios26_refactor`
> Status: In progress

## Objectives

Build the dependency-light, fully `Sendable` domain layer plus a declarative DSL,
with comprehensive unit tests. No SwiftUI views yet (rendering is Phase 2), but
SwiftUI value types (`Color`, `Font`, `AttributedString`) are used for config.

Deliverables:

- `WalkthroughImage` — `.named` / `.system` / `.remote(URL)` / `.none`.
- `AttributedTitle` — parses `*bold*` and `<b>bold</b>` markup into an
  `AttributedString` (bold via `.inlinePresentationIntent = .stronglyEmphasized`).
- `StepState` — `.idle` / `.loading` / `.success(String?)` / `.failure(String?)`.
- Specs: `InputSpec`, `LoginSpec`, `SignupSpec`, `ActionSpec`, `PickerSpec`
  (+ `PickerOption`), `PermissionSpec` (+ `PermissionKind`), `InputField`.
- `WalkthroughStep` (`Identifiable`, `Sendable`) + `StepKind` enum.
- `WalkthroughTheme` (colors, fonts, image style, motion, button shape).
- `WalkthroughBuilder` `@resultBuilder` + `Walkthrough` value + DSL page types
  (`InfoPage`, `InputPage`, `LoginPage`, `SignupPage`, `ActionPage`, `PickerPage`,
  `PermissionPage`) conforming to `WalkthroughStepConvertible`.
- `WalkthroughPresentationGate` — "shown once per version" with injectable storage.
- `LocalizedStepsLoader` — opt-in `walkthrough_0…n` population (parity).
- Supporting value types: `Credentials`, `WalkthroughAction`, `StepOutcome`.

## Key architectural decision (surfaced)

Page **actions are not stored as closures inside steps** (that would make
`WalkthroughStep` non-`Sendable`). Instead steps are pure data, and the host
supplies a single action handler to the runtime (Phase 2) of the form
`@MainActor (WalkthroughAction) async -> StepOutcome`, dispatched by step id.
This keeps the entire model layer `Sendable` and trivially testable.

Custom host-provided SwiftUI pages (`CustomPage`) are added in Phase 2 with the
rendering layer, since they require a view-builder closure.

## Risks / dependencies

- Markup parser correctness (overlapping/nested markers, unterminated markers).
  Mitigation: exhaustive unit tests; skip overlapping matches deterministically.
- Sort stability for steps with equal `sort`. Mitigation: stable ordering test.
- Version-gate storage keying must match legacy semantics
  (`vxwalkthroughshown_<build>`). Mitigation: parity test with an in-memory store.

## Checklist

- [ ] Implement all model types above (all `Sendable`).
- [ ] Implement `AttributedTitle` parser.
- [ ] Implement `WalkthroughBuilder` DSL.
- [ ] Implement `WalkthroughPresentationGate` with a `KeyValueStore` protocol
      (default `UserDefaults`, in-memory for tests).
- [ ] Implement `LocalizedStepsLoader` with an injectable lookup.
- [ ] Unit tests: markup parsing, image equality, step sorting/identity, DSL
      building, presentation gate (per-version), localized loader parity,
      state transitions.
- [ ] `swift test` green.

## Acceptance criteria

- All model types compile under Swift 6 strict concurrency as `Sendable`.
- DSL produces correctly ordered `[WalkthroughStep]`.
- Markup parser matches legacy bold behavior for `*`/`<b>` and leaves plain text
  untouched.
- Presentation gate returns `true` once per app version and `false` thereafter.
- `swift test` passes with meaningful coverage of every model type.
