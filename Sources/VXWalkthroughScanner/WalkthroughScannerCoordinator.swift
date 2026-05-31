//
//  WalkthroughScannerCoordinator.swift
//  VXWalkthroughScanner
//

import Foundation
import Observation

/// Coordinates presenting the scanner and bridging its result back to the
/// async `walkthroughScanHandler`.
@MainActor
@Observable
final class WalkthroughScannerCoordinator {
    var isPresented = false
    private var continuation: CheckedContinuation<String?, Never>?

    /// Presents the scanner and suspends until a result (or cancellation).
    func scan() async -> String? {
        // If a previous scan is somehow pending, cancel it first.
        continuation?.resume(returning: nil)
        continuation = nil
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            isPresented = true
        }
    }

    /// Completes the current scan with a parsed value (or nil if cancelled).
    func finish(with code: String?) {
        isPresented = false
        let value = code.map { ScanResultParser.parse($0).value }
        continuation?.resume(returning: value)
        continuation = nil
    }
}
