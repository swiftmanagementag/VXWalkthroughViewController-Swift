//
//  HostingControllerTests.swift
//  VXWalkthroughTests
//
//  Smoke coverage for the UIKit interop layer. Gated to UIKit platforms; on the
//  macOS host these tests are compiled out and run via `xcodebuild test` on a
//  simulator instead.
//

#if canImport(UIKit)

    import SwiftUI
    import UIKit
    import Testing
    import VXWalkthrough
    import VXWalkthroughUIKit

    @MainActor
    struct HostingControllerTests {
        private func sampleWalkthrough() -> Walkthrough {
            Walkthrough {
                InfoPage("welcome", title: "Welcome")
                ActionPage("go", title: "Ready?", buttonTitle: "Start")
            }
        }

        @Test func initialisesWithFullScreenPresentation() {
            let controller = WalkthroughHostingController(sampleWalkthrough())
            #expect(controller.modalPresentationStyle == .fullScreen)
        }

        @Test func loadsViewHierarchyWithoutCrashing() {
            let controller = WalkthroughHostingController(sampleWalkthrough())
            controller.loadViewIfNeeded()
            #expect(controller.view != nil)
        }

        @Test func appliesConfigureTransform() {
            var configured = false
            let controller = WalkthroughHostingController(
                sampleWalkthrough(),
                configure: { view in
                    configured = true
                    return AnyView(view)
                }
            )
            controller.loadViewIfNeeded()
            #expect(configured)
        }
    }

#endif
