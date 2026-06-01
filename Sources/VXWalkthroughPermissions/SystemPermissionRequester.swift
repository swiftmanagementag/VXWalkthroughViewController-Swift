//
//  SystemPermissionRequester.swift
//  VXWalkthroughPermissions
//
//  `PermissionRequesting` implementation backed by the system frameworks.
//  Each backend is compiled only when its SwiftPM trait is enabled, so a
//  consumer links exactly the privacy-sensitive frameworks it opts into:
//
//    PermissionsNotifications, PermissionsCamera, PermissionsMicrophone,
//    PermissionsPhotos, PermissionsLocation, PermissionsContacts,
//    PermissionsTracking
//
//  Kinds whose trait is disabled (and every kind on non-iOS platforms) resolve
//  to `.unavailable` — which `PermissionResolver` maps to `.advance`.
//

import Foundation
import VXWalkthrough

#if PermissionsNotifications && canImport(UserNotifications)
    import UserNotifications
#endif
#if (PermissionsCamera || PermissionsMicrophone) && canImport(AVFoundation)
    import AVFoundation
#endif
#if PermissionsPhotos && canImport(Photos)
    import Photos
#endif
#if PermissionsContacts && canImport(Contacts)
    import Contacts
#endif
#if PermissionsLocation && canImport(CoreLocation)
    import CoreLocation
#endif
#if PermissionsTracking && canImport(AppTrackingTransparency)
    import AppTrackingTransparency
#endif

/// System-backed permission requester. Only the permission kinds whose traits
/// are enabled reference their underlying framework.
public struct SystemPermissionRequester: PermissionRequesting {
    public init() {}

    public func status(for kind: PermissionKind) async -> PermissionStatus {
        #if os(iOS)
            switch kind {
            case .notifications:
                #if PermissionsNotifications
                    return await notificationStatus()
                #else
                    return .unavailable
                #endif
            case .camera:
                #if PermissionsCamera
                    return captureStatus(for: .video)
                #else
                    return .unavailable
                #endif
            case .microphone:
                #if PermissionsMicrophone
                    return captureStatus(for: .audio)
                #else
                    return .unavailable
                #endif
            case .photoLibrary:
                #if PermissionsPhotos
                    return photoStatus()
                #else
                    return .unavailable
                #endif
            case .locationWhenInUse:
                #if PermissionsLocation
                    return locationStatus()
                #else
                    return .unavailable
                #endif
            case .contacts:
                #if PermissionsContacts
                    return contactsStatus()
                #else
                    return .unavailable
                #endif
            case .tracking:
                #if PermissionsTracking
                    return trackingStatus()
                #else
                    return .unavailable
                #endif
            }
        #else
            return .unavailable
        #endif
    }

    @discardableResult
    public func request(_ kind: PermissionKind) async -> PermissionStatus {
        #if os(iOS)
            switch kind {
            case .notifications:
                #if PermissionsNotifications
                    return await requestNotifications()
                #else
                    return .unavailable
                #endif
            case .camera:
                #if PermissionsCamera
                    return await requestCapture(.video)
                #else
                    return .unavailable
                #endif
            case .microphone:
                #if PermissionsMicrophone
                    return await requestCapture(.audio)
                #else
                    return .unavailable
                #endif
            case .photoLibrary:
                #if PermissionsPhotos
                    return await requestPhotos()
                #else
                    return .unavailable
                #endif
            case .locationWhenInUse:
                #if PermissionsLocation
                    return await requestLocation()
                #else
                    return .unavailable
                #endif
            case .contacts:
                #if PermissionsContacts
                    return await requestContacts()
                #else
                    return .unavailable
                #endif
            case .tracking:
                #if PermissionsTracking
                    return await requestTracking()
                #else
                    return .unavailable
                #endif
            }
        #else
            return .unavailable
        #endif
    }
}

// MARK: Notifications

#if os(iOS) && PermissionsNotifications

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

#endif

// MARK: Camera / Microphone

#if os(iOS) && (PermissionsCamera || PermissionsMicrophone)

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

#endif

// MARK: Photos

#if os(iOS) && PermissionsPhotos

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

#endif

// MARK: Contacts

#if os(iOS) && PermissionsContacts

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

#endif

// MARK: Tracking (ATT)

#if os(iOS) && PermissionsTracking

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

#endif

// MARK: Location

#if os(iOS) && PermissionsLocation

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
