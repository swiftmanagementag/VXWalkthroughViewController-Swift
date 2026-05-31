# Phase 4 — Auth & Permissions

> Branch: `ios26_refactor`
> Status: In progress

## Objectives

- `LoginPageView` — email + password, live validation, submits
  `.login(Credentials)`. Optional scan button wired to an injected scan handler
  (the scanner itself ships in Phase 5).
- `SignupPageView` — email, validation, submits `.signup(email:)`.
- `PermissionRequesting` protocol + `PermissionStatus` + a pure
  `PermissionResolver` (status -> `StepOutcome`).
- `SystemPermissionRequester` — default implementation for the full permission
  set (notifications, camera, microphone, photo library, location, contacts,
  ATT), gated to iOS/Catalyst; returns `.unavailable` elsewhere.
- `PermissionPageView` — requests via the environment-injected requester and
  drives state/navigation from the result.
- Environment injection for the requester and the scan handler.
- Route `.login`, `.signup`, `.permission` to dedicated views.

## Risks / dependencies

- System permission APIs cannot run headlessly. Mitigation: hide them behind
  `PermissionRequesting`; unit-test with a mock requester + the pure resolver.
- CoreLocation is delegate-based. Mitigation: a `@MainActor` continuation bridge.
- Cross-platform builds. Mitigation: `#if os(iOS)` guards; macOS returns
  `.unavailable` so `swift test` stays green.

## Checklist

- [ ] `PermissionRequesting`, `PermissionStatus`, `PermissionResolver`.
- [ ] `SystemPermissionRequester` (iOS) + environment injection.
- [ ] `MockPermissionRequester` (test support).
- [ ] `LoginPageView`, `SignupPageView`, `PermissionPageView`.
- [ ] Scan handler environment hook (consumed in Phase 5).
- [ ] Route kinds in `WalkthroughPageView`.
- [ ] Tests: resolver mapping, mock-driven permission flow, login/signup validity.
- [ ] `swift build` + `swift test` + iOS build green.

## Acceptance criteria

- Login/signup pages validate and submit typed payloads.
- Permission pages map every `PermissionStatus` to the correct `StepOutcome`.
- The core still builds and tests on macOS (no system prompts triggered).
- iOS Simulator build succeeds.
