# Phase 2 — SwiftUI Rendering Engine

> Branch: `ios26_refactor`
> Status: In progress

## Objectives

- `WalkthroughModel` — `@MainActor @Observable` runtime: holds steps/theme,
  `currentIndex`, per-step `StepState`, navigation, the host action handler, and
  event callbacks. Drives `.loading` → `.success`/`.failure` around `async`
  actions.
- `WalkthroughPageProxy` — `@MainActor` value passed to pages giving them a clean
  API: `advance()`, `previous()`, `finish()`, `submit(payload)`, and `state`.
- Cross-platform `WalkthroughContainer` pager built on
  `ScrollView(.horizontal)` + `LazyHStack` + `containerRelativeFrame` +
  `.scrollTargetBehavior(.paging)` + `.scrollPosition(id:)` (works on iOS 17 and
  macOS 14; avoids iOS-only `PageTabViewStyle`).
- `PageChrome` — page indicator + previous/next/close controls (SF Symbols),
  iOS 26 Liquid Glass behind availability with a material fallback.
- `WalkthroughImageView` and `InfoPageView` (display page).
- `ParallaxModifier` using `.scrollTransition`, honoring reduce-motion and theme
  motion.
- `WalkthroughView` — public entry view + event modifiers (`onFinish`,
  `onPageChange`, `onAction`) and `walkthroughCustomPage(id:)` for host pages.
- Interactive kinds render a functional default (title/image + primary button)
  in Phase 2; full field UIs land in Phase 3.

## Risks / dependencies

- Keeping `scrollPosition` and `currentIndex` in sync without feedback loops.
  Mitigation: single source of truth in the model; guard redundant updates.
- `@Observable` + Swift 6 main-actor isolation. Mitigation: isolate the model and
  all views to `@MainActor`.
- Cross-platform availability of scroll APIs. Mitigation: rely only on APIs
  present on iOS 17 / macOS 14.

## Checklist

- [ ] `WalkthroughModel` with navigation + action dispatch + events.
- [ ] `WalkthroughPageProxy`.
- [ ] `WalkthroughContainer` pager + `PageChrome`.
- [ ] `WalkthroughImageView`, `InfoPageView`, `WalkthroughPageView` (kind switch).
- [ ] `ParallaxModifier`.
- [ ] `WalkthroughView` public API + custom page registration.
- [ ] Model unit tests (navigation, action outcomes, events) — `@MainActor`.
- [ ] `swift build` and `swift test` green.

## Acceptance criteria

- A `Walkthrough` of info pages renders and pages horizontally on iOS and macOS.
- Navigation (next/prev/goto/finish) and `onPageChange`/`onFinish` fire correctly.
- `perform(action:)` transitions state and applies every `StepOutcome` case.
- All existing tests still pass; new model tests pass.
