//
//  VXWalkthroughScanner.swift
//  VXWalkthroughScanner
//
//  Optional QR / barcode scanning support for VXWalkthrough.
//  Apply `.walkthroughQRScanner()` to a `WalkthroughView` to enable scanning on
//  login pages that set `scanEnabled`. iOS / Mac Catalyst only.
//

import Foundation

public enum VXWalkthroughScanner {
    /// Whether camera-based scanning is supported on this platform.
    public static let isAvailable: Bool = {
        #if os(iOS)
            return true
        #else
            return false
        #endif
    }()
}
