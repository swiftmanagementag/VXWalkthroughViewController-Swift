//
//  VXWalkthroughUIKit.swift
//  VXWalkthroughUIKit
//
//  Optional UIKit interop for VXWalkthrough (UIHostingController convenience).
//  Implemented in Phase 6. iOS / Mac Catalyst only.
//

import Foundation

public enum VXWalkthroughUIKit {
    public static let isAvailable: Bool = {
        #if canImport(UIKit)
            return true
        #else
            return false
        #endif
    }()
}
