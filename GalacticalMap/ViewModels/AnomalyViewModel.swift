//
//  AnomalyViewModel.swift
//  GalacticalMap
//
//  Gökyüzü anomalileri yönetimi için ViewModel
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AnomalyViewModel: ObservableObject {
    @Published var anomalies: [SkyAnomaly] = []
    @Published var savedAnomalies: [SkyAnomaly] = []
    @Published var selectedAnomaly: SkyAnomaly?
    @Published var searchText = ""
    @Published var filterType: AnomalyType?
    @Published var showOnlySaved = false
    @Published var sortBy: AnomalySortOption = .distance
    
    enum AnomalySortOption: String, CaseIterable {
        case distance = "Uzaklık"
        case magnitude = "Parlaklık"
        case name = "İsim"
        case size = "Boyut"
    }
    
    var filteredAnomalies: [SkyAnomaly] {
        var filtered = showOnlySaved ? savedAnomalies : anomalies
        
        if !searchText.isEmpty {
            filtered = filtered.filter { anomaly in
                anomaly.name.localizedCaseInsensitiveContains(searchText) ||
                anomaly.commonName?.localizedCaseInsensitiveContains(searchText) ?? false ||
                anomaly.catalogNumber.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        if let type = filterType {
            filtered = filtered.filter { $0.type == type }
        }
        
        // Sıralama
        switch sortBy {
        case .distance:
            filtered.sort { $0.distance < $1.distance }
        case .magnitude:
            filtered.sort { $0.magnitude < $1.magnitude }
        case .name:
            filtered.sort { $0.name < $1.name }
        case .size:
            filtered.sort { $0.size > $1.size }
        }
        
        return filtered
    }
    
    var nebulae: [SkyAnomaly] {
        anomalies.filter { $0.type == .nebula || $0.type == .planetaryNebula || $0.type == .darkNebula }
    }
    
    var galaxies: [SkyAnomaly] {
        anomalies.filter { $0.type == .galaxy }
    }
    
    var blackHoles: [SkyAnomaly] {
        anomalies.filter { $0.type == .blackHole }
    }
    
    var clusters: [SkyAnomaly] {
        anomalies.filter { $0.type == .openCluster || $0.type == .globularCluster }
    }
    
    init() {
        anomalies = SkyAnomaly.database
        loadSavedAnomalies()
    }
    
    func saveAnomaly(_ anomaly: SkyAnomaly) {
        if let index = anomalies.firstIndex(where: { $0.id == anomaly.id }) {
            anomalies[index].isSaved = true
            savedAnomalies.append(anomalies[index])
            
            // Persistence'a kaydet
            Task {
                await PersistenceManager.shared.saveAnomaly(anomalies[index])
            }
        }
    }
    
    func unsaveAnomaly(_ anomaly: SkyAnomaly) {
        if let index = anomalies.firstIndex(where: { $0.id == anomaly.id }) {
            anomalies[index].isSaved = false
            savedAnomalies.removeAll { $0.id == anomaly.id }
        }
    }
    
    func addNotes(to anomaly: SkyAnomaly, notes: String) {
        if let index = anomalies.firstIndex(where: { $0.id == anomaly.id }) {
            anomalies[index].observationNotes = notes
        }
    }
    
    func getAnomaliesByType(_ type: AnomalyType) -> [SkyAnomaly] {
        anomalies.filter { $0.type == type }
    }
    
    private func loadSavedAnomalies() {
        // SwiftData'dan kaydedilmiş anomalileri yükle
        savedAnomalies = anomalies.filter { $0.isSaved }
    }
}
