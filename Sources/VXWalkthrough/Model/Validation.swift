//
//  Validation.swift
//  VXWalkthrough
//
//  Pure, testable input validation.
//

import Foundation

public enum Validation {
    /// Validates an email address. `strict` uses a tighter pattern (matching the
    /// legacy framework's stricter filter).
    public static func isValidEmail(_ email: String?, strict: Bool = true) -> Bool {
        guard let email, !email.isEmpty else { return false }
        if strict {
            return email.wholeMatch(of: #/^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/#) != nil
        } else {
            return email.wholeMatch(of: #/^.+@.+\..{2,}$/#) != nil
        }
    }

    /// Validates a single field's current value against its content kind.
    public static func isValid(_ field: InputField, value: String) -> Bool {
        let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return !field.isRequired
        }
        switch field.content {
        case .plain, .password:
            return true
        case .email:
            return isValidEmail(trimmed)
        case .number:
            return Double(trimmed) != nil
        case .url:
            guard let url = URL(string: trimmed) else { return false }
            return url.scheme != nil
        }
    }
}

public extension InputField {
    func isValid(value: String) -> Bool {
        Validation.isValid(self, value: value)
    }
}

public extension InputSpec {
    /// Whether every field is valid for the supplied values (by field id).
    func isComplete(values: [String: String]) -> Bool {
        fields.allSatisfy { field in
            Validation.isValid(field, value: values[field.id] ?? "")
        }
    }

    /// Values seeded from each field's initial `value`.
    var initialValues: [String: String] {
        Dictionary(uniqueKeysWithValues: fields.map { ($0.id, $0.value) })
    }
}

public extension PickerSpec {
    /// The starting option index, derived from `selectedID` (or 0).
    var initialIndex: Int {
        guard let selectedID,
              let index = options.firstIndex(where: { $0.id == selectedID })
        else { return 0 }
        return index
    }

    /// The option at an index, if in range.
    func option(at index: Int) -> PickerOption? {
        options.indices.contains(index) ? options[index] : nil
    }
}
