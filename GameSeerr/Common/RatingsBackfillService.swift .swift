//
//  RatingsBackfillService.swift .swift
//  GameSeerr
//
//  Created by Dean Goodwin on 26/11/2025.
//

import Foundation
import FirebaseFirestore

final class RatingsBackfillService {

    private let db = Firestore.firestore()

    /// Run once to fix all game ratingAvg + ratingCount
    func recomputeAllGameRatings() {
        db.collection("games").getDocuments { [weak self] snapshot, error in
            if let error = error {
                print("Backfill: Failed to load games:", error)
                return
            }
            guard let self, let gameDocs = snapshot?.documents else { return }

            print("Backfill: found \(gameDocs.count) games")

            for gameDoc in gameDocs {
                let gameId = gameDoc.documentID
                self.recomputeRating(forGameId: gameId)
            }
        }
    }

    private func recomputeRating(forGameId gameId: String) {
        db.collection("reviews")
            .whereField("gameId", isEqualTo: gameId)
            .getDocuments { [weak self] snap, error in

                if let error = error {
                    print("Backfill: could not fetch reviews for game \(gameId):", error)
                    return
                }
                guard let self, let docs = snap?.documents else { return }

                let ratings = docs.compactMap { $0.data()["rating"] as? Double }

                let avg: Double = ratings.isEmpty
                    ? 0.0
                    : ratings.reduce(0.0, +) / Double(ratings.count)

                let rounded = (avg * 10).rounded() / 10.0

                self.db.collection("games")
                    .document(gameId)
                    .updateData([
                        "ratingAvg": rounded,
                        "ratingCount": ratings.count
                    ]) { error in
                        if let error = error {
                            print("Backfill: update failed for game \(gameId):", error)
                        } else {
                            print("Backfill: updated game \(gameId) → avg=\(rounded), count=\(ratings.count)")
                        }
                    }
            }
    }
}

