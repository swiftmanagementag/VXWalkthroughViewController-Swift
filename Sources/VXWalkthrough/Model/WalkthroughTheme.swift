//
//  WalkthroughTheme.swift
//  VXWalkthrough
//

import SwiftUI

/// Visual styling for a walkthrough. A `Sendable` value type injected through
/// the SwiftUI environment.
public struct WalkthroughTheme: Sendable, Equatable {
    /// How page images are presented.
    public enum ImageStyle: Sendable, Equatable {
        /// Circular, bordered image (the legacy default).
        case round
        /// Image fills the available space.
        case fullBleed
        /// Rounded-rectangle card.
        case card
        /// Full-width, aspect-fit image: the whole illustration is shown
        /// without cropping (ideal for wide artwork).
        case fit
    }

    /// Motion intensity for scroll-driven parallax effects.
    public enum MotionStyle: Sendable, Equatable {
        case none
        case subtle
        case standard
    }

    public var background: Color
    public var accent: Color
    public var titleColor: Color
    public var bodyColor: Color
    public var titleFont: Font
    public var bodyFont: Font
    public var imageStyle: ImageStyle
    public var motion: MotionStyle
    public var buttonCornerRadius: CGFloat
    /// Adopt iOS 26 Liquid Glass chrome when available (falls back gracefully).
    public var usesLiquidGlass: Bool

    public init(
        background: Color = .black,
        accent: Color = .accentColor,
        titleColor: Color = .white,
        bodyColor: Color = .white.opacity(0.85),
        titleFont: Font = .system(size: 24, weight: .regular),
        bodyFont: Font = .body,
        imageStyle: ImageStyle = .round,
        motion: MotionStyle = .standard,
        buttonCornerRadius: CGFloat = 12,
        usesLiquidGlass: Bool = true
    ) {
        self.background = background
        self.accent = accent
        self.titleColor = titleColor
        self.bodyColor = bodyColor
        self.titleFont = titleFont
        self.bodyFont = bodyFont
        self.imageStyle = imageStyle
        self.motion = motion
        self.buttonCornerRadius = buttonCornerRadius
        self.usesLiquidGlass = usesLiquidGlass
    }

    /// The default theme.
    public static let `default` = WalkthroughTheme()
}

// MARK: - Environment

private struct WalkthroughThemeKey: EnvironmentKey {
    static let defaultValue = WalkthroughTheme.default
}

public extension EnvironmentValues {
    var walkthroughTheme: WalkthroughTheme {
        get { self[WalkthroughThemeKey.self] }
        set { self[WalkthroughThemeKey.self] = newValue }
    }
}

public extension View {
    /// Injects a `WalkthroughTheme` into the environment.
    func walkthroughTheme(_ theme: WalkthroughTheme) -> some View {
        environment(\.walkthroughTheme, theme)
    }
}
