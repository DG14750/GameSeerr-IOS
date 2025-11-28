import Foundation
import FirebaseFirestore

// MARK: - Protocol
protocol ReviewsRepository {
    func fetchForGame(
        gameId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    )

    func addReview(
        gameId: String,
        userId: String,
        rating: Double,
        body: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )

    func updateReview(
        id: String,
        rating: Double,
        body: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )

    func deleteReview(
        id: String,
        gameId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    )
}


// MARK: - Firestore Implementation
final class FirestoreReviewsRepository: ReviewsRepository {

    private let db = FirebaseManager.shared.db

    private func toReviews(_ snapshot: QuerySnapshot?) -> [Review] {
        guard let docs = snapshot?.documents else { return [] }
        return docs.compactMap { Review(id: $0.documentID, data: $0.data()) }
    }


    // MARK: - FETCH
    func fetchForGame(
        gameId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("gameId", isEqualTo: gameId)
            .order(by: "createdAt", descending: true)
            .getDocuments { snap, err in
                if let err = err {
                    completion(.failure(err))
                    return
                }
                completion(.success(self.toReviews(snap)))
            }
    }


    // MARK: - ADD
    func addReview(
        gameId: String,
        userId: String,
        rating: Double,
        body: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let now = FieldValue.serverTimestamp()

        let data: [String: Any] = [
            "gameId": gameId,
            "userId": userId,
            "rating": rating,
            "body": body,
            "createdAt": now,
            "updatedAt": now
        ]

        db.collection("reviews").addDocument(data: data) { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self?.recalculateAverage(forGameId: gameId, completion: completion)
        }
    }


    // MARK: - UPDATE
    func updateReview(
        id: String,
        rating: Double,
        body: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let doc = db.collection("reviews").document(id)
        doc.getDocument { [weak self] snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let data = snapshot?.data(),
                  let gameId = data["gameId"] as? String else {
                completion(.failure(NSError(domain: "missingGameId", code: -1)))
                return
            }

            doc.updateData([
                "rating": rating,
                "body": body,
                "updatedAt": FieldValue.serverTimestamp()
            ]) { error in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                self?.recalculateAverage(forGameId: gameId, completion: completion)
            }
        }
    }


    // MARK: - DELETE
    func deleteReview(
        id: String,
        gameId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let doc = db.collection("reviews").document(id)

        doc.delete { [weak self] error in
            if let error = error {
                completion(.failure(error))
                return
            }

            self?.recalculateAverage(forGameId: gameId, completion: completion)
        }
    }


    // MARK: - Recalculate Average Rating
    private func recalculateAverage(
        forGameId gameId: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let query = db.collection("reviews")
            .whereField("gameId", isEqualTo: gameId)

        query.getDocuments { [weak self] snap, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            let ratings = snap?.documents.compactMap { $0["rating"] as? Double } ?? []
            let count = ratings.count
            let avg = count == 0 ? 0.0 : ratings.reduce(0, +) / Double(count)

            self?.db.collection("games").document(gameId)
                .updateData([
                    "ratingAvg": avg,
                    "ratingCount": count
                ]) { error in
                    if let error = error {
                        completion(.failure(error))
                    } else {
                        completion(.success(()))
                    }
                }
        }
    }
}
