//
//  DataScannerView.swift
//  VXWalkthroughScanner
//
//  VisionKit-based scanner used as a progressive enhancement on capable
//  devices. iOS only (not Mac Catalyst); callers fall back to `QRScannerView`
//  when this is unavailable.
//

import SwiftUI

#if os(iOS) && !targetEnvironment(macCatalyst)

    import VisionKit

    @available(iOS 16.0, *)
    struct DataScannerView: UIViewControllerRepresentable {
        let onResult: (String) -> Void
        let onError: () -> Void

        /// Whether VisionKit live scanning can run on this device right now
        /// (hardware support + camera availability/authorization).
        static var isSupportedAndAvailable: Bool {
            DataScannerViewController.isSupported && DataScannerViewController.isAvailable
        }

        func makeCoordinator() -> Coordinator {
            Coordinator(onResult: onResult)
        }

        func makeUIViewController(context: Context) -> DataScannerViewController {
            let scanner = DataScannerViewController(
                recognizedDataTypes: [.barcode()],
                qualityLevel: .balanced,
                recognizesMultipleItems: false,
                isHighFrameRateTrackingEnabled: false,
                isPinchToZoomEnabled: true,
                isGuidanceEnabled: true,
                isHighlightingEnabled: true
            )
            scanner.delegate = context.coordinator
            return scanner
        }

        func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
            guard !context.coordinator.isScanning else { return }
            do {
                try scanner.startScanning()
                context.coordinator.isScanning = true
            } catch {
                onError()
            }
        }

        static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
            scanner.stopScanning()
            coordinator.isScanning = false
        }

        @MainActor
        final class Coordinator: NSObject, @MainActor DataScannerViewControllerDelegate {
            let onResult: (String) -> Void
            var isScanning = false
            private var didEmit = false

            init(onResult: @escaping (String) -> Void) {
                self.onResult = onResult
            }

            func dataScanner(
                _: DataScannerViewController,
                didAdd addedItems: [RecognizedItem],
                allItems _: [RecognizedItem]
            ) {
                emit(from: addedItems)
            }

            func dataScanner(_: DataScannerViewController, didTapOn item: RecognizedItem) {
                emit(from: [item])
            }

            private func emit(from items: [RecognizedItem]) {
                guard !didEmit else { return }
                for case let .barcode(barcode) in items {
                    if let value = barcode.payloadStringValue {
                        didEmit = true
                        onResult(value)
                        return
                    }
                }
            }
        }
    }

#endif
