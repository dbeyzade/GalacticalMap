//
//  PersistenceManager.swift
//  GalacticalMap
//
//  Veritabanı yönetimi - SwiftData kullanarak
//

import Foundation
import Combine
import SwiftData

@MainActor
class PersistenceManager: ObservableObject {
    static let shared = PersistenceManager()
    
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: SavedStar.self, SavedAnomaly.self, SavedObservation.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }
    
    func saveStar(_ star: Star) {
        let context = container.mainContext
        let savedStar = SavedStar(from: star)
        context.insert(savedStar)
        try? context.save()
    }
    
    func saveAnomaly(_ anomaly: SkyAnomaly) {
        let context = container.mainContext
        let savedAnomaly = SavedAnomaly(from: anomaly)
        context.insert(savedAnomaly)
        try? context.save()
    }
    
    func saveObservation(title: String, notes: String, location: String, imageData: Data?) {
        let context = container.mainContext
        let observation = SavedObservation(
            title: title,
            notes: notes,
            date: Date(),
            location: location,
            imageData: imageData
        )
        context.insert(observation)
        try? context.save()
    }
}

// SwiftData modelleri
@Model
class SavedStar {
    var id: UUID
    var name: String
    var commonName: String?
    var rightAscension: Double
    var declination: Double
    var magnitude: Double
    var distance: Double
    var spectralType: String
    var constellation: String
    var notes: String?
    var savedDate: Date
    var observationCount: Int
    
    init(from star: Star) {
        self.id = star.id
        self.name = star.name
        self.commonName = star.commonName
        self.rightAscension = star.rightAscension
        self.declination = star.declination
        self.magnitude = star.magnitude
        self.distance = star.distance
        self.spectralType = star.spectralType
        self.constellation = star.constellation.rawValue
        self.notes = star.notes
        self.savedDate = Date()
        self.observationCount = star.observationCount
    }
}

@Model
class SavedAnomaly {
    var id: UUID
    var catalogNumber: String
    var name: String
    var commonName: String?
    var type: String
    var rightAscension: Double
    var declination: Double
    var magnitude: Double
    var distance: Double
    var constellation: String
    var observationNotes: String?
    var savedDate: Date
    
    init(from anomaly: SkyAnomaly) {
        self.id = anomaly.id
        self.catalogNumber = anomaly.catalogNumber
        self.name = anomaly.name
        self.commonName = anomaly.commonName
        self.type = anomaly.type.rawValue
        self.rightAscension = anomaly.rightAscension
        self.declination = anomaly.declination
        self.magnitude = anomaly.magnitude
        self.distance = anomaly.distance
        self.constellation = anomaly.constellation.rawValue
        self.observationNotes = anomaly.observationNotes
        self.savedDate = Date()
    }
}

@Model
class SavedObservation {
    var id: UUID
    var title: String
    var notes: String
    var date: Date
    var location: String
    var imageData: Data?
    
    init(title: String, notes: String, date: Date, location: String, imageData: Data?) {
        self.id = UUID()
        self.title = title
        self.notes = notes
        self.date = date
        self.location = location
        self.imageData = imageData
    }
}
