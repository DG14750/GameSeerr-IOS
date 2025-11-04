//
//  Extensions.swift
//  GameSeerr
//
//  Created by Dean Goodwin on 1/11/2025.
//
//  Shared helpers for validation and UI alerts
//

import UIKit
import Foundation

// MARK: - String Helpers
extension String {
    /// True if the string is empty or only whitespace/newlines
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    /// True if the string matches a valid email format
    var isValidEmail: Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: self)
    }
}

// MARK: - Optional String Helpers
extension Optional where Wrapped == String {
    /// True if the optional is nil OR the wrapped string is blank
    var isBlank: Bool {
        switch self {
        case .none:
            return true
        case .some(let value):
            return value.isBlank
        }
    }
    
    /// True if non-nil and valid email
    var isValidEmail: Bool {
        switch self {
        case .none:
            return false
        case .some(let value):
            return value.isValidEmail
        }
    }
}

// MARK: - UIViewController Helpers
extension UIViewController {
    /// Displays a simple alert with an OK button
    func showAlertMessage(
        title: String,
        message: String,
        preferredStyle: UIAlertController.Style = .alert,
        okTitle: String = "OK",
        handler: ((UIAlertAction) -> Void)? = nil
    ) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: preferredStyle)
        let okAction = UIAlertAction(title: okTitle, style: .default, handler: handler)
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
}
