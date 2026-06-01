//
//  ScanResultParser.swift
//  VXWalkthroughScanner
//
//  Pure parsing of a scanned string. Preserves the legacy behavior of pulling a
//  `voucher` (and optional `teacher`) out of URL payloads.
//

import Foundation

public struct ScanResult: Sendable, Equatable {
    /// The value to feed back into the login/password field.
    public var value: String
    /// A voucher code, if the payload was a URL containing `voucher`.
    public var voucher: String?
    /// A teacher/identifier code, if present in a URL payload.
    public var teacher: String?

    public init(value: String, voucher: String? = nil, teacher: String? = nil) {
        self.value = value
        self.voucher = voucher
        self.teacher = teacher
    }
}

public enum ScanResultParser {
    public static func parse(_ code: String) -> ScanResult {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmed.lowercased().hasPrefix("http"),
              let components = URLComponents(string: trimmed),
              let items = components.queryItems
        else {
            return ScanResult(value: trimmed)
        }

        let voucher = items.first { $0.name == "voucher" }?.value
        let teacher = items.first { $0.name == "teacher" }?.value
        return ScanResult(value: voucher ?? trimmed, voucher: voucher, teacher: teacher)
    }
}
