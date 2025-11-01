//
//  FirebaseManager.swift
//  GameSeerr
//
//  Created by Dean Goodwin on 1/11/2025.
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseManager {
    static let shared = FirebaseManager()
    let db = Firestore.firestore()
    private init() {}

    func authenticatedPing() {
        let email = "test@example.com"
        let password = "123456"

        Auth.auth().signIn(withEmail: email, password: password) { result, error in
            if let error = error {
                print("Sign-in failed:", error.localizedDescription)
                return
            }
            print("Signed in as:", result?.user.email ?? "unknown")

            let docRef = self.db.collection("pingTests").document()
            docRef.setData([
                "timestamp": Date().timeIntervalSince1970,
                "uid": result?.user.uid ?? "",
                "message": "Authenticated Firestore ping OK"
            ]) { error in
                if let error = error {
                    print("Firestore write failed:", error.localizedDescription)
                } else {
                    print("Firestore write succeeded:", docRef.documentID)
                }
            }
        }
    }
}

