//
//  PickerPageView.swift
//  VXWalkthrough
//

import SwiftUI

/// An option-selection carousel: step through options and confirm a choice.
struct PickerPageView: View {
    let step: WalkthroughStep
    let spec: PickerSpec
    let proxy: WalkthroughPageProxy

    @State private var activeIndex = 0
    @Environment(\.walkthroughTheme) private var theme

    private var activeOption: PickerOption? { spec.option(at: activeIndex) }

    var body: some View {
        PageScaffold(step: step, state: proxy.state) {
            VStack(spacing: 20) {
                if let option = activeOption {
                    HStack(spacing: 24) {
                        carouselButton(system: "chevron.left", id: "walkthrough.picker.previous") {
                            if activeIndex > 0 { activeIndex -= 1 }
                        }
                        .opacity(activeIndex > 0 ? 1 : 0.25)
                        .disabled(activeIndex == 0)

                        Text(option.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(theme.titleColor)
                            .frame(minWidth: 120)
                            .multilineTextAlignment(.center)
                            .accessibilityIdentifier("walkthrough.picker.option")

                        carouselButton(system: "chevron.right", id: "walkthrough.picker.next") {
                            if activeIndex < spec.options.count - 1 { activeIndex += 1 }
                        }
                        .opacity(activeIndex < spec.options.count - 1 ? 1 : 0.25)
                        .disabled(activeIndex >= spec.options.count - 1)
                    }

                    WalkthroughPrimaryButton(
                        title: spec.buttonTitle,
                        isLoading: proxy.state.isLoading,
                        isEnabled: option.isAvailable
                    ) {
                        Task { await proxy.submit(.picker(selectedID: option.id)) }
                    }
                }
            }
        }
        .onAppear { activeIndex = spec.initialIndex }
    }

    private func carouselButton(system: String, id: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.title2.weight(.bold))
                .foregroundStyle(theme.titleColor)
                .frame(width: 44, height: 44)
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(id)
    }
}
