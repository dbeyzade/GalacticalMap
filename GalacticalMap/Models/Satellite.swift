//
//  Satellite.swift
//  GalacticalMap
//
//  Uydu modeli - NASA ve Roscosmos uyduları için
//

import Foundation
import CoreLocation

enum SatelliteOrigin: String, Codable, CaseIterable {
    case nasa = "NASA (USA)"
    case roscosmos = "Roscosmos (Russia)"
    case esa = "ESA (Europe)"
    case jaxa = "JAXA (Japan)"
    case other = "Other"
}

enum SatelliteType: String, Codable, CaseIterable {
    case iss = "International Space Station"
    case earth = "Earth Observation"
    case weather = "Weather"
    case communication = "Communication"
    case scientific = "Scientific Research"
    case navigation = "Navigation"
    case military = "Military"
}

struct Satellite: Identifiable, Codable, Hashable {
    let id: Int
    let name: String
    let noradId: String
    let origin: SatelliteOrigin
    let type: SatelliteType
    var latitude: Double
    var longitude: Double
    var altitude: Double
    var velocity: Double
    var azimuth: Double
    var elevation: Double
    var isVisible: Bool
    var nextPass: Date?
    var liveStreamURL: String?
    var description: String
    var launchDate: Date?
    var isFavorite: Bool = false
    
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Örnek uydular
    static let examples: [Satellite] = [
        Satellite(
            id: 1,
            name: "ISS (Zarya)",
            noradId: "25544",
            origin: .nasa,
            type: .iss,
            latitude: 51.6,
            longitude: -0.1,
            altitude: 408.0,
            velocity: 27600.0,
            azimuth: 45.0,
            elevation: 30.0,
            isVisible: true,
            nextPass: Date().addingTimeInterval(3600),
            liveStreamURL: "https://wheretheiss.at/",
            description: "International Space Station - joint NASA and Roscosmos project",
            launchDate: Calendar.current.date(from: DateComponents(year: 1998, month: 11, day: 20))
        ),
        Satellite(
            id: 2,
            name: "Hubble Space Telescope",
            noradId: "20580",
            origin: .nasa,
            type: .scientific,
            latitude: 28.5,
            longitude: -80.6,
            altitude: 547.0,
            velocity: 27300.0,
            azimuth: 90.0,
            elevation: 45.0,
            isVisible: false,
            liveStreamURL: nil,
            description: "NASA's space telescope - deep space observations",
            launchDate: Calendar.current.date(from: DateComponents(year: 1990, month: 4, day: 24))
        ),
        Satellite(
            id: 3,
            name: "NOAA-20 (JPSS-1)",
            noradId: "43013",
            origin: .nasa,
            type: .weather,
            latitude: 35.0,
            longitude: -100.0,
            altitude: 824.0,
            velocity: 27000.0,
            azimuth: 180.0,
            elevation: 15.0,
            isVisible: true,
            nextPass: Date().addingTimeInterval(7200),
            liveStreamURL: nil,
            description: "NASA weather and climate monitoring satellite",
            launchDate: Calendar.current.date(from: DateComponents(year: 2017, month: 11, day: 18))
        ),
        Satellite(
            id: 4,
            name: "Spektr-RG",
            noradId: "44389",
            origin: .roscosmos,
            type: .scientific,
            latitude: 0.0,
            longitude: 0.0,
            altitude: 1500000.0,
            velocity: 3000.0,
            azimuth: 270.0,
            elevation: 60.0,
            isVisible: false,
            liveStreamURL: nil,
            description: "Roscosmos X-ray space telescope",
            launchDate: Calendar.current.date(from: DateComponents(year: 2019, month: 7, day: 13))
        ),
        Satellite(
            id: 5,
            name: "GLONASS-M",
            noradId: "41554",
            origin: .roscosmos,
            type: .navigation,
            latitude: 64.8,
            longitude: 45.0,
            altitude: 19130.0,
            velocity: 13900.0,
            azimuth: 135.0,
            elevation: 50.0,
            isVisible: true,
            nextPass: Date().addingTimeInterval(5400),
            liveStreamURL: nil,
            description: "Russia's global navigation system satellite",
            launchDate: Calendar.current.date(from: DateComponents(year: 2014, month: 3, day: 24))
        ),
        Satellite(
            id: 6,
            name: "Soyuz MS",
            noradId: "48756",
            origin: .roscosmos,
            type: .iss,
            latitude: 51.6,
            longitude: -0.5,
            altitude: 410.0,
            velocity: 27600.0,
            azimuth: 50.0,
            elevation: 35.0,
            isVisible: true,
            nextPass: Date().addingTimeInterval(3700),
            liveStreamURL: nil,
            description: "Roscosmos crew transport vehicle to the ISS",
            launchDate: Calendar.current.date(from: DateComponents(year: 2021, month: 10, day: 5))
        ),
        Satellite(
            id: 7,
            name: "Terra (EOS AM-1)",
            noradId: "25994",
            origin: .nasa,
            type: .earth,
            latitude: 40.0,
            longitude: -75.0,
            altitude: 705.0,
            velocity: 27000.0,
            azimuth: 200.0,
            elevation: 25.0,
            isVisible: true,
            nextPass: Date().addingTimeInterval(4800),
            liveStreamURL: nil,
            description: "NASA Earth observation satellite - climate change monitoring",
            launchDate: Calendar.current.date(from: DateComponents(year: 1999, month: 12, day: 18))
        )
    ]
}

// Uydu pozisyon güncellemesi için response modeli
struct SatellitePosition: Codable {
    let satid: Int
    let satname: String
    let satlatitude: Double
    let satlongitude: Double
    let sataltitude: Double
    let azimuth: Double
    let elevation: Double
    let ra: Double
    let dec: Double
    let timestamp: Int
}

struct SatellitePassInfo: Codable {
    let startAz: Double
    let startAzCompass: String
    let startEl: Double
    let startUTC: Int
    let maxAz: Double
    let maxAzCompass: String
    let maxEl: Double
    let maxUTC: Int
    let endAz: Double
    let endAzCompass: String
    let endEl: Double
    let endUTC: Int
    let mag: Double
    let duration: Int
}
