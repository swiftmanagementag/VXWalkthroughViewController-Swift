//
//  VXWalkthroughScanner.swift
//  VXWalkthroughScanner
//
//  Optional QR / barcode scanning support for VXWalkthrough.
//  Implemented in Phase 5 (VisionKit DataScannerViewController with an
//  AVFoundation fallback). iOS / Mac Catalyst only.
//

import Foundation

public enum VXWalkthroughScanner {
    public static let isAvailable: Bool = {
        #if os(iOS)
            return true
        #else
            return false
        #endif
    }()
}
