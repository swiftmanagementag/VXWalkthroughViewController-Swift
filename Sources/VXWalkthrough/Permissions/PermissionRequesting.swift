//
//  PermissionRequesting.swift
//  VXWalkthrough
//

import Foundation

/// The resolved authorization status for a permission.
public enum PermissionStatus: Sendable, Equatable {
    case notDetermined
    case granted
    case denied
    case restricted
    /// The permission is not applicable on this platform/configuration.
    case unavailable
}

/// Abstraction over system permission requests, allowing the core framework to
/// remain dependency-light and fully testable with mocks.
public protocol PermissionRequesting: Sendable {
    func status(for kind: PermissionKind) async -> PermissionStatus
    @discardableResult
    func request(_ kind: PermissionKind) async -> PermissionStatus
}

/// Maps a resolved permission status to a step outcome (pure / testable).
public enum PermissionResolver {
    public static func outcome(for status: PermissionStatus, spec: PermissionSpec) -> StepOutcome {
        switch status {
        case .granted:
            .success(spec.grantedMessage)
        case .denied, .restricted:
            .failure(spec.deniedMessage)
        case .unavailable:
            .advance
        case .notDetermined:
            .none
        }
    }
}
