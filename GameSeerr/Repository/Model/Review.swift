//
//  Review.swift
//  GameSeerr
//
//  Created by Dean Goodwin on 1/11/2025.
//

import Foundation
import FirebaseFirestore

struct Review {
    let id: String
    let gameId: String
    let userId: String
    let rating: Double
    let body: String
    let createdAt: Date
    let updatedAt: Date?

    init?(id: String, data: [String: Any]) {
        guard
            let gameId  = data["gameId"]  as? String,
            let userId  = data["userId"]  as? String,
            let rating  = data["rating"]  as? Double,
            let body    = data["body"]    as? String
        else {
            return nil
        }

        let createdTs = data["createdAt"] as? Timestamp
        let updatedTs = data["updatedAt"] as? Timestamp

        self.id        = id
        self.gameId    = gameId
        self.userId    = userId
        self.rating    = rating
        self.body      = body
        self.createdAt = createdTs?.dateValue() ?? Date()
        self.updatedAt = updatedTs?.dateValue()
    }
}

