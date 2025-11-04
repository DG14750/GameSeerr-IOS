//
//  FirebaseManager.swift
//  GameSeerr
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

final class FirebaseManager {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()
    private init() {}

    // MARK: - Sign Up
    func createUser(username: String, email: String, password: String, completion: @escaping (Result<User, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { result, error in
            if let error = error { return completion(.failure(error)) }
            guard let user = result?.user else {
                return completion(.failure(NSError(domain: "GameSeerr", code: -1, userInfo: [NSLocalizedDescriptionKey: "No user returned"])))
            }

            // Set displayName
            let change = user.createProfileChangeRequest()
            change.displayName = username
            change.commitChanges { commitError in
                if let commitError = commitError {
                    // Not fatal; we continue but bubble the error for logging if needed
                    print("Display name update error:", commitError.localizedDescription)
                }

                // Verification
                user.sendEmailVerification(completion: nil)

                // Create Firestore user profile
                let data: [String: Any] = [
                    "uid": user.uid,
                    "username": username,
                    "email": email,
                    "createdAt": FieldValue.serverTimestamp()
                ]
                self.db.collection("users").document(user.uid).setData(data) { writeErr in
                    if let writeErr = writeErr {
                        // Still consider signup successful; just log the profile write error
                        print("Firestore user profile write error:", writeErr.localizedDescription)
                    }
                    completion(.success(user))
                }
            }
        }
    }

    // MARK: - Sign In
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
    func sendPasswordReset(email: String, completion: @escaping (Error?) -> Void) {
        Auth.auth().sendPasswordReset(withEmail: email, completion: completion)
    }

    // MARK: - Error message
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

    // USED TO TEST CONNECTION
//    func authenticatedPing() {
//        let email = "test@example.com"
//        let password = "123456"
//        Auth.auth().signIn(withEmail: email, password: password) { result, error in
//            if let error = error {
//                print("Sign-in failed:", error.localizedDescription)
//                return
//            }
//            print("Signed in as:", result?.user.email ?? "unknown")
//
//            let docRef = self.db.collection("pingTests").document()
//            docRef.setData([
//                "timestamp": Date().timeIntervalSince1970,
//                "uid": result?.user.uid ?? "",
//                "message": "Authenticated Firestore ping OK"
//            ]) { error in
//                if let error = error {
//                    print("Firestore write failed:", error.localizedDescription)
//                } else {
//                    print("Firestore write succeeded:", docRef.documentID)
//                }
//            }
//        }
//    }
}
