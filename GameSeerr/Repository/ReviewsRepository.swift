import Foundation
import FirebaseFirestore

// MARK: - Protocol
protocol ReviewsRepository {
    func fetchForGame(
        gameId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    )

    /// Fetch this user's review for a specific game (if it exists)
    func fetchUserReview(
        gameId: String,
        userId: String,
        completion: @escaping (Result<Review?, Error>) -> Void
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

    // MARK: - FETCH (all reviews for a game)
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

    // MARK: - FETCH USER REVIEW (check if user already reviewed this game)
    func fetchUserReview(
        gameId: String,
        userId: String,
        completion: @escaping (Result<Review?, Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("gameId", isEqualTo: gameId)
            .whereField("userId", isEqualTo: userId)
            .limit(to: 1)
            .getDocuments { snap, err in
                if let err = err {
                    completion(.failure(err))
                    return
                }

                guard let doc = snap?.documents.first else {
                    completion(.success(nil))   // user has no review for this game
                    return
                }

                let review = Review(id: doc.documentID, data: doc.data())
                completion(.success(review))
            }
    }

    // MARK: - ADD (with duplicate check)
    func addReview(
        gameId: String,
        userId: String,
        rating: Double,
        body: String,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        // First check if this user already reviewed this game
        fetchUserReview(gameId: gameId, userId: userId) { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                completion(.failure(error))

            case .success(let existing):
                if existing != nil {
                    // Duplicate found → return a friendly error
                    let err = NSError(
                        domain: "duplicateReview",
                        code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "You have already reviewed this game."]
                    )
                    completion(.failure(err))
                    return
                }

                // No duplicate → proceed to add new review
                let now = FieldValue.serverTimestamp()

                let data: [String: Any] = [
                    "gameId": gameId,
                    "userId": userId,
                    "rating": rating,
                    "body": body,
                    "createdAt": now,
                    "updatedAt": now
                ]

                self.db.collection("reviews").addDocument(data: data) { error in
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    self.recalculateAverage(forGameId: gameId, completion: completion)
                }
            }
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
