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

    /// Fill, label color, and corner treatment for a call-to-action button.
    ///
    /// Lets the host guarantee adequate contrast for the primary CTA against any
    /// brand background, independent of the title/body colors.
    public struct WalkthroughButtonStyle: Sendable, Equatable {
        /// Corner treatment for the button.
        public enum CornerStyle: Sendable, Equatable {
            /// Rounded rectangle with the given corner radius.
            case radius(CGFloat)
            /// Fully-rounded (pill) shape.
            case capsule
        }

        /// Button fill color.
        public var background: Color
        /// Label (and progress spinner) color.
        public var foreground: Color
        /// Corner treatment.
        public var cornerStyle: CornerStyle

        public init(
            background: Color,
            foreground: Color = .white,
            cornerStyle: CornerStyle = .radius(12)
        ) {
            self.background = background
            self.foreground = foreground
            self.cornerStyle = cornerStyle
        }
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
    /// Fill / label / corner for primary CTA buttons. `nil` keeps the legacy
    /// look (filled with `accent`, white label, `buttonCornerRadius`).
    public var actionButtonStyle: WalkthroughButtonStyle?
    /// Color of the unselected page-indicator dots. `nil` falls back to
    /// `titleColor` (rendered at 35% opacity, matching the legacy look).
    public var pageIndicatorColor: Color?
    /// Color of the selected page-indicator dot. `nil` falls back to
    /// `titleColor` at full opacity.
    public var pageIndicatorSelectedColor: Color?
    /// Tint for the Next / Previous / Close controls. `nil` falls back to
    /// `titleColor`.
    public var navControlTint: Color?
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
        actionButtonStyle: WalkthroughButtonStyle? = nil,
        pageIndicatorColor: Color? = nil,
        pageIndicatorSelectedColor: Color? = nil,
        navControlTint: Color? = nil,
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
        self.actionButtonStyle = actionButtonStyle
        self.pageIndicatorColor = pageIndicatorColor
        self.pageIndicatorSelectedColor = pageIndicatorSelectedColor
        self.navControlTint = navControlTint
        self.usesLiquidGlass = usesLiquidGlass
    }

    /// The default theme.
    public static let `default` = WalkthroughTheme()

    // MARK: Resolved values

    /// The primary-button style to use, resolving the legacy fallback (filled
    /// with `accent`, white label, `buttonCornerRadius`) when none is set.
    public var resolvedActionButtonStyle: WalkthroughButtonStyle {
        actionButtonStyle
            ?? WalkthroughButtonStyle(
                background: accent,
                foreground: .white,
                cornerStyle: .radius(buttonCornerRadius)
            )
    }

    /// Tint for the Next / Previous / Close controls (falls back to `titleColor`).
    public var resolvedNavControlTint: Color { navControlTint ?? titleColor }

    /// Selected page-indicator dot color (falls back to `titleColor`).
    public var resolvedPageIndicatorSelectedColor: Color {
        pageIndicatorSelectedColor ?? titleColor
    }
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
