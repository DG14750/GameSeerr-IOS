//
//  FirebaseManager.swift
//  GameSeerr
//
//  Small wrapper around Firebase so controllers stay cleaner
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseManager {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()
    private init() {}

    // MARK: - Sign Up
    /// creates auth user, sets displayName, writes a minimal profile doc
    func createUser(username: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error { return completion(.failure(error)) }
            guard let user = result?.user else {
                return completion(.failure(NSError(domain: "GameSeerr", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user returned"])))
            }

            // set display name (not critical if this fails)
            let change = user.createProfileChangeRequest()
            change.displayName = username
            change.commitChanges { commitError in
                if let commitError = commitError {
                    print("Display name update error:", commitError.localizedDescription)
                }

                // email verification is optional for now
                user.sendEmailVerification(completion: nil)

                // write user profile (best-effort)
                let data: [String: Any] = [
                    "uid": user.uid,
                    "username": username,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                self.db.collection("users").document(user.uid).setData(data) { writeErr in
                    if let writeErr = writeErr {
                        print("Firestore user profile write error:", writeErr.localizedDescription)
                    }
                    completion(.success(user))
                }
            }
        }
    }

    // MARK: - Sign In
    /// plain email/password login
    func signIn(email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error { return completion(.failure(error)) }
            guard let user = result?.user else {
                return completion(.failure(NSError(domain: "GameSeerr", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user returned"])))
            }
            completion(.success(user))
        }
    }

    // MARK: - Password Reset
    /// sends reset link to the email
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }

    // MARK: - Error message
    /// map common Firebase auth errors into short user messages
    func friendlyMessage(for error: Error) -> String {
        let ns = error as NSError
        guard let code = AuthErrorCode(rawValue: ns.code) else {
            return error.localizedDescription
        }
        switch code {
        case .emailAlreadyInUse: return "That email is already in use. Try logging in instead."
        case .invalidEmail:      return "That doesn’t look like a valid email."
        case .weakPassword:      return "Your password is too weak. Try at least 6 characters."
        case .networkError:      return "Network error. Please check your connection and try again."
        default:                 return error.localizedDescription
        }
    }
}
