//
//  PermissionEnvironment.swift
//  VXWalkthrough
//

import SwiftUI

private struct PermissionRequesterKey: EnvironmentKey {
    // Defaults to a no-op so the core product references no privacy-sensitive
    // frameworks. Inject `SystemPermissionRequester` from the optional
    // `VXWalkthroughPermissions` product (with the relevant traits enabled) to
    // request real system permissions.
    static let defaultValue: any PermissionRequesting = NoopPermissionRequester()
}

public extension EnvironmentValues {
    /// The permission requester used by permission pages. Inject a mock in tests
    /// or a custom implementation to add logging/analytics.
    var walkthroughPermissionRequester: any PermissionRequesting {
        get { self[PermissionRequesterKey.self] }
        set { self[PermissionRequesterKey.self] = newValue }
    }
}

public extension View {
    /// Overrides the permission requester used by permission pages.
    func walkthroughPermissionRequester(_ requester: any PermissionRequesting) -> some View {
        environment(\.walkthroughPermissionRequester, requester)
    }
}

/// A handler that presents a scanner and returns the scanned string (or `nil`).
/// Supplied by the optional `VXWalkthroughScanner` module (Phase 5).
public typealias WalkthroughScanHandler = @MainActor () async -> String?

private struct ScanHandlerKey: EnvironmentKey {
    static let defaultValue: WalkthroughScanHandler? = nil
}

public extension EnvironmentValues {
    var walkthroughScanHandler: WalkthroughScanHandler? {
        get { self[ScanHandlerKey.self] }
        set { self[ScanHandlerKey.self] = newValue }
    }
}

public extension View {
    /// Provides a scan handler that login pages use when `scanEnabled` is set.
    func walkthroughScanHandler(_ handler: @escaping WalkthroughScanHandler) -> some View {
        environment(\.walkthroughScanHandler, handler)
    }
}
