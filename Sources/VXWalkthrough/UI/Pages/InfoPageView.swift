//
//  InfoPageView.swift
//  VXWalkthrough
//

import SwiftUI

/// The display-only page: image + styled title and optional body.
struct InfoPageView: View {
    let step: WalkthroughStep
    @Environment(\.walkthroughTheme) private var theme

    var body: some View {
        VStack(spacing: 24) {
            Spacer(minLength: 0)

            if !step.image.isEmpty {
                WalkthroughImageView(image: step.image, style: theme.imageStyle)
            }

            VStack(spacing: 24) {
                if !step.title.isEmpty {
                    Text(step.title.attributedString())
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
                        .accessibilityIdentifier("walkthrough.page.body")
                }
            }
            .measureWalkthroughContentHeight()

            Spacer(minLength: 0)
        }
        .padding(.horizontal, 32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
