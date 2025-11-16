//
//  Game.swift
//  GameSeerr
//
//  Firestore game model (simple struct)
//

import Foundation
import FirebaseFirestore

struct Game {
    let id: String
    let title: String
    let description: String
    let coverUrl: String
    let genres: [String]
    let platforms: [String]
    let ratingAvg: Double
    /// Stored as a *String* in Firestore now
    let releaseDate: String?
    let steamAppId: String
}

// convert Firestore dictionary into Game
extension Game {
    init?(id: String, data: [String: Any]) {
        // title + cover are the two fields I actually need for the UI card
        guard
            let title = data["title"] as? String,
            let coverUrl = data["coverUrl"] as? String
        else { return nil }

        self.id = id
        self.title = title
        self.description = (data["description"] as? String) ?? ""
        self.coverUrl = coverUrl
        self.genres = (data["genres"] as? [String]) ?? []
        self.platforms = (data["platforms"] as? [String]) ?? []
        self.ratingAvg = (data["ratingAvg"] as? Double) ?? 0.0

        // handle String releaseDate
        if let str = data["releaseDate"] as? String {
            self.releaseDate = str
        } else if let ts = data["releaseDate"] as? Timestamp {
            // legacy Timestamp - convert to string
            let date = ts.dateValue()
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            self.releaseDate = df.string(from: date)
        } else if let seconds = data["releaseDate"] as? TimeInterval {
            // legacy seconds since 1970 - convert to string
            let date = Date(timeIntervalSince1970: seconds)
            let df = DateFormatter()
            df.dateFormat = "yyyy-MM-dd"
            self.releaseDate = df.string(from: date)
        } else {
            self.releaseDate = nil
        }

        self.steamAppId = (data["steamAppId"] as? String) ?? ""
    }
}
