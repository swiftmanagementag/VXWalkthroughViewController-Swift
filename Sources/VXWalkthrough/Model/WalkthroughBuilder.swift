//
//  WalkthroughBuilder.swift
//  VXWalkthrough
//
//  A declarative result-builder DSL that produces an ordered list of
//  `WalkthroughStep` values.
//

import Foundation

/// A type that can be converted into one or more walkthrough steps.
public protocol WalkthroughStepConvertible {
    func makeSteps() -> [WalkthroughStep]
}

extension WalkthroughStep: WalkthroughStepConvertible {
    public func makeSteps() -> [WalkthroughStep] { [self] }
}

/// Result builder that assembles `WalkthroughStepConvertible` components.
@resultBuilder
public enum WalkthroughBuilder {
    public static func buildBlock(_ components: [WalkthroughStepConvertible]...) -> [WalkthroughStepConvertible] {
        components.flatMap { $0 }
    }

    public static func buildExpression(_ expression: WalkthroughStepConvertible) -> [WalkthroughStepConvertible] {
        [expression]
    }

    public static func buildExpression(_ expression: [WalkthroughStepConvertible]) -> [WalkthroughStepConvertible] {
        expression
    }

    public static func buildOptional(_ component: [WalkthroughStepConvertible]?) -> [WalkthroughStepConvertible] {
        component ?? []
    }

    public static func buildEither(first component: [WalkthroughStepConvertible]) -> [WalkthroughStepConvertible] {
        component
    }

    public static func buildEither(second component: [WalkthroughStepConvertible]) -> [WalkthroughStepConvertible] {
        component
    }

    public static func buildArray(_ components: [[WalkthroughStepConvertible]]) -> [WalkthroughStepConvertible] {
        components.flatMap { $0 }
    }

    public static func buildLimitedAvailability(_ component: [WalkthroughStepConvertible]) -> [WalkthroughStepConvertible] {
        component
    }
}

/// A fully-described walkthrough: an ordered set of steps plus its theme.
public struct Walkthrough: Sendable, Equatable {
    public var steps: [WalkthroughStep]
    public var theme: WalkthroughTheme

    /// Build a walkthrough from explicit steps.
    public init(theme: WalkthroughTheme = .default, steps: [WalkthroughStep]) {
        self.theme = theme
        self.steps = steps.sortedBySort()
    }

    /// Build a walkthrough using the declarative DSL.
    public init(
        theme: WalkthroughTheme = .default,
        @WalkthroughBuilder _ content: () -> [WalkthroughStepConvertible]
    ) {
        self.theme = theme
        steps = content().flatMap { $0.makeSteps() }.sortedBySort()
    }

    public var isEmpty: Bool { steps.isEmpty }
    public var count: Int { steps.count }
}
