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
                    WalkthroughPageView(
                        step: step,
                        proxy: WalkthroughPageProxy(model: model, stepID: step.id),
                        customProviders: customProviders
                    )
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
        .ignoresSafeArea(edges: theme.imageStyle == .fullBleed ? .all : [])
    }
}
