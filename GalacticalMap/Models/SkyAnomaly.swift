//
//  SkyAnomaly.swift
//  GalacticalMap
//
//  Gökyüzü anomalileri - Nebulalar, galaksiler, süpernovalar vb.
//

import Foundation

enum AnomalyType: String, Codable, CaseIterable {
    case nebula = "Nebula"
    case galaxy = "Galaxy"
    case supernova = "Supernova"
    case blackHole = "Black Hole"
    case quasar = "Quasar"
    case pulsar = "Pulsar"
    case planetaryNebula = "Planetary Nebula"
    case openCluster = "Open Cluster"
    case globularCluster = "Globular Cluster"
    case darkNebula = "Dark Nebula"
}

struct SkyAnomaly: Identifiable, Codable, Hashable {
    let id: UUID
    let catalogNumber: String  // M31, NGC 7293, etc.
    let name: String
    let commonName: String?
    let type: AnomalyType
    let rightAscension: Double
    let declination: Double
    let magnitude: Double
    let distance: Double  // Işık yılı veya megaparsek
    let size: Double     // Açısal boyut (arcminutes)
    let constellation: Constellation
    let discoveryDate: Date?
    let discoveredBy: String?
    let description: String
    let imageURL: String?
    var isSaved: Bool = false
    var observationNotes: String?
    
    // Ünlü gökyüzü anomalileri veritabanı
    static let database: [SkyAnomaly] = [
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M31",
            name: "Andromeda Galaxy",
            commonName: "Andromeda",
            type: .galaxy,
            rightAscension: 0.712,
            declination: 41.269,
            magnitude: 3.44,
            distance: 2537000,
            size: 178.0,
            constellation: .andromeda,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 964)),
            discoveredBy: "Abd al-Rahman al-Sufi",
            description: "The nearest major galaxy. On a collision course with the Milky Way. Contains roughly 1 trillion stars.",
            imageURL: "https://apod.nasa.gov/apod/image/2110/M31_HubbleSpitzerGendler_2000.jpg",
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M42",
            name: "Orion Nebula",
            commonName: "Great Orion Nebula",
            type: .nebula,
            rightAscension: 5.583,
            declination: -5.391,
            magnitude: 4.0,
            distance: 1344,
            size: 65.0,
            constellation: .orion,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1610)),
            discoveredBy: "Nicolas-Claude Fabri de Peiresc",
            description: "One of the brightest nebulae. Active star-forming region. Visible to the naked eye.",
            imageURL: "https://apod.nasa.gov/apod/image/2201/OrionNebula_HubbleGendler_1800.jpg",
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M1",
            name: "Crab Nebula",
            commonName: "Yengeç Bulutsusu",
            type: .supernova,
            rightAscension: 5.575,
            declination: 22.017,
            magnitude: 8.4,
            distance: 6500,
            size: 6.0,
            constellation: .taurus,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1054)),
            discoveredBy: "Chinese Astronomers",
            description: "Remnant of the 1054 supernova explosion. Contains a pulsar at its center.",
            imageURL: "https://apod.nasa.gov/apod/image/2212/M1_Hubble_3864.jpg",
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M13",
            name: "Great Globular Cluster",
            commonName: "Hercules Globular Cluster",
            type: .globularCluster,
            rightAscension: 16.695,
            declination: 36.459,
            magnitude: 5.8,
            distance: 25100,
            size: 20.0,
            constellation: .other,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1714)),
            discoveredBy: "Edmond Halley",
            description: "Brightest globular cluster visible in the Northern Hemisphere. Contains about 300,000 stars.",
            imageURL: nil,
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M57",
            name: "Ring Nebula",
            commonName: "Ring Nebula",
            type: .planetaryNebula,
            rightAscension: 18.897,
            declination: 33.029,
            magnitude: 8.8,
            distance: 2300,
            size: 1.4,
            constellation: .lyra,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1779)),
            discoveredBy: "Antoine Darquier de Pellepoix",
            description: "Planetary nebula formed from the outer layers of a dying star.",
            imageURL: nil,
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M45",
            name: "Pleiades",
            commonName: "Pleiades Star Cluster",
            type: .openCluster,
            rightAscension: 3.783,
            declination: 24.117,
            magnitude: 1.6,
            distance: 444,
            size: 110.0,
            constellation: .taurus,
            discoveryDate: nil,
            discoveredBy: "Known since antiquity",
            description: "Open star cluster visible to the naked eye. Known as the Seven Sisters.",
            imageURL: nil,
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "NGC 7293",
            name: "Helix Nebula",
            commonName: "Eye of God",
            type: .planetaryNebula,
            rightAscension: 22.494,
            declination: -20.837,
            magnitude: 7.6,
            distance: 650,
            size: 16.0,
            constellation: .other,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1824)),
            discoveredBy: "Karl Ludwig Harding",
            description: "Closest planetary nebula to Earth. Features a stunning spiral structure.",
            imageURL: nil,
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M51",
            name: "Whirlpool Galaxy",
            commonName: "Whirlpool Galaxy",
            type: .galaxy,
            rightAscension: 13.498,
            declination: 47.195,
            magnitude: 8.4,
            distance: 23000000,
            size: 11.2,
            constellation: .other,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1773)),
            discoveredBy: "Charles Messier",
            description: "First discovered spiral galaxy. Interacting galaxy pair.",
            imageURL: nil,
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M104",
            name: "Sombrero Galaxy",
            commonName: "Sombrero Galaxy",
            type: .galaxy,
            rightAscension: 12.666,
            declination: -11.623,
            magnitude: 8.0,
            distance: 29000000,
            size: 8.7,
            constellation: .other,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1781)),
            discoveredBy: "Pierre Méchain",
            description: "Spiral galaxy famous for its characteristic hat-like shape.",
            imageURL: nil,
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "SgrA*",
            name: "Sagittarius A*",
            commonName: "Milky Way Central Black Hole",
            type: .blackHole,
            rightAscension: 17.761,
            declination: -29.008,
            magnitude: 0,
            distance: 26000,
            size: 0.00005,
            constellation: .sagittarius,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1974)),
            discoveredBy: "Bruce Balick & Robert Brown",
            description: "The supermassive black hole at the center of the Milky Way. About 4 million solar masses.",
            imageURL: nil,
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M8",
            name: "Lagoon Nebula",
            commonName: "Lagoon Nebula",
            type: .nebula,
            rightAscension: 18.063,
            declination: -24.383,
            magnitude: 6.0,
            distance: 4100,
            size: 90.0,
            constellation: .sagittarius,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1654)),
            discoveredBy: "Giovanni Battista Hodierna",
            description: "Active star-forming region. Visible to the naked eye.",
            imageURL: nil,
            isSaved: false
        ),
        SkyAnomaly(
            id: UUID(),
            catalogNumber: "M87",
            name: "Virgo A",
            commonName: "Virgo Galaxy",
            type: .blackHole,
            rightAscension: 12.514,
            declination: 12.391,
            magnitude: 8.6,
            distance: 53500000,
            size: 8.3,
            constellation: .other,
            discoveryDate: Calendar.current.date(from: DateComponents(year: 1781)),
            discoveredBy: "Charles Messier",
            description: "Giant elliptical galaxy containing the first black hole ever imaged. Black hole of 6.5 billion solar masses.",
            imageURL: nil,
            isSaved: false
        )
    ]
}
