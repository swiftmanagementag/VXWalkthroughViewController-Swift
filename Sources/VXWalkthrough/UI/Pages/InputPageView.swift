//
//  InputPageView.swift
//  VXWalkthrough
//

import SwiftUI

/// A generic field-collection page driven by an `InputSpec`.
struct InputPageView: View {
    let step: WalkthroughStep
    let spec: InputSpec
    let proxy: WalkthroughPageProxy

    @State private var values: [String: String] = [:]
    @FocusState private var focusedField: String?
    @Environment(\.walkthroughTheme) private var theme

    private var isComplete: Bool { spec.isComplete(values: values) }

    var body: some View {
        PageScaffold(step: step, state: proxy.state) {
            VStack(spacing: 16) {
                ForEach(spec.fields) { field in
                    fieldView(field)
                }

                WalkthroughPrimaryButton(
                    title: spec.buttonTitle,
                    isLoading: proxy.state.isLoading,
                    isEnabled: isComplete
                ) {
                    focusedField = nil
                    Task { await proxy.submit(.input(values)) }
                }
            }
        }
        .onAppear {
            if values.isEmpty { values = spec.initialValues }
        }
    }

    @ViewBuilder
    private func fieldView(_ field: InputField) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if !field.prompt.isEmpty {
                Text(field.prompt)
                    .font(.caption)
                    .foregroundStyle(theme.bodyColor)
            }
            Group {
                if field.content == .password {
                    SecureField(field.placeholder, text: binding(for: field))
                } else {
                    TextField(field.placeholder, text: binding(for: field))
                }
            }
            .textFieldStyle(.roundedBorder)
            .focused($focusedField, equals: field.id)
            .applyContentType(field.content)
            .accessibilityIdentifier("walkthrough.field.\(field.id)")
        }
    }

    private func binding(for field: InputField) -> Binding<String> {
        Binding(
            get: { values[field.id] ?? "" },
            set: { values[field.id] = $0 }
        )
    }
}

private extension View {
    @ViewBuilder
    func applyContentType(_ kind: InputField.ContentKind) -> some View {
        #if os(iOS)
            switch kind {
            case .email:
                keyboardType(.emailAddress)
                    .textContentType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            case .password:
                textContentType(.password)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            case .number:
                keyboardType(.numberPad)
            case .url:
                keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
            case .plain:
                self
            }
        #else
            self
        #endif
    }
}
