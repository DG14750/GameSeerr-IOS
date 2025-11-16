//
//  UsersRepository.swift
//  GameSeerr
//
//  user-specific data (wishlist is a subcollection)
//

import Foundation
import FirebaseAuth
import FirebaseFirestore

// MARK: - Protocol
protocol UsersRepository {
    /// live stream of current user's wishlist ids
    func observeWishlist(_ onChange: @escaping (Set<String>) -> Void) -> ListenerRegistration?
    /// add/remove game from wishlist (id only)
    func toggleWishlist(gameId: String, isCurrentlyIn: Bool, completion: ((Error?) -> Void)?)
}

// MARK: - Firestore implementation
final class FirestoreUsersRepository: UsersRepository {
    private let db = FirebaseManager.shared.db

    // users/{uid}/wishlist/{gameId}
    private func wishlistCollection(for uid: String) -> CollectionReference {
        db.collection("users").document(uid).collection("wishlist")
    }

    /// returns a ListenerRegistration so caller can remove it
    func observeWishlist(_ onChange: @escaping (Set<String>) -> Void) -> ListenerRegistration? {
        guard let uid = Auth.auth().currentUser?.uid else {
            onChange([]) // not signed in = empty wishlist
            return nil
        }
        return wishlistCollection(for: uid).addSnapshotListener { snap, _ in
            let ids = Set(snap?.documents.map { $0.documentID } ?? [])
            onChange(ids)
        }
    }

    /// toggles the doc presence: setData to add, delete to remove
    func toggleWishlist(gameId: String, isCurrentlyIn: Bool, completion: ((Error?) -> Void)? = nil) {
        guard let uid = Auth.auth().currentUser?.uid else {
            completion?(NSError(domain: "UsersRepository",
                                code: 401,
                                userInfo: [NSLocalizedDescriptionKey: "Not signed in"]))
            return
        }
        let doc = wishlistCollection(for: uid).document(gameId)
        if isCurrentlyIn {
            doc.delete(completion: completion)
        } else {
            doc.setData(["addedAt": FieldValue.serverTimestamp()], completion: completion)
        }
    }
}
