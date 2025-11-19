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
}

// MARK: - Firestore Implementation
final class FirestoreReviewsRepository: ReviewsRepository {

    private let db = FirebaseManager.shared.db

    private func toReviews(_ snapshot: QuerySnapshot?) -> [Review] {
        guard let docs = snapshot?.documents else { return [] }
        return docs.compactMap { Review(id: $0.documentID, data: $0.data()) }
    }

    func fetchForGame(
        gameId: String,
        completion: @escaping (Result<[Review], Error>) -> Void
    ) {
        db.collection("reviews")
            .whereField("gameId", isEqualTo: gameId)
            .getDocuments { snap, err in
                if let err = err {
                    print("fetchForGame error:", err)
                    completion(.failure(err))
                    return
                }

                let list = self.toReviews(snap)
                print("fetchForGame(): snapshot -> \(list.count) reviews")
                completion(.success(list))
            }
    }


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

        db.collection("reviews").addDocument(data: data) { error in
            if let error = error {
                completion(.failure(error))
            } else {
                completion(.success(()))
            }
        }
    }
}
