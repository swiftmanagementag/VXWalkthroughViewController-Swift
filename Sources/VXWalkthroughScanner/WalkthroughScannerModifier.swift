//
//  WalkthroughScannerModifier.swift
//  VXWalkthroughScanner
//

import SwiftUI
import VXWalkthrough

public extension View {
    /// Enables QR/barcode scanning for login pages that set `scanEnabled`.
    /// Presents a scanner sheet and feeds the parsed value into the page.
    func walkthroughQRScanner(prompt: String = "Scan a code") -> some View {
        modifier(WalkthroughScannerModifier(prompt: prompt))
    }
}

struct WalkthroughScannerModifier: ViewModifier {
    let prompt: String
    @State private var coordinator = WalkthroughScannerCoordinator()

    func body(content: Content) -> some View {
        content
            .walkthroughScanHandler { await coordinator.scan() }
            .sheet(isPresented: $coordinator.isPresented) {
                ScannerSheet(prompt: prompt) { result in
                    coordinator.finish(with: result)
                }
            }
    }
}

private struct ScannerSheet: View {
    let prompt: String
    let onFinish: (String?) -> Void

    var body: some View {
        #if os(iOS)
            ZStack(alignment: .top) {
                QRScannerView(
                    onResult: { onFinish($0) },
                    onError: { onFinish(nil) }
                )
                .ignoresSafeArea()

                HStack {
                    Text(prompt)
                        .font(.headline)
                        .foregroundStyle(.white)
                    Spacer()
                    Button("Cancel") { onFinish(nil) }
                        .tint(.white)
                        .accessibilityIdentifier("walkthrough.scanner.cancel")
                }
                .padding()
                .background(.black.opacity(0.4))
            }
        #else
            VStack(spacing: 16) {
                Image(systemName: "qrcode.viewfinder").font(.largeTitle)
                Text("Scanning is not available on this platform.")
                    .multilineTextAlignment(.center)
                Button("Close") { onFinish(nil) }
            }
            .padding(40)
        #endif
    }
}
