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
        /// Full-width, aspect-fit image with rounded corners: the whole
        /// illustration is shown without cropping (ideal for wide artwork).
        case fit
    }

    /// Styling for the circular (`ImageStyle.round`) image.
    ///
    /// The circle's diameter is resolved at runtime to the largest size that
    /// fits across every page (leaving `margin` on all sides), capped by
    /// `maxDiameter`, and recalculated on rotation / size change. These knobs
    /// configure the cap, the margin, and the border/shadow chrome. Defaults
    /// mirror the pre-2.x look (white border, soft shadow).
    public struct CircleStyle: Sendable, Equatable {
        /// Upper bound on the circle diameter. `nil` means uncapped (the circle
        /// grows to fill the available space minus `margin`).
        public var maxDiameter: CGFloat?
        /// Space left around the circle on every side when sizing it.
        public var margin: CGFloat
        /// Border width (0 hides the border).
        public var borderWidth: CGFloat
        /// Border color.
        public var borderColor: Color
        /// Whether to draw a soft drop shadow behind the circle.
        public var showsShadow: Bool

        public init(
            maxDiameter: CGFloat? = 320,
            margin: CGFloat = 24,
            borderWidth: CGFloat = 3,
            borderColor: Color = .white,
            showsShadow: Bool = true
        ) {
            self.maxDiameter = maxDiameter
            self.margin = margin
            self.borderWidth = borderWidth
            self.borderColor = borderColor
            self.showsShadow = showsShadow
        }

        /// The default circle style (responsive, white 3pt border, soft shadow).
        public static let `default` = CircleStyle()
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
    /// Styling for the circular (`ImageStyle.round`) image.
    public var circleStyle: CircleStyle
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
        circleStyle: CircleStyle = .default,
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
        self.circleStyle = circleStyle
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
