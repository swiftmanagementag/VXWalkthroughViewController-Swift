//
//  QRScannerView.swift
//  VXWalkthroughScanner
//
//  AVFoundation-based QR/barcode scanner. iOS / Mac Catalyst only.
//

import SwiftUI

#if os(iOS)

    import AVFoundation
    import UIKit

    /// Acknowledged-safe wrapper for moving a thread-safe object across actors.
    private struct UncheckedSendableBox<T>: @unchecked Sendable {
        let value: T
        init(_ value: T) { self.value = value }
    }

    /// A SwiftUI wrapper around an `AVCaptureMetadataOutput` QR scanner.
    struct QRScannerView: UIViewControllerRepresentable {
        let onResult: (String) -> Void
        let onError: () -> Void

        func makeUIViewController(context: Context) -> ScannerViewController {
            let controller = ScannerViewController()
            controller.onResult = onResult
            controller.onError = onError
            return controller
        }

        func updateUIViewController(_: ScannerViewController, context _: Context) {}
    }

    final class ScannerViewController: UIViewController, @MainActor AVCaptureMetadataOutputObjectsDelegate {
        var onResult: ((String) -> Void)?
        var onError: (() -> Void)?

        private let session = AVCaptureSession()
        private var preview: AVCaptureVideoPreviewLayer?
        private var didEmit = false

        override func viewDidLoad() {
            super.viewDidLoad()
            view.backgroundColor = .black
            configureSession()
        }

        override func viewDidLayoutSubviews() {
            super.viewDidLayoutSubviews()
            preview?.frame = view.bounds
        }

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            startRunningIfNeeded()
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            guard session.isRunning else { return }
            // AVCaptureSession start/stop are documented as thread-safe.
            let box = UncheckedSendableBox(session)
            DispatchQueue.global(qos: .userInitiated).async { box.value.stopRunning() }
        }

        private func configureSession() {
            guard let device = AVCaptureDevice.default(for: .video),
                  let input = try? AVCaptureDeviceInput(device: device),
                  session.canAddInput(input)
            else {
                onError?()
                return
            }
            session.addInput(input)

            let output = AVCaptureMetadataOutput()
            guard session.canAddOutput(output) else {
                onError?()
                return
            }
            session.addOutput(output)
            output.setMetadataObjectsDelegate(self, queue: .main)
            output.metadataObjectTypes = [.qr, .ean13, .code128, .pdf417, .aztec]

            let preview = AVCaptureVideoPreviewLayer(session: session)
            preview.videoGravity = .resizeAspectFill
            preview.frame = view.bounds
            view.layer.addSublayer(preview)
            self.preview = preview
        }

        private func startRunningIfNeeded() {
            guard !session.isRunning else { return }
            let box = UncheckedSendableBox(session)
            DispatchQueue.global(qos: .userInitiated).async { box.value.startRunning() }
        }

        func metadataOutput(
            _: AVCaptureMetadataOutput,
            didOutput metadataObjects: [AVMetadataObject],
            from _: AVCaptureConnection
        ) {
            guard !didEmit,
                  let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
                  let value = object.stringValue
            else { return }
            didEmit = true
            onResult?(value)
        }
    }

#endif
