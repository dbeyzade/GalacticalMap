//
//  FavoritesManager.swift
//  GalacticalMap
//
//  Merkezi favoriler yönetim sistemi
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class FavoritesManager: ObservableObject {
    static let shared = FavoritesManager()
    
    @Published var favoriteItems: [FavoriteItem] = []
    @Published var collections: [FavoriteCollection] = FavoriteCollection.defaultCollections
    @Published var selectedCollection: FavoriteCollection?
    @Published var searchText = ""
    @Published var filterType: FavoriteType?
    @Published var sortOption: SortOption = .dateAdded
    
    enum SortOption: String, CaseIterable {
        case dateAdded = "Eklenme Tarihi"
        case dateModified = "Değiştirme Tarihi"
        case title = "Başlık"
        case rating = "Değerlendirme"
        case viewCount = "Görüntülenme"
    }
    
    private let favoritesKey = "savedFavorites"
    private let collectionsKey = "favoriteCollections"
    
    init() {
        loadFavorites()
        loadCollections()
    }
    
    // MARK: - Favorite Operations
    
    func addFavorite(_ item: FavoriteItem) {
        var newItem = item
        
        // Koleksiyon sayısını güncelle
        if let collectionName = item.collectionName,
           let index = collections.firstIndex(where: { $0.name == collectionName }) {
            collections[index].itemCount += 1
        }
        
        favoriteItems.append(newItem)
        saveFavorites()
        
        // Haptic feedback
        HapticManager.trigger(.success)
    }
    
    func removeFavorite(_ item: FavoriteItem) {
        if let collectionName = item.collectionName,
           let index = collections.firstIndex(where: { $0.name == collectionName }) {
            collections[index].itemCount = max(0, collections[index].itemCount - 1)
        }
        
        favoriteItems.removeAll { $0.id == item.id }
        saveFavorites()
        
        HapticManager.trigger(.warning)
    }
    
    func updateFavorite(_ item: FavoriteItem) {
        if let index = favoriteItems.firstIndex(where: { $0.id == item.id }) {
            favoriteItems[index] = item
            saveFavorites()
        }
    }
    
    func toggleFeatured(_ item: FavoriteItem) {
        if let index = favoriteItems.firstIndex(where: { $0.id == item.id }) {
            favoriteItems[index].isFeatured.toggle()
            saveFavorites()
        }
    }
    
    func incrementViewCount(_ item: FavoriteItem) {
        if let index = favoriteItems.firstIndex(where: { $0.id == item.id }) {
            favoriteItems[index].viewCount += 1
            favoriteItems[index].lastViewedDate = Date()
            saveFavorites()
        }
    }
    
    func addNote(to item: FavoriteItem, note: String) {
        if let index = favoriteItems.firstIndex(where: { $0.id == item.id }) {
            favoriteItems[index].notes = note
            saveFavorites()
        }
    }
    
    func setRating(for item: FavoriteItem, rating: Int) {
        if let index = favoriteItems.firstIndex(where: { $0.id == item.id }) {
            favoriteItems[index].rating = rating
            saveFavorites()
        }
    }
    
    // MARK: - Collection Operations
    
    func createCollection(name: String, description: String?, color: String, icon: String) {
        let collection = FavoriteCollection(name: name, description: description, color: color, icon: icon)
        collections.append(collection)
        saveCollections()
    }
    
    func deleteCollection(_ collection: FavoriteCollection) {
        collections.removeAll { $0.id == collection.id }
        // Koleksiyondaki itemleri de sil veya başka koleksiyona taşı
        favoriteItems.removeAll { $0.collectionName == collection.name }
        saveCollections()
        saveFavorites()
    }
    
    func moveToCollection(_ item: FavoriteItem, collectionName: String) {
        if let index = favoriteItems.firstIndex(where: { $0.id == item.id }) {
            // Eski koleksiyondan çıkar
            if let oldCollection = favoriteItems[index].collectionName,
               let oldIndex = collections.firstIndex(where: { $0.name == oldCollection }) {
                collections[oldIndex].itemCount = max(0, collections[oldIndex].itemCount - 1)
            }
            
            // Yeni koleksiyona ekle
            favoriteItems[index].collectionName = collectionName
            if let newIndex = collections.firstIndex(where: { $0.name == collectionName }) {
                collections[newIndex].itemCount += 1
            }
            
            saveFavorites()
            saveCollections()
        }
    }
    
    // MARK: - Filtering & Sorting
    
    var filteredFavorites: [FavoriteItem] {
        var filtered = favoriteItems
        
        // Koleksiyon filtresi
        if let collection = selectedCollection {
            filtered = filtered.filter { $0.collectionName == collection.name }
        }
        
        // Tip filtresi
        if let type = filterType {
            filtered = filtered.filter { $0.type == type }
        }
        
        // Arama
        if !searchText.isEmpty {
            filtered = filtered.filter { item in
                item.title.localizedCaseInsensitiveContains(searchText) ||
                item.subtitle?.localizedCaseInsensitiveContains(searchText) ?? false ||
                item.tags.contains { $0.localizedCaseInsensitiveContains(searchText) }
            }
        }
        
        // Sıralama
        switch sortOption {
        case .dateAdded:
            filtered.sort { $0.createdDate > $1.createdDate }
        case .dateModified:
            filtered.sort { ($0.lastViewedDate ?? $0.createdDate) > ($1.lastViewedDate ?? $1.createdDate) }
        case .title:
            filtered.sort { $0.title < $1.title }
        case .rating:
            filtered.sort { ($0.rating ?? 0) > ($1.rating ?? 0) }
        case .viewCount:
            filtered.sort { $0.viewCount > $1.viewCount }
        }
        
        return filtered
    }
    
    var featuredFavorites: [FavoriteItem] {
        favoriteItems.filter { $0.isFeatured }
    }
    
    var recentlyViewed: [FavoriteItem] {
        favoriteItems
            .filter { $0.lastViewedDate != nil }
            .sorted { ($0.lastViewedDate ?? Date.distantPast) > ($1.lastViewedDate ?? Date.distantPast) }
            .prefix(10)
            .map { $0 }
    }
    
    var topRated: [FavoriteItem] {
        favoriteItems
            .filter { $0.rating != nil && $0.rating! >= 4 }
            .sorted { ($0.rating ?? 0) > ($1.rating ?? 0) }
    }
    
    // MARK: - Quick Actions
    
    func addSatelliteToFavorites(_ satellite: Satellite, collection: String? = nil) {
        let item = FavoriteItem(
            type: .satellite,
            title: satellite.name,
            subtitle: satellite.origin.rawValue,
            description: satellite.description,
            tags: [satellite.type.rawValue, satellite.origin.rawValue],
            collectionName: collection,
            satelliteData: SatelliteFavoriteData(
                noradId: satellite.noradId,
                origin: satellite.origin.rawValue,
                type: satellite.type.rawValue,
                nextPassTime: satellite.nextPass,
                isCurrentlyVisible: satellite.isVisible
            )
        )
        addFavorite(item)
    }
    
    func addStarToFavorites(_ star: Star, collection: String? = nil) {
        let item = FavoriteItem(
            type: .star,
            title: star.commonName ?? star.name,
            subtitle: star.constellation.rawValue,
            description: "Parlaklık: \(String(format: "%.2f", star.magnitude)), Uzaklık: \(Int(star.distance)) ly",
            tags: [star.constellation.rawValue, star.starType.rawValue, star.spectralType],
            collectionName: collection,
            starData: StarFavoriteData(
                rightAscension: star.rightAscension,
                declination: star.declination,
                magnitude: star.magnitude,
                spectralType: star.spectralType,
                constellation: star.constellation.rawValue
            )
        )
        addFavorite(item)
    }
    
    func addAnomalyToFavorites(_ anomaly: SkyAnomaly, collection: String? = nil) {
        let item = FavoriteItem(
            type: .anomaly,
            title: anomaly.commonName ?? anomaly.name,
            subtitle: anomaly.catalogNumber,
            description: anomaly.description,
            tags: [anomaly.type.rawValue, anomaly.constellation.rawValue],
            collectionName: collection,
            anomalyData: AnomalyFavoriteData(
                catalogNumber: anomaly.catalogNumber,
                anomalyType: anomaly.type.rawValue,
                distance: anomaly.distance,
                constellation: anomaly.constellation.rawValue
            )
        )
        addFavorite(item)
    }
    
    func addScreenshotToFavorites(image: UIImage, title: String, location: CLLocationCoordinate2D?, collection: String? = nil) {
        let imageData = image.jpegData(compressionQuality: 0.8)
        let locationCoord = location != nil ? LocationCoordinate(latitude: location!.latitude, longitude: location!.longitude, altitude: nil) : nil
        
        let item = FavoriteItem(
            type: .screenshot,
            title: title,
            subtitle: "Ekran Görüntüsü",
            imageData: imageData,
            locationCoordinate: locationCoord,
            tags: ["screenshot", "photo"],
            collectionName: collection
        )
        addFavorite(item)
    }
    
    func addLiveStreamToFavorites(title: String, url: String, collection: String? = nil) {
        let item = FavoriteItem(
            type: .livestream,
            title: title,
            subtitle: "Canlı Yayın",
            videoURL: url,
            tags: ["live", "stream"],
            collectionName: collection
        )
        addFavorite(item)
    }
    
    func isFavorited(satelliteId: Int) -> Bool {
        favoriteItems.contains { $0.type == .satellite && $0.satelliteData?.noradId == "\(satelliteId)" }
    }
    
    func isFavorited(starId: UUID) -> Bool {
        favoriteItems.contains { $0.type == .star && $0.starData != nil }
    }
    
    func isFavorited(anomalyId: UUID) -> Bool {
        favoriteItems.contains { $0.type == .anomaly && $0.anomalyData != nil }
    }

    func isFavorited(noradId: String) -> Bool {
        favoriteItems.contains { $0.type == .satellite && $0.satelliteData?.noradId == noradId }
    }
    
    // MARK: - Persistence
    
    private func saveFavorites() {
        if let encoded = try? JSONEncoder().encode(favoriteItems) {
            UserDefaults.standard.set(encoded, forKey: favoritesKey)
        }
    }
    
    private func loadFavorites() {
        if let data = UserDefaults.standard.data(forKey: favoritesKey),
           let decoded = try? JSONDecoder().decode([FavoriteItem].self, from: data) {
            favoriteItems = decoded
        }
    }
    
    private func saveCollections() {
        if let encoded = try? JSONEncoder().encode(collections) {
            UserDefaults.standard.set(encoded, forKey: collectionsKey)
        }
    }
    
    private func loadCollections() {
        if let data = UserDefaults.standard.data(forKey: collectionsKey),
           let decoded = try? JSONDecoder().decode([FavoriteCollection].self, from: data) {
            collections = decoded
        }
    }
    
    // MARK: - Statistics
    
    var totalFavorites: Int {
        favoriteItems.count
    }
    
    var favoritesByType: [FavoriteType: Int] {
        Dictionary(grouping: favoriteItems, by: { $0.type })
            .mapValues { $0.count }
    }
    
    var mostViewedFavorites: [FavoriteItem] {
        favoriteItems
            .sorted { $0.viewCount > $1.viewCount }
            .prefix(5)
            .map { $0 }
    }
}
