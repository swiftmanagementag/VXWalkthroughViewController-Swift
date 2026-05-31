import Testing
import Foundation
@testable import VXWalkthrough

/// Configurable mock requester for tests.
final class MockPermissionRequester: PermissionRequesting, @unchecked Sendable {
    private let lock = NSLock()
    private var statuses: [PermissionKind: PermissionStatus]
    private(set) var requested: [PermissionKind] = []

    init(default defaultStatus: PermissionStatus = .granted,
         overrides: [PermissionKind: PermissionStatus] = [:])
    {
        statuses = [:]
        for kind in PermissionKind.allCases { statuses[kind] = defaultStatus }
        for (k, v) in overrides { statuses[k] = v }
    }

    func status(for kind: PermissionKind) async -> PermissionStatus {
        lock.withLock { statuses[kind] ?? .notDetermined }
    }

    func request(_ kind: PermissionKind) async -> PermissionStatus {
        lock.withLock {
            requested.append(kind)
            return statuses[kind] ?? .notDetermined
        }
    }
}

@Suite("PermissionResolver")
struct PermissionResolverTests {
    private let spec = PermissionSpec(
        kind: .notifications,
        grantedMessage: "Thanks!",
        deniedMessage: "No problem"
    )

    @Test("granted -> success(grantedMessage)")
    func granted() {
        #expect(PermissionResolver.outcome(for: .granted, spec: spec) == .success("Thanks!"))
    }

    @Test("denied/restricted -> failure(deniedMessage)")
    func denied() {
        #expect(PermissionResolver.outcome(for: .denied, spec: spec) == .failure("No problem"))
        #expect(PermissionResolver.outcome(for: .restricted, spec: spec) == .failure("No problem"))
    }

    @Test("unavailable -> advance; notDetermined -> none")
    func edges() {
        #expect(PermissionResolver.outcome(for: .unavailable, spec: spec) == .advance)
        #expect(PermissionResolver.outcome(for: .notDetermined, spec: spec) == .none)
    }
}

@MainActor
@Suite("Permission flow (integration)")
struct PermissionFlowTests {
    private func model() -> WalkthroughModel {
        WalkthroughModel(steps: [
            WalkthroughStep(id: "perm", kind: .permission(PermissionSpec(kind: .camera, grantedMessage: "Yay", deniedMessage: "Nope"))),
            WalkthroughStep(id: "next", kind: .info),
        ])
    }

    @Test("Granting drives success and advances")
    func granting() async {
        let model = model()
        let requester = MockPermissionRequester(default: .granted)
        let spec = PermissionSpec(kind: .camera, grantedMessage: "Yay", deniedMessage: "Nope")

        let status = await requester.request(spec.kind)
        model.applyOutcome(PermissionResolver.outcome(for: status, spec: spec), to: "perm")

        #expect(requester.requested == [.camera])
        #expect(model.state(for: "perm") == .success("Yay"))
        #expect(model.currentIndex == 1)
    }

    @Test("Denial drives failure and stays")
    func denial() async {
        let model = model()
        let requester = MockPermissionRequester(default: .denied)
        let spec = PermissionSpec(kind: .camera, grantedMessage: "Yay", deniedMessage: "Nope")

        let status = await requester.request(spec.kind)
        model.applyOutcome(PermissionResolver.outcome(for: status, spec: spec), to: "perm")

        #expect(model.state(for: "perm") == .failure("Nope"))
        #expect(model.currentIndex == 0)
    }
}

@MainActor
@Suite("Auth flow (integration)")
struct AuthFlowTests {
    @Test("Login handler receives credentials and can succeed")
    func login() async {
        let model = WalkthroughModel(steps: [
            WalkthroughStep(id: "login", kind: .login(LoginSpec())),
            WalkthroughStep(id: "done", kind: .info),
        ])
        var captured: Credentials?
        model.actionHandler = { action in
            if case let .login(creds) = action.payload {
                captured = creds
                return .success("Welcome")
            }
            return .none
        }

        await model.perform(WalkthroughAction(
            stepID: "login",
            payload: .login(Credentials(login: "a@b.com", password: "secret"))
        ))

        #expect(captured == Credentials(login: "a@b.com", password: "secret"))
        #expect(model.state(for: "login") == .success("Welcome"))
        #expect(model.currentIndex == 1)
    }

    @Test("Signup handler receives email")
    func signup() async {
        let model = WalkthroughModel(steps: [WalkthroughStep(id: "signup", kind: .signup(SignupSpec()))])
        var email: String?
        model.actionHandler = { action in
            if case let .signup(value) = action.payload { email = value }
            return .successStay("Check your inbox")
        }
        await model.perform(WalkthroughAction(stepID: "signup", payload: .signup(email: "x@y.com")))
        #expect(email == "x@y.com")
        #expect(model.state(for: "signup") == .success("Check your inbox"))
    }
}
