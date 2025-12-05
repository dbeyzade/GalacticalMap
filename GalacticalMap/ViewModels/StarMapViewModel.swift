//
//  StarMapViewModel.swift
//  GalacticalMap
//
//  Yıldız haritası yönetimi için ViewModel
//

import Foundation
import SwiftUI
import Combine
import CoreLocation

@MainActor
class StarMapViewModel: ObservableObject {
    @Published var stars: [Star] = []
    @Published var savedStars: [Star] = []
    @Published var selectedStar: Star?
    @Published var searchText = ""
    @Published var filterConstellation: Constellation?
    @Published var filterStarType: StarType?
    @Published var showOnlySaved = false
    @Published var sortBy: StarSortOption = .brightness
    
    enum StarSortOption: String, CaseIterable {
        case brightness = "Parlaklık"
        case distance = "Uzaklık"
        case name = "İsim"
    }
    
    var filteredStars: [Star] {
        var filtered = showOnlySaved ? savedStars : stars
        
        if !searchText.isEmpty {
            filtered = filtered.filter { star in
                star.name.localizedCaseInsensitiveContains(searchText) ||
                star.commonName?.localizedCaseInsensitiveContains(searchText) ?? false
            }
        }
        
        if let constellation = filterConstellation {
            filtered = filtered.filter { $0.constellation == constellation }
        }
        
        if let starType = filterStarType {
            filtered = filtered.filter { $0.starType == starType }
        }
        
        // Sıralama
        switch sortBy {
        case .brightness:
            filtered.sort { $0.magnitude < $1.magnitude }
        case .distance:
            filtered.sort { $0.distance < $1.distance }
        case .name:
            filtered.sort { $0.name < $1.name }
        }
        
        return filtered
    }
    
    var visibleStars: [Star] {
        // Konuma göre görünür yıldızları hesapla
        filteredStars
    }
    
    init() {
        stars = Star.database
        loadSavedStars()
    }
    
    func saveStar(_ star: Star) {
        if let index = stars.firstIndex(where: { $0.id == star.id }) {
            stars[index].isSaved = true
            stars[index].savedDate = Date()
            savedStars.append(stars[index])
            
            // Persistence'a kaydet
            Task {
                await PersistenceManager.shared.saveStar(stars[index])
            }
        }
    }
    
    func unsaveStar(_ star: Star) {
        if let index = stars.firstIndex(where: { $0.id == star.id }) {
            stars[index].isSaved = false
            savedStars.removeAll { $0.id == star.id }
        }
    }
    
    func incrementObservation(_ star: Star) {
        if let index = stars.firstIndex(where: { $0.id == star.id }) {
            stars[index].observationCount += 1
        }
    }
    
    func addNote(to star: Star, note: String) {
        if let index = stars.firstIndex(where: { $0.id == star.id }) {
            stars[index].notes = note
        }
    }
    
    func getStarsInConstellation(_ constellation: Constellation) -> [Star] {
        stars.filter { $0.constellation == constellation }
    }
    
    func getVisibleStarsNow(location: CLLocationCoordinate2D) -> [Star] {
        stars.filter { star in
            let (altitude, _) = star.altitudeAzimuth(for: location)
            return altitude > 0 // Ufuk üzerinde
        }
    }
    
    private func loadSavedStars() {
        // SwiftData'dan kaydedilmiş yıldızları yükle
        savedStars = stars.filter { $0.isSaved }
    }
}
