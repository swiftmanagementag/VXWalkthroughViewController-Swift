//
//  Pages.swift
//  VXWalkthrough
//
//  Public DSL page types. Each is a lightweight value that produces a
//  `WalkthroughStep`; SwiftUI rendering (Phase 2+) switches on `step.kind`.
//

import Foundation

/// A display-only page with an image and styled title/body.
public struct InfoPage: WalkthroughStepConvertible, Sendable {
    public var id: String
    public var title: AttributedTitle
    public var body: AttributedTitle?
    public var image: WalkthroughImage
    public var sort: Int

    public init(
        _ id: String,
        title: AttributedTitle = "",
        body: AttributedTitle? = nil,
        image: WalkthroughImage = .none,
        sort: Int = 0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.image = image
        self.sort = sort
    }

    public func makeSteps() -> [WalkthroughStep] {
        [WalkthroughStep(id: id, kind: .info, title: title, body: body, image: image, sort: sort)]
    }
}

/// A generic field-collection page.
public struct InputPage: WalkthroughStepConvertible, Sendable {
    public var id: String
    public var title: AttributedTitle
    public var image: WalkthroughImage
    public var spec: InputSpec
    public var sort: Int

    public init(
        _ id: String,
        title: AttributedTitle = "",
        image: WalkthroughImage = .none,
        fields: [InputField],
        buttonTitle: String = "Continue",
        sort: Int = 0
    ) {
        self.id = id
        self.title = title
        self.image = image
        spec = InputSpec(fields: fields, buttonTitle: buttonTitle)
        self.sort = sort
    }

    public func makeSteps() -> [WalkthroughStep] {
        [WalkthroughStep(id: id, kind: .input(spec), title: title, image: image, sort: sort)]
    }
}

/// An email + password login page.
public struct LoginPage: WalkthroughStepConvertible, Sendable {
    public var id: String
    public var title: AttributedTitle
    public var image: WalkthroughImage
    public var spec: LoginSpec
    public var sort: Int

    public init(
        _ id: String = "login",
        title: AttributedTitle = "",
        image: WalkthroughImage = .none,
        loginPrompt: String = "Email",
        passwordPrompt: String = "Password",
        placeholder: String = "",
        buttonTitle: String = "Sign In",
        scanEnabled: Bool = false,
        sort: Int = 0
    ) {
        self.id = id
        self.title = title
        self.image = image
        spec = LoginSpec(
            loginPrompt: loginPrompt,
            passwordPrompt: passwordPrompt,
            placeholder: placeholder,
            buttonTitle: buttonTitle,
            scanEnabled: scanEnabled
        )
        self.sort = sort
    }

    public func makeSteps() -> [WalkthroughStep] {
        [WalkthroughStep(id: id, kind: .login(spec), title: title, image: image, sort: sort)]
    }
}

/// An email signup page.
public struct SignupPage: WalkthroughStepConvertible, Sendable {
    public var id: String
    public var title: AttributedTitle
    public var image: WalkthroughImage
    public var spec: SignupSpec
    public var sort: Int

    public init(
        _ id: String = "signup",
        title: AttributedTitle = "",
        image: WalkthroughImage = .none,
        emailPrompt: String = "Email",
        placeholder: String = "",
        buttonTitle: String = "Sign Up",
        sort: Int = 0
    ) {
        self.id = id
        self.title = title
        self.image = image
        spec = SignupSpec(emailPrompt: emailPrompt, placeholder: placeholder, buttonTitle: buttonTitle)
        self.sort = sort
    }

    public func makeSteps() -> [WalkthroughStep] {
        [WalkthroughStep(id: id, kind: .signup(spec), title: title, image: image, sort: sort)]
    }
}

/// A single call-to-action page.
public struct ActionPage: WalkthroughStepConvertible, Sendable {
    public var id: String
    public var title: AttributedTitle
    public var body: AttributedTitle?
    public var image: WalkthroughImage
    public var spec: ActionSpec
    public var sort: Int

    public init(
        _ id: String,
        title: AttributedTitle = "",
        body: AttributedTitle? = nil,
        image: WalkthroughImage = .none,
        buttonTitle: String = "Continue",
        sort: Int = 0
    ) {
        self.id = id
        self.title = title
        self.body = body
        self.image = image
        spec = ActionSpec(buttonTitle: buttonTitle)
        self.sort = sort
    }

    public func makeSteps() -> [WalkthroughStep] {
        [WalkthroughStep(id: id, kind: .action(spec), title: title, body: body, image: image, sort: sort)]
    }
}

/// An option-selection (carousel) page.
public struct PickerPage: WalkthroughStepConvertible, Sendable {
    public var id: String
    public var title: AttributedTitle
    public var image: WalkthroughImage
    public var spec: PickerSpec
    public var sort: Int

    public init(
        _ id: String,
        title: AttributedTitle = "",
        image: WalkthroughImage = .none,
        options: [PickerOption],
        selectedID: String? = nil,
        buttonTitle: String = "Select",
        sort: Int = 0
    ) {
        self.id = id
        self.title = title
        self.image = image
        spec = PickerSpec(options: options, selectedID: selectedID, buttonTitle: buttonTitle)
        self.sort = sort
    }

    public func makeSteps() -> [WalkthroughStep] {
        [WalkthroughStep(id: id, kind: .picker(spec), title: title, image: image, sort: sort)]
    }
}

/// A system-permission request page.
public struct PermissionPage: WalkthroughStepConvertible, Sendable {
    public var id: String
    public var title: AttributedTitle
    public var image: WalkthroughImage
    public var spec: PermissionSpec
    public var sort: Int

    public init(
        _ kind: PermissionKind,
        id: String? = nil,
        title: AttributedTitle = "",
        image: WalkthroughImage = .none,
        rationale: String = "",
        buttonTitle: String = "Allow",
        grantedMessage: String? = nil,
        deniedMessage: String? = nil,
        sort: Int = 0
    ) {
        self.id = id ?? "permission.\(kind.rawValue)"
        self.title = title
        self.image = image
        spec = PermissionSpec(
            kind: kind,
            rationale: rationale,
            buttonTitle: buttonTitle,
            grantedMessage: grantedMessage,
            deniedMessage: deniedMessage
        )
        self.sort = sort
    }

    public func makeSteps() -> [WalkthroughStep] {
        [WalkthroughStep(id: id, kind: .permission(spec), title: title, image: image, sort: sort)]
    }
}
