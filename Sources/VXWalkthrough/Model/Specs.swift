//
//  Specs.swift
//  VXWalkthrough
//
//  Per-kind configuration payloads carried by a `WalkthroughStep`.
//  All specs are pure, `Sendable` value types (no closures).
//

import Foundation

// MARK: - Input

/// A single text field within an `InputPage`.
public struct InputField: Sendable, Equatable, Identifiable {
    public enum ContentKind: Sendable, Equatable {
        case plain
        case email
        case password
        case number
        case url
    }

    public var id: String
    public var prompt: String
    public var placeholder: String
    public var value: String
    public var content: ContentKind
    public var isRequired: Bool

    public init(
        id: String,
        prompt: String = "",
        placeholder: String = "",
        value: String = "",
        content: ContentKind = .plain,
        isRequired: Bool = true
    ) {
        self.id = id
        self.prompt = prompt
        self.placeholder = placeholder
        self.value = value
        self.content = content
        self.isRequired = isRequired
    }
}

/// Configuration for a generic field-collection page.
public struct InputSpec: Sendable, Equatable {
    public var fields: [InputField]
    public var buttonTitle: String

    public init(fields: [InputField], buttonTitle: String = "Continue") {
        self.fields = fields
        self.buttonTitle = buttonTitle
    }
}

// MARK: - Login / Signup

public struct LoginSpec: Sendable, Equatable {
    public var loginPrompt: String
    public var passwordPrompt: String
    public var loginValue: String
    public var passwordValue: String
    public var placeholder: String
    public var buttonTitle: String
    public var scanEnabled: Bool

    public init(
        loginPrompt: String = "Email",
        passwordPrompt: String = "Password",
        loginValue: String = "",
        passwordValue: String = "",
        placeholder: String = "",
        buttonTitle: String = "Sign In",
        scanEnabled: Bool = false
    ) {
        self.loginPrompt = loginPrompt
        self.passwordPrompt = passwordPrompt
        self.loginValue = loginValue
        self.passwordValue = passwordValue
        self.placeholder = placeholder
        self.buttonTitle = buttonTitle
        self.scanEnabled = scanEnabled
    }
}

public struct SignupSpec: Sendable, Equatable {
    public var emailPrompt: String
    public var emailValue: String
    public var placeholder: String
    public var buttonTitle: String

    public init(
        emailPrompt: String = "Email",
        emailValue: String = "",
        placeholder: String = "",
        buttonTitle: String = "Sign Up"
    ) {
        self.emailPrompt = emailPrompt
        self.emailValue = emailValue
        self.placeholder = placeholder
        self.buttonTitle = buttonTitle
    }
}

// MARK: - Action

public struct ActionSpec: Sendable, Equatable {
    public var buttonTitle: String

    public init(buttonTitle: String = "Continue") {
        self.buttonTitle = buttonTitle
    }
}

// MARK: - Picker

public struct PickerOption: Sendable, Equatable, Identifiable {
    public var id: String
    public var title: String
    public var image: WalkthroughImage
    public var isAvailable: Bool

    public init(
        id: String,
        title: String,
        image: WalkthroughImage = .none,
        isAvailable: Bool = true
    ) {
        self.id = id
        self.title = title
        self.image = image
        self.isAvailable = isAvailable
    }
}

public struct PickerSpec: Sendable, Equatable {
    public var options: [PickerOption]
    public var selectedID: String?
    public var buttonTitle: String

    public init(
        options: [PickerOption],
        selectedID: String? = nil,
        buttonTitle: String = "Select"
    ) {
        self.options = options
        self.selectedID = selectedID
        self.buttonTitle = buttonTitle
    }
}

// MARK: - Permission

/// The system permissions a `PermissionPage` can request.
public enum PermissionKind: String, Sendable, Equatable, CaseIterable {
    case notifications
    case camera
    case microphone
    case photoLibrary
    case locationWhenInUse
    case contacts
    case tracking
}

public struct PermissionSpec: Sendable, Equatable {
    public var kind: PermissionKind
    public var rationale: String
    public var buttonTitle: String
    public var grantedMessage: String?
    public var deniedMessage: String?

    public init(
        kind: PermissionKind,
        rationale: String = "",
        buttonTitle: String = "Allow",
        grantedMessage: String? = nil,
        deniedMessage: String? = nil
    ) {
        self.kind = kind
        self.rationale = rationale
        self.buttonTitle = buttonTitle
        self.grantedMessage = grantedMessage
        self.deniedMessage = deniedMessage
    }
}

// MARK: - Actions & payloads

/// Credentials captured by login pages.
public struct Credentials: Sendable, Equatable {
    public var login: String
    public var password: String
    public init(login: String, password: String) {
        self.login = login
        self.password = password
    }
}

/// A user-initiated action emitted by an interactive page, dispatched to the
/// host's action handler. Carries the originating step id and a typed payload.
public struct WalkthroughAction: Sendable, Equatable {
    public enum Payload: Sendable, Equatable {
        case action
        case input([String: String])
        case login(Credentials)
        case signup(email: String)
        case picker(selectedID: String)
        case permission(PermissionKind)
    }

    public var stepID: String
    public var payload: Payload

    public init(stepID: String, payload: Payload) {
        self.stepID = stepID
        self.payload = payload
    }
}
