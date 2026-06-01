//
//  ParallaxModifier.swift
//  VXWalkthrough
//

import SwiftUI

/// Applies a scroll-driven parallax (scale + fade) to a page, replacing the
/// legacy `CATransform3D` animations. Honors reduce-motion and the theme.
struct ParallaxModifier: ViewModifier {
    let motion: WalkthroughTheme.MotionStyle
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isActive: Bool { motion != .none && !reduceMotion }

    private var minScale: CGFloat {
        switch motion {
        case .none: 1
        case .subtle: 0.96
        case .standard: 0.86
        }
    }

    func body(content: Content) -> some View {
        let active = isActive
        let scale = minScale
        return content.scrollTransition(.interactive) { view, phase in
            view
                .opacity(active ? (phase.isIdentity ? 1 : 0.4) : 1)
                .scaleEffect(active ? (phase.isIdentity ? 1 : scale) : 1)
        }
    }
}

extension View {
    func walkthroughParallax(_ motion: WalkthroughTheme.MotionStyle) -> some View {
        modifier(ParallaxModifier(motion: motion))
    }
}
