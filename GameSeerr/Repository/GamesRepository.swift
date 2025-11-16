//
//  GamesRepository.swift
//  GameSeerr
//
//  Queries for games (top rated, recent, and simple title search)
//

import Foundation
import FirebaseFirestore

protocol GamesRepository {
    func fetchTopRated(limit: Int, completion: @escaping (Result<[Game], Error>) -> Void)
    func fetchRecent(limit: Int, completion: @escaping (Result<[Game], Error>) -> Void)
    func search(byTitle query: String, limit: Int, completion: @escaping (Result<[Game], Error>) -> Void)
    func fetchMany(ids: [String], completion: @escaping (Result<[Game], Error>) -> Void)
}

final class FirestoreGamesRepository: GamesRepository {
    private let db = FirebaseManager.shared.db

    /// helper to map snapshot -> [Game]
    private func toGames(_ snapshot: QuerySnapshot?) -> [Game] {
        guard let docs = snapshot?.documents else { return [] }
        return docs.compactMap { Game(id: $0.documentID, data: $0.data()) }
    }
    
    // IMPLEMENTATION
    func fetchMany(ids: [String], completion: @escaping (Result<[Game], Error>) -> Void) {
        if ids.isEmpty { completion(.success([])); return }

        let chunks: [[String]] = stride(from: 0, to: ids.count, by: 10).map {
            Array(ids[$0..<min($0 + 10, ids.count)])
        }

        var all: [Game] = []
        var pending = chunks.count
        var firstError: Error?

        for part in chunks {
            db.collection("games")
                .whereField(FieldPath.documentID(), in: part)
                .getDocuments { snap, err in
                    if let err = err { firstError = firstError ?? err }
                    all.append(contentsOf: self.toGames(snap))
                    pending -= 1

                    if pending == 0 {
                        if let err = firstError { completion(.failure(err)); return }
                        // keep same order as ids
                        let map = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })
                        let ordered = ids.compactMap { map[$0] }
                        completion(.success(ordered))
                    }
                }
        }
    }

    /// highest ratingAvg first
    func fetchTopRated(limit: Int = 20, completion: @escaping (Result<[Game], Error>) -> Void) {
        db.collection("games")
            .order(by: "ratingAvg", descending: true)
            .limit(to: limit)
            .getDocuments { snap, err in
                if let err = err { completion(.failure(err)); return }
                completion(.success(self.toGames(snap)))
            }
    }

    /// newest releases first
    func fetchRecent(limit: Int = 20, completion: @escaping (Result<[Game], Error>) -> Void) {
        db.collection("games")
            .order(by: "releaseDate", descending: true)
            .limit(to: limit)
            .getDocuments { snap, err in
                if let err = err { completion(.failure(err)); return }
                completion(.success(self.toGames(snap)))
            }
    }

    /// prefix search on title
    func search(byTitle query: String, limit: Int = 20, completion: @escaping (Result<[Game], Error>) -> Void) {
        let start = query
        let end = query + "\u{f8ff}"
        db.collection("games")
            .order(by: "title")
            .start(at: [start])
            .end(at: [end])
            .limit(to: limit)
            .getDocuments { snap, err in
                if let err = err { completion(.failure(err)); return }
                completion(.success(self.toGames(snap)))
            }
    }
}
