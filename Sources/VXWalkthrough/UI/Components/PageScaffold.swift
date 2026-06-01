//
//  PageScaffold.swift
//  VXWalkthrough
//
//  Shared layout for interactive pages: image + title + body + content slot,
//  with an inline state message for success/failure.
//

import SwiftUI

struct PageScaffold<Content: View>: View {
    let step: WalkthroughStep
    let state: StepState
    @ViewBuilder var content: () -> Content

    @Environment(\.walkthroughTheme) private var theme

    var body: some View {
        VStack(spacing: 20) {
            Spacer(minLength: 0)

            if !step.image.isEmpty {
                WalkthroughImageView(image: step.image, style: theme.imageStyle)
            }

            VStack(spacing: 20) {
                if !displayTitle.isEmpty {
                    Text(displayTitleAttributed)
                        .font(theme.titleFont)
                        .foregroundStyle(theme.titleColor)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("walkthrough.page.title")
                }

                if let body = step.body, !body.isEmpty {
                    Text(body.attributedString())
                        .font(theme.bodyFont)
                        .foregroundStyle(theme.bodyColor)
                        .multilineTextAlignment(.center)
                }

                // The success/failure message replaces controls when terminal.
                if state.isTerminal, let message = state.message, !message.isEmpty {
                    Text(message)
                        .font(theme.bodyFont)
                        .foregroundStyle(isFailure ? .red : theme.bodyColor)
                        .multilineTextAlignment(.center)
                        .accessibilityIdentifier("walkthrough.page.stateMessage")
                } else {
                    content()
                }
            }
            .measureWalkthroughContentHeight()

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var isFailure: Bool {
        if case .failure = state { return true }
        return false
    }

    private var displayTitle: AttributedTitle { step.title }
    private var displayTitleAttributed: AttributedString { step.title.attributedString() }
}
