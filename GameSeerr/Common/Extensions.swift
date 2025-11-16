
//  Extensions.swift
//  GameSeerr
//
//  Shared helpers for validation and simple alerts
//

import UIKit
import Foundation

// MARK: - String Helpers
extension String {
    /// quick check for empty or only spaces/newlines
    var isBlank: Bool {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    /// basic email regex
    var isValidEmail: Bool {
        let emailRegEx = "^[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$"
        return NSPredicate(format: "SELF MATCHES %@", emailRegEx).evaluate(with: self)
    }
}

// MARK: - Optional String Helpers
extension Optional where Wrapped == String {
    /// nil = blank, or wrapped string is blank
    var isBlank: Bool {
        switch self {
        case .none: return true
        case .some(let v): return v.isBlank
        }
    }

    /// only true when non-nil AND valid email
    var isValidEmail: Bool {
        switch self {
        case .none: return false
        case .some(let v): return v.isValidEmail
        }
    }
}

// MARK: - UIViewController Helpers
extension UIViewController {
    /// small alert with one OK button (used across screens)
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
