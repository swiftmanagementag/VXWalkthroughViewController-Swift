import Testing
import Foundation
@testable import VXWalkthrough

@Suite("Walkthrough DSL")
struct BuilderTests {
    @Test("DSL assembles steps in declared order and maps kinds")
    func assembles() {
        let walkthrough = Walkthrough {
            InfoPage("welcome", title: "Welcome", image: .named("walkthrough_0"))
            LoginPage(title: "Sign in", scanEnabled: true)
            PermissionPage(.notifications, rationale: "Stay in the loop")
        }

        #expect(walkthrough.count == 3)
        #expect(walkthrough.steps.map(\.id) == ["welcome", "login", "permission.notifications"])
        #expect(walkthrough.steps[0].kind.name == "info")
        #expect(walkthrough.steps[1].kind.name == "login")
        #expect(walkthrough.steps[2].kind.name == "permission")
    }

    @Test("DSL honors sort over declaration order")
    func sortWins() {
        let walkthrough = Walkthrough {
            InfoPage("third", sort: 30)
            InfoPage("first", sort: 10)
            InfoPage("second", sort: 20)
        }
        #expect(walkthrough.steps.map(\.id) == ["first", "second", "third"])
    }

    @Test("Conditionals and loops are supported in the builder")
    func conditionals() {
        let includeLogin = true
        let walkthrough = Walkthrough {
            for i in 0 ..< 3 {
                InfoPage("page_\(i)", sort: i)
            }
            if includeLogin {
                LoginPage(sort: 99)
            }
        }
        #expect(walkthrough.steps.map(\.id) == ["page_0", "page_1", "page_2", "login"])
    }

    @Test("LoginPage carries its spec")
    func loginSpec() {
        let walkthrough = Walkthrough {
            LoginPage(loginPrompt: "Mail", passwordPrompt: "Pass", scanEnabled: true)
        }
        guard case let .login(spec) = walkthrough.steps[0].kind else {
            Issue.record("expected login kind")
            return
        }
        #expect(spec.loginPrompt == "Mail")
        #expect(spec.passwordPrompt == "Pass")
        #expect(spec.scanEnabled)
    }

    @Test("PickerPage carries options and selection")
    func pickerSpec() {
        let walkthrough = Walkthrough {
            PickerPage(
                "plan",
                options: [
                    PickerOption(id: "free", title: "Free"),
                    PickerOption(id: "pro", title: "Pro", isAvailable: true),
                ],
                selectedID: "free"
            )
        }
        guard case let .picker(spec) = walkthrough.steps[0].kind else {
            Issue.record("expected picker kind")
            return
        }
        #expect(spec.options.count == 2)
        #expect(spec.selectedID == "free")
    }

    @Test("Explicit-steps initializer also sorts")
    func explicitInit() {
        let walkthrough = Walkthrough(steps: [
            WalkthroughStep(id: "b", sort: 2),
            WalkthroughStep(id: "a", sort: 1),
        ])
        #expect(walkthrough.steps.map(\.id) == ["a", "b"])
    }
}
