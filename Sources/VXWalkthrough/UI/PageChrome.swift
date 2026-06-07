//
//  PageChrome.swift
//  VXWalkthrough
//

import SwiftUI

/// Navigation chrome overlaid on the pager: close button, page indicator, and
/// previous/next controls.
struct PageChrome: View {
    @Bindable var model: WalkthroughModel
    let showsClose: Bool

    @Environment(\.walkthroughTheme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            if showsClose {
                HStack {
                    Spacer()
                    Button {
                        model.finish()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .padding(10)
                    }
                    .glassButtonStyleIfAvailable()
                    .tint(theme.resolvedNavControlTint)
                    .accessibilityIdentifier("walkthrough.close")
                    .accessibilityLabel("Close")
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
            }

            Spacer()

            HStack {
                navButton(
                    system: "chevron.left",
                    id: "walkthrough.previous",
                    label: "Previous",
                    hidden: model.isFirst
                ) { model.goPrevious() }

                Spacer()

                if model.numberOfPages > 1 {
                    PageIndicator(
                        count: model.numberOfPages,
                        current: model.currentIndex,
                        baseColor: theme.pageIndicatorColor,
                        selectedColor: theme.resolvedPageIndicatorSelectedColor,
                        fallbackColor: theme.titleColor
                    )
                }

                Spacer()

                navButton(
                    system: model.isLast ? "checkmark" : "chevron.right",
                    id: "walkthrough.next",
                    label: model.isLast ? "Done" : "Next",
                    hidden: false
                ) { model.goNext() }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func navButton(
        system: String,
        id: String,
        label: String,
        hidden: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title3.weight(.semibold))
                .frame(width: 44, height: 44)
        }
        .glassButtonStyleIfAvailable()
        .tint(theme.resolvedNavControlTint)
        .opacity(hidden ? 0 : 1)
        .disabled(hidden)
        .accessibilityIdentifier(id)
        .accessibilityLabel(label)
    }
}

private struct PageIndicator: View {
    let count: Int
    let current: Int
    /// Explicit unselected-dot color, if the theme set one.
    let baseColor: Color?
    /// Resolved selected-dot color.
    let selectedColor: Color
    /// Fallback used for unselected dots when `baseColor` is `nil` (legacy look:
    /// `titleColor` at 35% opacity).
    let fallbackColor: Color

    private func dotColor(selected: Bool) -> Color {
        if selected { return selectedColor }
        return baseColor ?? fallbackColor.opacity(0.35)
    }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(0 ..< count, id: \.self) { index in
                Circle()
                    .fill(dotColor(selected: index == current))
                    .frame(width: 8, height: 8)
            }
        }
        .accessibilityElement()
        .accessibilityLabel("Page \(current + 1) of \(count)")
        .accessibilityIdentifier("walkthrough.pageIndicator")
    }
}

private extension View {
    /// Applies the iOS 26 Liquid Glass button style when available, otherwise a
    /// neutral bordered style.
    @ViewBuilder
    func glassButtonStyleIfAvailable() -> some View {
        #if compiler(>=6.2)
            if #available(iOS 26.0, macCatalyst 26.0, macOS 26.0, *) {
                buttonStyle(.glass)
            } else {
                buttonStyle(.bordered)
            }
        #else
            buttonStyle(.bordered)
        #endif
    }
}
