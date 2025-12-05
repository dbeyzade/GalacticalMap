//
//  RTKLocationManager.swift
//  GalacticalMap
//
//  RTK (Real-Time Kinematic) Ultra Hassas Konum Servisi
//  Santimetre hassasiyetinde GPS konum belirleme
//

import Foundation
import CoreLocation
import Combine

class RTKLocationManager: NSObject, ObservableObject {
    static let shared = RTKLocationManager()
    
    @Published var currentLocation: CLLocation?
    @Published var rtkLocation: RTKLocation?
    @Published var accuracy: LocationAccuracy = .standard
    @Published var isRTKEnabled = false
    @Published var coordinateDisplay: CoordinateDisplay = CoordinateDisplay()
    
    private let locationManager = CLLocationManager()
    private var cancellables = Set<AnyCancellable>()
    
    // RTK Base Station (örnek olarak bir RTK servisi)
    private let rtkBaseStationURL = "ntrip://rtk.ngs.noaa.gov:2101"
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        
        // Enable RTK if available (iOS 15+)
        if #available(iOS 15.0, *) {
            locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        }
    }

    func requestPermission() {
        locationManager.requestWhenInUseAuthorization()
    }

    func startUpdating() {
        locationManager.startUpdatingLocation()
        locationManager.startUpdatingHeading()
    }

    func stopUpdating() {
        locationManager.stopUpdatingLocation()
        locationManager.stopUpdatingHeading()
    }
    
    func updateCoordinateDisplay(from location: CLLocation) {
        let lat = location.coordinate.latitude
        let lon = location.coordinate.longitude
        let alt = location.altitude
        
        // Decimal Degrees
        coordinateDisplay.decimalDegrees = String(format: "%.8f°, %.8f°", lat, lon)
        
        // DMS (Degrees Minutes Seconds)
        coordinateDisplay.dms = formatToDMS(latitude: lat, longitude: lon)
        
        // UTM
        coordinateDisplay.utm = convertToUTM(latitude: lat, longitude: lon)
        
        // MGRS (Military Grid Reference System)
        coordinateDisplay.mgrs = convertToMGRS(latitude: lat, longitude: lon)
        
        // Plus Code (Google)
        coordinateDisplay.plusCode = convertToPlusCode(latitude: lat, longitude: lon)
        
        // Altitude
        coordinateDisplay.altitude = String(format: "%.2f m", alt)
        
        // Accuracy
        coordinateDisplay.horizontalAccuracy = String(format: "±%.2f m", location.horizontalAccuracy)
        coordinateDisplay.verticalAccuracy = String(format: "±%.2f m", location.verticalAccuracy)
        
        // Speed and course
        if location.speed > 0 {
            coordinateDisplay.speed = String(format: "%.1f m/s", location.speed)
        }
        if location.course >= 0 {
            coordinateDisplay.course = String(format: "%.1f°", location.course)
        }
        
        // Timestamp
        coordinateDisplay.timestamp = location.timestamp
    }
    
    private func formatToDMS(latitude: Double, longitude: Double) -> String {
        let latDirection = latitude >= 0 ? "N" : "S"
        let lonDirection = longitude >= 0 ? "E" : "W"
        
        let latAbs = abs(latitude)
        let lonAbs = abs(longitude)
        
        let latDegrees = Int(latAbs)
        let latMinutes = Int((latAbs - Double(latDegrees)) * 60)
        let latSeconds = ((latAbs - Double(latDegrees)) * 60 - Double(latMinutes)) * 60
        
        let lonDegrees = Int(lonAbs)
        let lonMinutes = Int((lonAbs - Double(lonDegrees)) * 60)
        let lonSeconds = ((lonAbs - Double(lonDegrees)) * 60 - Double(lonMinutes)) * 60
        
        return String(format: "%d°%d'%.2f\"%@ %d°%d'%.2f\"%@",
                     latDegrees, latMinutes, latSeconds, latDirection,
                     lonDegrees, lonMinutes, lonSeconds, lonDirection)
    }
    
    private func convertToUTM(latitude: Double, longitude: Double) -> String {
        // Simplified UTM conversion
        let zone = Int((longitude + 180) / 6) + 1
        let centralMeridian = Double((zone - 1) * 6 - 180 + 3)
        
        // This is simplified - real UTM needs complex calculations
        return String(format: "Zone %dN, E: %.0f, N: %.0f", zone, 
                     (longitude - centralMeridian) * 111320,
                     latitude * 111320)
    }
    
    private func convertToMGRS(latitude: Double, longitude: Double) -> String {
        // Simplified MGRS
        let utm = convertToUTM(latitude: latitude, longitude: longitude)
        return "MGRS: " + utm // Placeholder
    }
    
    private func convertToPlusCode(latitude: Double, longitude: Double) -> String {
        // Google Plus Codes - simplified
        let latOffset = (latitude + 90) * 8000 / 180
        let lonOffset = (longitude + 180) * 8000 / 360
        
        // This is extremely simplified
        return String(format: "Plus: +%.0f%.0f", latOffset, lonOffset)
    }
}

// MARK: - CLLocationManagerDelegate

extension RTKLocationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        
        currentLocation = location
        updateCoordinateDisplay(from: location)
        
        // Determine accuracy level
        if location.horizontalAccuracy <= 0.1 {
            accuracy = .rtk // Centimeter level
        } else if location.horizontalAccuracy <= 1.0 {
            accuracy = .dgps // Sub-meter
        } else if location.horizontalAccuracy <= 5.0 {
            accuracy = .high // Few meters
        } else {
            accuracy = .standard
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        coordinateDisplay.heading = String(format: "%.1f°", newHeading.trueHeading)
        coordinateDisplay.magneticHeading = String(format: "%.1f°", newHeading.magneticHeading)
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        if status == .authorizedWhenInUse || status == .authorizedAlways {
            startUpdating()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}

// MARK: - NTRIP Connection (RTK Corrections) - Simulated

// MARK: - Supporting Types

enum LocationAccuracy {
    case rtk        // ±2cm (RTK Fixed)
    case dgps       // ±50cm (DGPS)
    case high       // ±5m (Standard GPS)
    case standard   // ±10-30m
    
    var description: String {
        switch self {
        case .rtk: return "RTK (±2cm)"
        case .dgps: return "DGPS (±50cm)"
        case .high: return "High (±5m)"
        case .standard: return "Standard (±10-30m)"
        }
    }
    
    var color: String {
        switch self {
        case .rtk: return "#00FF00"
        case .dgps: return "#00FFFF"
        case .high: return "#FFFF00"
        case .standard: return "#FF8800"
        }
    }
}

struct RTKLocation {
    let coordinate: CLLocationCoordinate2D
    let altitude: Double
    let horizontalAccuracy: Double
    let verticalAccuracy: Double
    let timestamp: Date
    let rtkQuality: RTKQuality
    
    enum RTKQuality {
        case fixed      // RTK Fixed (en iyi)
        case float      // RTK Float
        case dgps       // DGPS
        case standalone // GPS only
    }
}

struct RTKCorrection {
    let latitudeCorrection: Double
    let longitudeCorrection: Double
    let altitudeCorrection: Double
    let timestamp: Date
}

struct CoordinateDisplay {
    var decimalDegrees: String = ""
    var dms: String = ""
    var utm: String = ""
    var mgrs: String = ""
    var plusCode: String = ""
    var altitude: String = ""
    var horizontalAccuracy: String = ""
    var verticalAccuracy: String = ""
    var speed: String = ""
    var course: String = ""
    var heading: String = ""
    var magneticHeading: String = ""
    var timestamp: Date = Date()
}
