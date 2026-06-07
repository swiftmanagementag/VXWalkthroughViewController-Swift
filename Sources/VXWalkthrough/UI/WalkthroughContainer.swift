//
//  WalkthroughContainer.swift
//  VXWalkthrough
//
//  The cross-platform horizontal pager that hosts the pages, plus chrome.
//

import SwiftUI

struct WalkthroughContainer: View {
    @Bindable var model: WalkthroughModel
    let showsClose: Bool
    let customProviders: [String: @MainActor (WalkthroughPageProxy) -> AnyView]

    @State private var scrolledID: String?
    // Tallest non-image content across pages, and the diameter resolved from
    // it. Recomputed on measurement and on container size change (rotation,
    // iPad multitasking, Mac Catalyst resize).
    @State private var maxContentHeight: CGFloat = 0
    @State private var resolvedCircleDiameter: CGFloat?
    @Environment(\.walkthroughTheme) private var theme

    /// Vertical space reserved for the page chrome (page indicator + nav) and
    /// the image-to-content spacing, kept clear when sizing the circle.
    private static let chromeReserve: CGFloat = 140

    var body: some View {
        GeometryReader { geo in
            ZStack {
                theme.background.ignoresSafeArea()

                pager

                PageChrome(model: model, showsClose: showsClose)
            }
            .onPreferenceChange(PageContentHeightPreferenceKey.self) { newValue in
                maxContentHeight = newValue
                updateCircleDiameter(containerSize: geo.size)
            }
            .onChange(of: geo.size) { _, newSize in
                // Rotation / window resize: re-derive the circle diameter.
                updateCircleDiameter(containerSize: newSize)
            }
            .onChange(of: geo.size.width) { _, _ in
                // Rotation / window resize changes the page width, which leaves
                // the paging scroll view sitting between pages. Re-snap to the
                // current page at the new width so the content stays aligned.
                realignToCurrentPage()
            }
            .environment(\.walkthroughResolvedCircleDiameter, resolvedCircleDiameter)
        }
        .environment(\.walkthroughTheme, theme)
        .onAppear { scrolledID = model.currentStepID }
        .onChange(of: model.currentIndex) { _, _ in
            // Programmatic navigation: animate the scroll to the new page.
            withAnimation(.easeInOut) { scrolledID = model.currentStepID }
        }
        .onChange(of: scrolledID) { _, newValue in
            // User-driven swipe: sync the model.
            model.syncIndex(toStepID: newValue)
        }
    }

    /// Re-aligns the pager to the current page after a size change. Clearing
    /// then restoring the bound id (on the next runloop tick, once the pages
    /// have re-laid-out at the new width) forces the paging scroll view to
    /// re-snap to the safe-area-aware page boundary — assigning the same id
    /// would be a no-op. Animation is disabled so the correction is invisible.
    private func realignToCurrentPage() {
        let target = model.currentStepID
        scrolledID = nil
        DispatchQueue.main.async {
            var transaction = Transaction()
            transaction.disablesAnimations = true
            withTransaction(transaction) {
                scrolledID = target
            }
        }
    }

    /// Resolves the uniform circle diameter for the current measurements: the
    /// largest circle that fits in the space left after the most-constrained
    /// page's content and the chrome reserve.
    private func updateCircleDiameter(containerSize: CGSize) {
        guard theme.imageStyle == .round, containerSize.height > 0 else {
            resolvedCircleDiameter = nil
            return
        }
        let leftover = containerSize.height - maxContentHeight - Self.chromeReserve
        let diameter = CircleSizing.diameter(
            minLeftoverHeight: leftover,
            width: containerSize.width,
            style: theme.circleStyle
        )
        guard resolvedCircleDiameter != diameter else { return }
        withAnimation(.easeInOut(duration: 0.2)) {
            resolvedCircleDiameter = diameter
        }
    }

    private var pager: some View {
        ScrollView(.horizontal) {
            // Eager HStack (not Lazy) so every page is laid out and reports its
            // image-slot height up front, letting the container pick a single
            // circle diameter that fits across all pages.
            HStack(spacing: 0) {
                ForEach(model.steps) { step in
                    pageView(for: step)
                        .containerRelativeFrame(.horizontal)
                        .walkthroughParallax(theme.motion)
                        .id(step.id)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $scrolledID)
        .scrollIndicators(.hidden)
        // Span the full width so each page equals the viewport and paging snaps
        // edge-to-edge. Respecting the horizontal safe area would make pages
        // narrower than the viewport (e.g. the landscape notch inset), leaving
        // a sliver of the adjacent page and misaligning content. Page content
        // keeps clear of the notch via its own horizontal padding.
        .ignoresSafeArea(edges: theme.imageStyle == .fullBleed ? .all : .horizontal)
    }

    /// Builds a single page, wiring its proxy, the `walkthroughAdvance`
    /// environment action, and any per-step theme override.
    ///
    /// A per-step `theme` replaces the walkthrough theme for that page's content
    /// (background, title/body colors + fonts, button). The overlaid page chrome
    /// (indicator / nav) and the cross-page circle diameter are still driven by
    /// the walkthrough's base theme.
    @ViewBuilder
    private func pageView(for step: WalkthroughStep) -> some View {
        let proxy = WalkthroughPageProxy(model: model, stepID: step.id)
        let stepTheme = step.theme ?? theme
        WalkthroughPageView(
            step: step,
            proxy: proxy,
            customProviders: customProviders
        )
        // Paint the overridden background so a per-step theme is visible over the
        // container's base background. Skipped when no override (zero change).
        .background(step.theme.map(\.background) ?? Color.clear)
        .walkthroughTheme(stepTheme)
        .environment(
            \.walkthroughAdvance,
            WalkthroughAdvanceAction(
                advance: { proxy.advance() },
                previous: { proxy.previous() },
                finish: { proxy.finish() }
            )
        )
    }
}
