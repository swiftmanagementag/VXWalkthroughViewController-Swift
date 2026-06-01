//
//  NoopPermissionRequester.swift
//  VXWalkthrough
//
//  The core's default permission requester. It references no system frameworks
//  and reports every permission as `.unavailable` (which `PermissionResolver`
//  maps to `.advance`). This keeps the core product free of privacy-sensitive
//  API references; opt into real system permissions via the optional
//  `VXWalkthroughPermissions` product and its per-kind traits.
//

import Foundation

/// A permission requester that performs no system calls and reports every kind
/// as `.unavailable`. Used as the environment default so `PermissionPage`s
/// degrade gracefully (they advance) until a real requester is injected.
public struct NoopPermissionRequester: PermissionRequesting {
    public init() {}

    public func status(for _: PermissionKind) async -> PermissionStatus { .unavailable }

    @discardableResult
    public func request(_: PermissionKind) async -> PermissionStatus { .unavailable }
}
