//
//  FavoriteItem.swift
//  GalacticalMap
//
//  Gelişmiş favoriler sistemi - Her türlü içeriği favorilere ekle
//

import Foundation
import SwiftUI
import CoreLocation

enum FavoriteType: String, Codable, CaseIterable {
    case satellite = "Satellite"
    case star = "Star"
    case anomaly = "Anomaly"
    case constellation = "Constellation"
    case screenshot = "Screenshot"
    case video = "Video"
    case observation = "Observation"
    case location = "Location"
    case event = "Space Event"
    case livestream = "Live Stream"
}

struct FavoriteItem: Identifiable, Codable, Hashable {
    let id: UUID
    let type: FavoriteType
    let title: String
    let subtitle: String?
    let description: String?
    let imageData: Data?
    let videoURL: String?
    let locationCoordinate: LocationCoordinate?
    let tags: [String]
    var collectionName: String?
    var notes: String?
    var rating: Int? // 1-5 yıldız
    let createdDate: Date
    var lastViewedDate: Date?
    var viewCount: Int
    var isFeatured: Bool
    
    // İlişkili veri (tip bazlı)
    var satelliteData: SatelliteFavoriteData?
    var starData: StarFavoriteData?
    var anomalyData: AnomalyFavoriteData?
    
    init(
        type: FavoriteType,
        title: String,
        subtitle: String? = nil,
        description: String? = nil,
        imageData: Data? = nil,
        videoURL: String? = nil,
        locationCoordinate: LocationCoordinate? = nil,
        tags: [String] = [],
        collectionName: String? = nil,
        notes: String? = nil,
        rating: Int? = nil,
        satelliteData: SatelliteFavoriteData? = nil,
        starData: StarFavoriteData? = nil,
        anomalyData: AnomalyFavoriteData? = nil
    ) {
        self.id = UUID()
        self.type = type
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.imageData = imageData
        self.videoURL = videoURL
        self.locationCoordinate = locationCoordinate
        self.tags = tags
        self.collectionName = collectionName
        self.notes = notes
        self.rating = rating
        self.createdDate = Date()
        self.lastViewedDate = nil
        self.viewCount = 0
        self.isFeatured = false
        self.satelliteData = satelliteData
        self.starData = starData
        self.anomalyData = anomalyData
    }
}

struct LocationCoordinate: Codable, Hashable {
    let latitude: Double
    let longitude: Double
    let altitude: Double?
    
    var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct SatelliteFavoriteData: Codable, Hashable {
    let noradId: String
    let origin: String
    let type: String
    var nextPassTime: Date?
    var isCurrentlyVisible: Bool
}

struct StarFavoriteData: Codable, Hashable {
    let rightAscension: Double
    let declination: Double
    let magnitude: Double
    let spectralType: String
    let constellation: String
}

struct AnomalyFavoriteData: Codable, Hashable {
    let catalogNumber: String
    let anomalyType: String
    let distance: Double
    let constellation: String
}

struct FavoriteCollection: Identifiable, Codable {
    let id: UUID
    var name: String
    var description: String?
    var color: String // Hex color
    var icon: String // SF Symbol name
    var itemCount: Int
    let createdDate: Date
    var isShared: Bool
    
    init(name: String, description: String? = nil, color: String = "#00D4FF", icon: String = "star.fill") {
        self.id = UUID()
        self.name = name
        self.description = description
        self.color = color
        self.icon = icon
        self.itemCount = 0
        self.createdDate = Date()
        self.isShared = false
    }
    
    static let defaultCollections: [FavoriteCollection] = [
        FavoriteCollection(name: "My Favorites", color: "#FFD700", icon: "star.fill"),
        FavoriteCollection(name: "Watchlist", color: "#FF6B6B", icon: "eye.fill"),
        FavoriteCollection(name: "My Observations", color: "#4ECDC4", icon: "checkmark.circle.fill"),
        FavoriteCollection(name: "Upcoming Events", color: "#95E1D3", icon: "calendar"),
    ]
}
