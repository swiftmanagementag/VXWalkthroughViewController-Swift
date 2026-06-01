//
//  SystemPermissionRequester.swift
//  VXWalkthrough
//
//  Default `PermissionRequesting` implementation backed by the system
//  frameworks. iOS / Mac Catalyst only; other platforms report `.unavailable`.
//

import Foundation

#if canImport(UserNotifications)
    import UserNotifications
#endif
#if canImport(AVFoundation)
    import AVFoundation
#endif
#if canImport(Photos)
    import Photos
#endif
#if canImport(Contacts)
    import Contacts
#endif
#if canImport(CoreLocation)
    import CoreLocation
#endif
#if canImport(AppTrackingTransparency)
    import AppTrackingTransparency
#endif

public struct SystemPermissionRequester: PermissionRequesting {
    public init() {}

    public func status(for kind: PermissionKind) async -> PermissionStatus {
        #if os(iOS)
            switch kind {
            case .notifications: return await notificationStatus()
            case .camera: return captureStatus(for: .video)
            case .microphone: return captureStatus(for: .audio)
            case .photoLibrary: return photoStatus()
            case .locationWhenInUse: return locationStatus()
            case .contacts: return contactsStatus()
            case .tracking: return trackingStatus()
            }
        #else
            return .unavailable
        #endif
    }

    @discardableResult
    public func request(_ kind: PermissionKind) async -> PermissionStatus {
        #if os(iOS)
            switch kind {
            case .notifications: return await requestNotifications()
            case .camera: return await requestCapture(.video)
            case .microphone: return await requestCapture(.audio)
            case .photoLibrary: return await requestPhotos()
            case .locationWhenInUse: return await requestLocation()
            case .contacts: return await requestContacts()
            case .tracking: return await requestTracking()
            }
        #else
            return .unavailable
        #endif
    }
}

#if os(iOS)

    // MARK: Notifications

    private extension SystemPermissionRequester {
        func notificationStatus() async -> PermissionStatus {
            let settings = await UNUserNotificationCenter.current().notificationSettings()
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral: return .granted
            case .denied: return .denied
            case .notDetermined: return .notDetermined
            @unknown default: return .notDetermined
            }
        }

        func requestNotifications() async -> PermissionStatus {
            do {
                let granted = try await UNUserNotificationCenter.current()
                    .requestAuthorization(options: [.alert, .badge, .sound])
                return granted ? .granted : .denied
            } catch {
                return .denied
            }
        }
    }

    // MARK: Camera / Microphone

    private extension SystemPermissionRequester {
        func captureStatus(for media: AVMediaType) -> PermissionStatus {
            switch AVCaptureDevice.authorizationStatus(for: media) {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .notDetermined
            }
        }

        func requestCapture(_ media: AVMediaType) async -> PermissionStatus {
            let granted = await AVCaptureDevice.requestAccess(for: media)
            return granted ? .granted : .denied
        }
    }

    // MARK: Photos

    private extension SystemPermissionRequester {
        func photoStatus() -> PermissionStatus {
            map(PHPhotoLibrary.authorizationStatus(for: .readWrite))
        }

        func requestPhotos() async -> PermissionStatus {
            let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
            return map(status)
        }

        func map(_ status: PHAuthorizationStatus) -> PermissionStatus {
            switch status {
            case .authorized, .limited: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .notDetermined
            }
        }
    }

    // MARK: Contacts

    private extension SystemPermissionRequester {
        func contactsStatus() -> PermissionStatus {
            switch CNContactStore.authorizationStatus(for: .contacts) {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            #if compiler(>=5.9)
                case .limited: return .granted
            #endif
            @unknown default: return .notDetermined
            }
        }

        func requestContacts() async -> PermissionStatus {
            do {
                let granted = try await CNContactStore().requestAccess(for: .contacts)
                return granted ? .granted : .denied
            } catch {
                return .denied
            }
        }
    }

    // MARK: Tracking (ATT)

    private extension SystemPermissionRequester {
        func trackingStatus() -> PermissionStatus {
            map(ATTrackingManager.trackingAuthorizationStatus)
        }

        func requestTracking() async -> PermissionStatus {
            let status = await ATTrackingManager.requestTrackingAuthorization()
            return map(status)
        }

        func map(_ status: ATTrackingManager.AuthorizationStatus) -> PermissionStatus {
            switch status {
            case .authorized: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .notDetermined
            }
        }
    }

    // MARK: Location

    private extension SystemPermissionRequester {
        func locationStatus() -> PermissionStatus {
            map(CLLocationManager().authorizationStatus)
        }

        func requestLocation() async -> PermissionStatus {
            await LocationAuthorizationBridge().requestWhenInUse()
        }

        func map(_ status: CLAuthorizationStatus) -> PermissionStatus {
            switch status {
            case .authorizedAlways, .authorizedWhenInUse: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .notDetermined
            }
        }
    }

    /// Bridges CoreLocation's delegate callback into an async result.
    @MainActor
    private final class LocationAuthorizationBridge: NSObject, @MainActor CLLocationManagerDelegate {
        private let manager = CLLocationManager()
        private var continuation: CheckedContinuation<PermissionStatus, Never>?

        func requestWhenInUse() async -> PermissionStatus {
            manager.delegate = self
            let current = manager.authorizationStatus
            if current != .notDetermined {
                return Self.map(current)
            }
            return await withCheckedContinuation { continuation in
                self.continuation = continuation
                manager.requestWhenInUseAuthorization()
            }
        }

        func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
            let status = manager.authorizationStatus
            guard status != .notDetermined, let continuation else { return }
            self.continuation = nil
            continuation.resume(returning: Self.map(status))
        }

        static func map(_ status: CLAuthorizationStatus) -> PermissionStatus {
            switch status {
            case .authorizedAlways, .authorizedWhenInUse: return .granted
            case .denied: return .denied
            case .restricted: return .restricted
            case .notDetermined: return .notDetermined
            @unknown default: return .notDetermined
            }
        }
    }

#endif
