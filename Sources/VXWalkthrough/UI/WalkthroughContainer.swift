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
    @Environment(\.walkthroughTheme) private var theme

    var body: some View {
        ZStack {
            theme.background.ignoresSafeArea()

            pager

            PageChrome(model: model, showsClose: showsClose)
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

    private var pager: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
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
