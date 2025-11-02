//
//  Extensions.swift
//  GameSeerr
//
//  Created by Dean Goodwin on 1/11/2025.
//
// Shared helpers

import Foundation

extension String {
    /// True if the string is empty or only whitespace/newlines
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

extension Optional where Wrapped == String {
    /// True if the optional is nil OR the wrapped string is blank
    var isBlank: Bool {
        guard let notNilBool = self else {
            return true
        }
        return notNilBool.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

