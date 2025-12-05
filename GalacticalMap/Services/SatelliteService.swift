//
//  SatelliteService.swift
//  GalacticalMap
//
//  Uydu API servisi - N2YO API kullanarak canlı uydu verileri
//

import Foundation
import Combine
import CoreLocation

class SatelliteService: ObservableObject {
    private let apiKey = "YOUR_N2YO_API_KEY" // https://www.n2yo.com/api/ - ücretsiz API key
    private let baseURL = "https://api.n2yo.com/rest/v1/satellite"
    
    // Canlı yayın URL'leri
    static let liveStreams: [String: String] = [
        "ISS": "https://www.youtube.com/watch?v=21X5lGlDOfg",
        "NASA TV": "https://www.youtube.com/@NASA/live",
        "ISS HD Earth": "https://www.youtube.com/watch?v=21X5lGlDOfg"
    ]
    
    func fetchSatellitePosition(noradId: String, latitude: Double, longitude: Double) async throws -> SatellitePosition {
        let urlString = "\(baseURL)/positions/\(noradId)/\(latitude)/\(longitude)/0/1/&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(SatellitePositionResponse.self, from: data)
        
        guard let position = response.positions.first else {
            throw NSError(domain: "SatelliteService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No position data"])
        }
        
        return SatellitePosition(
            satid: response.info.satid,
            satname: response.info.satname,
            satlatitude: position.satlatitude,
            satlongitude: position.satlongitude,
            sataltitude: position.sataltitude,
            azimuth: position.azimuth,
            elevation: position.elevation,
            ra: position.ra,
            dec: position.dec,
            timestamp: position.timestamp
        )
    }
    
    func fetchVisualPasses(noradId: String, latitude: Double, longitude: Double, days: Int = 10) async throws -> [SatellitePassInfo] {
        let urlString = "\(baseURL)/visualpasses/\(noradId)/\(latitude)/\(longitude)/0/\(days)/300/&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(VisualPassesResponse.self, from: data)
        
        return response.passes
    }
    
    func fetchAbove(latitude: Double, longitude: Double, altitude: Double = 0, radius: Double = 90) async throws -> [Satellite] {
        let urlString = "\(baseURL)/above/\(latitude)/\(longitude)/\(altitude)/\(radius)/0/&apiKey=\(apiKey)"
        
        guard let url = URL(string: urlString) else {
            throw URLError(.badURL)
        }
        
        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(AboveResponse.self, from: data)
        
        // API yanıtını Satellite modeline dönüştür
        return response.above.map { satInfo in
            Satellite(
                id: satInfo.satid,
                name: satInfo.satname,
                noradId: "\(satInfo.satid)",
                origin: determineSatelliteOrigin(name: satInfo.satname),
                type: determineSatelliteType(name: satInfo.satname),
                latitude: satInfo.satlat,
                longitude: satInfo.satlng,
                altitude: satInfo.satalt,
                velocity: 27000.0, // Ortalama değer
                azimuth: 0,
                elevation: 0,
                isVisible: true,
                description: satInfo.satname
            )
        }
    }
    
    private func determineSatelliteOrigin(name: String) -> SatelliteOrigin {
        let upperName = name.uppercased()
        if upperName.contains("COSMOS") || upperName.contains("MOLNIYA") || upperName.contains("GLONASS") || upperName.contains("SOYUZ") {
            return .roscosmos
        } else if upperName.contains("NOAA") || upperName.contains("NASA") || upperName.contains("TERRA") || upperName.contains("AQUA") || upperName.contains("ISS") {
            return .nasa
        } else if upperName.contains("ESA") || upperName.contains("SENTINEL") {
            return .esa
        } else if upperName.contains("JAXA") {
            return .jaxa
        }
        return .other
    }
    
    private func determineSatelliteType(name: String) -> SatelliteType {
        let upperName = name.uppercased()
        if upperName.contains("ISS") || upperName.contains("TIANGONG") {
            return .iss
        } else if upperName.contains("NOAA") || upperName.contains("GOES") || upperName.contains("METOP") {
            return .weather
        } else if upperName.contains("TERRA") || upperName.contains("LANDSAT") || upperName.contains("SENTINEL") {
            return .earth
        } else if upperName.contains("GPS") || upperName.contains("GLONASS") || upperName.contains("GALILEO") {
            return .navigation
        } else if upperName.contains("HUBBLE") || upperName.contains("CHANDRA") || upperName.contains("SPEKTR") {
            return .scientific
        }
        return .communication
    }
}

// API Response modelleri
private struct SatellitePositionResponse: Codable {
    let info: SatInfo
    let positions: [PositionData]
}

private struct SatInfo: Codable {
    let satid: Int
    let satname: String
}

private struct PositionData: Codable {
    let satlatitude: Double
    let satlongitude: Double
    let sataltitude: Double
    let azimuth: Double
    let elevation: Double
    let ra: Double
    let dec: Double
    let timestamp: Int
}

private struct VisualPassesResponse: Codable {
    let passes: [SatellitePassInfo]
}

private struct AboveResponse: Codable {
    let above: [AboveSatellite]
}

private struct AboveSatellite: Codable {
    let satid: Int
    let satname: String
    let satlat: Double
    let satlng: Double
    let satalt: Double
}
