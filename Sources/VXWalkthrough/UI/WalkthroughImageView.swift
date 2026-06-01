//
//  WalkthroughImageView.swift
//  VXWalkthrough
//

import SwiftUI

/// Renders a `WalkthroughImage` according to the theme's image style.
struct WalkthroughImageView: View {
    let image: WalkthroughImage
    let style: WalkthroughTheme.ImageStyle

    @Environment(\.walkthroughImageBundle) private var imageBundle

    var body: some View {
        imageContent
            .modifier(StyleModifier(style: style))
            .accessibilityHidden(true)
    }

    @ViewBuilder
    private var imageContent: some View {
        switch image {
        case let .named(name):
            namedImage(name)
        case let .system(name):
            Image(systemName: name).resizable().scaledToFit().padding(24)
        case let .remote(url):
            AsyncImage(url: url) { phase in
                switch phase {
                case let .success(image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.clear
                case .empty:
                    ProgressView()
                @unknown default:
                    Color.clear
                }
            }
        case .none:
            Color.clear
        }
    }

    /// Resolves a named image through the bundle cascade (asset catalog, then
    /// loose `.png`/`.jpg`/`.jpeg`), falling back to `Color.clear` on a miss.
    @ViewBuilder
    private func namedImage(_ name: String) -> some View {
        #if canImport(UIKit)
            if let platformImage = WalkthroughImageLoader.loadImage(named: name, preferredBundle: imageBundle) {
                Image(uiImage: platformImage).resizable().scaledToFill()
            } else {
                Color.clear
            }
        #elseif canImport(AppKit)
            if let platformImage = WalkthroughImageLoader.loadImage(named: name, preferredBundle: imageBundle) {
                Image(nsImage: platformImage).resizable().scaledToFill()
            } else {
                Color.clear
            }
        #else
            Color.clear
        #endif
    }

    private struct StyleModifier: ViewModifier {
        let style: WalkthroughTheme.ImageStyle

        func body(content: Content) -> some View {
            switch style {
            case .round:
                content
                    .frame(width: 160, height: 160)
                    .clipShape(.circle)
                    .overlay(Circle().stroke(.white, lineWidth: 3))
                    .shadow(color: .black.opacity(0.3), radius: 6)
            case .card:
                content
                    .frame(maxWidth: 320, maxHeight: 320)
                    .clipShape(.rect(cornerRadius: 20))
                    .shadow(color: .black.opacity(0.25), radius: 8)
            case .fullBleed:
                content
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
    }
}
