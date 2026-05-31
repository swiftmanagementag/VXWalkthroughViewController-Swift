import Testing
import Foundation
@testable import VXWalkthrough

@Suite("Validation")
struct ValidationTests {
    @Test("Strict email validation", arguments: [
        ("info@domain.com", true),
        ("a.b+c@sub.domain.co", true),
        ("plainaddress", false),
        ("@missing.com", false),
        ("name@nodot", false),
        ("name@domain.c", false),
        ("", false),
    ])
    func strictEmail(input: String, expected: Bool) {
        #expect(Validation.isValidEmail(input, strict: true) == expected)
    }

    @Test("Lax email accepts looser forms")
    func laxEmail() {
        #expect(Validation.isValidEmail("a@b.cd", strict: false))
        #expect(!Validation.isValidEmail("nope", strict: false))
    }

    @Test("Required empty field is invalid; optional empty is valid")
    func requiredness() {
        let required = InputField(id: "x", content: .plain, isRequired: true)
        let optional = InputField(id: "y", content: .plain, isRequired: false)
        #expect(!required.isValid(value: "  "))
        #expect(optional.isValid(value: ""))
        #expect(required.isValid(value: "hi"))
    }

    @Test("Typed field validation")
    func typed() {
        let email = InputField(id: "e", content: .email)
        #expect(email.isValid(value: "a@b.com"))
        #expect(!email.isValid(value: "nope"))

        let number = InputField(id: "n", content: .number)
        #expect(number.isValid(value: "42.5"))
        #expect(!number.isValid(value: "x"))

        let url = InputField(id: "u", content: .url)
        #expect(url.isValid(value: "https://example.com"))
        #expect(!url.isValid(value: "example"))
    }

    @Test("InputSpec completeness and initial values")
    func specCompleteness() {
        let spec = InputSpec(fields: [
            InputField(id: "email", value: "seed@x.com", content: .email),
            InputField(id: "name", content: .plain),
        ])
        #expect(spec.initialValues["email"] == "seed@x.com")
        #expect(!spec.isComplete(values: ["email": "a@b.com"])) // name missing
        #expect(spec.isComplete(values: ["email": "a@b.com", "name": "Sam"]))
        #expect(!spec.isComplete(values: ["email": "bad", "name": "Sam"]))
    }
}

@Suite("PickerSpec logic")
struct PickerSpecTests {
    private let spec = PickerSpec(
        options: [
            PickerOption(id: "free", title: "Free"),
            PickerOption(id: "pro", title: "Pro", isAvailable: false),
            PickerOption(id: "max", title: "Max"),
        ],
        selectedID: "pro"
    )

    @Test("initialIndex resolves selectedID")
    func initialIndex() {
        #expect(spec.initialIndex == 1)
        let noSelection = PickerSpec(options: spec.options)
        #expect(noSelection.initialIndex == 0)
    }

    @Test("option(at:) bounds")
    func optionAt() {
        #expect(spec.option(at: 0)?.id == "free")
        #expect(spec.option(at: 2)?.id == "max")
        #expect(spec.option(at: 3) == nil)
        #expect(spec.option(at: -1) == nil)
    }

    @Test("availability is carried per option")
    func availability() {
        #expect(spec.option(at: 1)?.isAvailable == false)
        #expect(spec.option(at: 0)?.isAvailable == true)
    }
}
