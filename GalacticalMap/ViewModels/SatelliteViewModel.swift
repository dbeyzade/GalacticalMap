//
//  SatelliteViewModel.swift
//  GalacticalMap
//
//  Uydu yönetimi için ViewModel
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SatelliteViewModel: ObservableObject {
    @Published var satellites: [Satellite] = []
    @Published var selectedSatellite: Satellite?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var filterOrigin: SatelliteOrigin?
    @Published var filterType: SatelliteType?
    @Published var showOnlyVisible = false
    @Published var showOnlyFavorites = false
    
    private let satelliteService = SatelliteService()
    private var cancellables = Set<AnyCancellable>()
    
    var filteredSatellites: [Satellite] {
        satellites.filter { satellite in
            if let origin = filterOrigin, satellite.origin != origin {
                return false
            }
            if let type = filterType, satellite.type != type {
                return false
            }
            if showOnlyVisible && !satellite.isVisible {
                return false
            }
            if showOnlyFavorites && !satellite.isFavorite {
                return false
            }
            return true
        }
    }
    
    var nasaSatellites: [Satellite] {
        satellites.filter { $0.origin == .nasa }
    }
    
    var roscosmosatellites: [Satellite] {
        satellites.filter { $0.origin == .roscosmos }
    }
    
    init() {
        // Başlangıçta örnek uydular
        satellites = Satellite.examples
    }
    
    func loadSatellitesAbove(latitude: Double, longitude: Double) async {
        isLoading = true
        errorMessage = nil
        
        do {
            var fetchedSatellites = try await satelliteService.fetchAbove(
                latitude: latitude,
                longitude: longitude
            )
            
            // ISS için canlı yayın URL'sini ekle (wheretheiss.at haritası)
            if let index = fetchedSatellites.firstIndex(where: { $0.id == 25544 || $0.name.uppercased().contains("ISS") }) {
                fetchedSatellites[index].liveStreamURL = "https://wheretheiss.at/"
            }
            
            satellites = fetchedSatellites
        } catch {
            errorMessage = "Uydu verileri yüklenemedi: \(error.localizedDescription)"
            // Hata durumunda örnek verileri kullan
            satellites = Satellite.examples
        }
        
        isLoading = false
    }
    
    func updateSatellitePosition(_ satellite: Satellite, latitude: Double, longitude: Double) async {
        do {
            let position = try await satelliteService.fetchSatellitePosition(
                noradId: satellite.noradId,
                latitude: latitude,
                longitude: longitude
            )
            
            if let index = satellites.firstIndex(where: { $0.id == satellite.id }) {
                satellites[index].latitude = position.satlatitude
                satellites[index].longitude = position.satlongitude
                satellites[index].altitude = position.sataltitude
                satellites[index].azimuth = position.azimuth
                satellites[index].elevation = position.elevation
            }
        } catch {
            print("Position update failed: \(error)")
        }
    }
    
    func toggleFavorite(_ satellite: Satellite) {
        if let index = satellites.firstIndex(where: { $0.id == satellite.id }) {
            satellites[index].isFavorite.toggle()
        }
    }
    
    func startLiveTracking() {
        // Her 30 saniyede bir güncelleme
        Timer.publish(every: 30, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task {
                    await self?.refreshAllSatellites()
                }
            }
            .store(in: &cancellables)
    }
    
    private func refreshAllSatellites() async {
        // Tüm uyduları güncelle (production'da optimize edilmeli)
        print("Refreshing satellite positions...")
    }
}
