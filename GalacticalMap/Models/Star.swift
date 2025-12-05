//
//  Star.swift
//  GalacticalMap
//
//  Yıldız modeli - Kaydedilebilir yıldızlar
//

import Foundation
import CoreLocation

enum StarType: String, Codable, CaseIterable {
    case mainSequence = "Main Sequence"
    case redGiant = "Red Giant"
    case whiteDwarf = "White Dwarf"
    case neutronStar = "Neutron Star"
    case blackHole = "Black Hole"
    case supergiant = "Supergiant"
}

enum Constellation: String, Codable, CaseIterable {
    case ursamajor = "Ursa Major"
    case ursaminor = "Ursa Minor"
    case orion = "Orion"
    case cassiopeia = "Cassiopeia"
    case andromeda = "Andromeda"
    case perseus = "Perseus"
    case cygnus = "Cygnus"
    case lyra = "Lyra"
    case aquila = "Aquila"
    case scorpius = "Scorpius"
    case sagittarius = "Sagittarius"
    case leo = "Leo"
    case gemini = "Gemini"
    case taurus = "Taurus"
    case aries = "Aries"
    case other = "Other"
}

struct Star: Identifiable, Codable, Hashable {
    let id: UUID
    let name: String
    let commonName: String?
    let rightAscension: Double  // Saat açısı (0-24)
    let declination: Double     // Derece (-90 to +90)
    let magnitude: Double       // Görünür parlaklık
    let distance: Double        // Işık yılı
    let spectralType: String    // O, B, A, F, G, K, M
    let starType: StarType
    let constellation: Constellation
    let temperature: Double     // Kelvin
    let radius: Double          // Güneş yarıçapı cinsinden
    let mass: Double           // Güneş kütlesi cinsinden
    var isSaved: Bool = false
    var notes: String?
    var savedDate: Date?
    var observationCount: Int = 0
    
    // Hesaplanan özellikler
    var absoluteMagnitude: Double {
        magnitude - 5 * log10(distance / 10)
    }
    
    var luminosity: Double {
        pow(10, (4.83 - absoluteMagnitude) / 2.5)
    }
    
    // Popüler yıldızlar veritabanı
    static let database: [Star] = [
        Star(
            id: UUID(),
            name: "Alpha Ursae Minoris",
            commonName: "Polaris (North Star)",
            rightAscension: 2.530,
            declination: 89.264,
            magnitude: 1.98,
            distance: 433,
            spectralType: "F7Ib",
            starType: .supergiant,
            constellation: .ursaminor,
            temperature: 6015,
            radius: 46,
            mass: 5.4,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Alpha Canis Majoris",
            commonName: "Sirius",
            rightAscension: 6.752,
            declination: -16.716,
            magnitude: -1.46,
            distance: 8.6,
            spectralType: "A1V",
            starType: .mainSequence,
            constellation: .other,
            temperature: 9940,
            radius: 1.711,
            mass: 2.063,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Alpha Orionis",
            commonName: "Betelgeuse",
            rightAscension: 5.919,
            declination: 7.407,
            magnitude: 0.50,
            distance: 548,
            spectralType: "M1-2Ia-ab",
            starType: .redGiant,
            constellation: .orion,
            temperature: 3500,
            radius: 887,
            mass: 16.5,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Alpha Lyrae",
            commonName: "Vega",
            rightAscension: 18.615,
            declination: 38.783,
            magnitude: 0.03,
            distance: 25,
            spectralType: "A0Va",
            starType: .mainSequence,
            constellation: .lyra,
            temperature: 9602,
            radius: 2.362,
            mass: 2.135,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Alpha Scorpii",
            commonName: "Antares",
            rightAscension: 16.490,
            declination: -26.432,
            magnitude: 0.96,
            distance: 550,
            spectralType: "M1.5Iab-Ib",
            starType: .supergiant,
            constellation: .scorpius,
            temperature: 3660,
            radius: 883,
            mass: 12.4,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Alpha Aquilae",
            commonName: "Altair",
            rightAscension: 19.846,
            declination: 8.868,
            magnitude: 0.77,
            distance: 16.73,
            spectralType: "A7V",
            starType: .mainSequence,
            constellation: .aquila,
            temperature: 7550,
            radius: 1.63,
            mass: 1.79,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Beta Orionis",
            commonName: "Rigel",
            rightAscension: 5.242,
            declination: -8.202,
            magnitude: 0.13,
            distance: 860,
            spectralType: "B8Ia",
            starType: .supergiant,
            constellation: .orion,
            temperature: 11000,
            radius: 78.9,
            mass: 21,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Alpha Centauri A",
            commonName: "Rigil Kentaurus",
            rightAscension: 14.660,
            declination: -60.835,
            magnitude: -0.01,
            distance: 4.37,
            spectralType: "G2V",
            starType: .mainSequence,
            constellation: .other,
            temperature: 5790,
            radius: 1.2234,
            mass: 1.0788,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Alpha Cassiopeiae",
            commonName: "Schedar",
            rightAscension: 0.675,
            declination: 56.537,
            magnitude: 2.24,
            distance: 228,
            spectralType: "K0IIIa",
            starType: .redGiant,
            constellation: .cassiopeia,
            temperature: 4530,
            radius: 42,
            mass: 4.5,
            isSaved: false
        ),
        Star(
            id: UUID(),
            name: "Alpha Cygni",
            commonName: "Deneb",
            rightAscension: 20.690,
            declination: 45.280,
            magnitude: 1.25,
            distance: 2615,
            spectralType: "A2Ia",
            starType: .supergiant,
            constellation: .cygnus,
            temperature: 8525,
            radius: 203,
            mass: 19,
            isSaved: false
        )
    ]
}

// Yıldız pozisyonunu hesaplama için yardımcı fonksiyonlar
extension Star {
    func altitudeAzimuth(for location: CLLocationCoordinate2D, date: Date = Date()) -> (altitude: Double, azimuth: Double) {
        // Basitleştirilmiş hesaplama - gerçek uygulamada astronomi kütüphanesi kullanılmalı
        let latitude = location.latitude * .pi / 180
        let dec = declination * .pi / 180
        
        // Local Sidereal Time hesaplama (basitleştirilmiş)
        let daysSinceJ2000 = date.timeIntervalSince1970 / 86400 - 10957.5
        let lst = (280.46061837 + 360.98564736629 * daysSinceJ2000 + location.longitude).truncatingRemainder(dividingBy: 360)
        let hourAngle = (lst - rightAscension * 15) * .pi / 180
        
        // Altitude hesaplama
        let sinAlt = sin(latitude) * sin(dec) + cos(latitude) * cos(dec) * cos(hourAngle)
        let altitude = asin(sinAlt) * 180 / .pi
        
        // Azimuth hesaplama
        let cosAz = (sin(dec) - sin(latitude) * sinAlt) / (cos(latitude) * cos(asin(sinAlt)))
        var azimuth = acos(cosAz) * 180 / .pi
        
        if sin(hourAngle) > 0 {
            azimuth = 360 - azimuth
        }
        
        return (altitude, azimuth)
    }
}
