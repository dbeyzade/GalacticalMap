//
//  SatellitePassPrediction.swift
//  GalacticalMap
//
//  Uydu Geçiş Tahmini ve Alarm Sistemi
//  Hangi uydu ne zaman başınızın üzerinden geçecek - Tam zamanında bildirim!
//

import Foundation
import Combine
import CoreLocation
import UserNotifications
import SwiftUI

class SatellitePassPrediction: NSObject, ObservableObject, UNUserNotificationCenterDelegate {
    static let shared = SatellitePassPrediction()
    
    @Published var upcomingPasses: [SatellitePass] = []
    @Published var nextPass: SatellitePass?
    @Published var visibleNow: [SatellitePass] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    // private var updateTimer: Timer? // Disabled for manual refresh only
    @Published var setAlarms: Set<UUID> = [] // Track set alarms by pass ID (using UUID here for simplicity, but pass ID changes on recalc. Better use satellite ID + time)
    
    override init() {
        super.init()
        notificationCenter.delegate = self
        requestNotificationPermission()
        // startPredictionUpdates() // Don't auto start, wait for view
    }
    
    // MARK: - Notification Delegate
    
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.banner, .sound, .list])
    }
    
    // MARK: - Notification Permission
    
    func requestNotificationPermission() {
        notificationCenter.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            }
        }
    }
    
    // MARK: - Pass Prediction
    
    func startPredictionUpdates() {
        updatePasses()
        // Timer removed for manual update only
    }
    
    func updatePasses() {
        guard let location = RTKLocationManager.shared.currentLocation else { return }
        
        // Predict passes for all tracked satellites
        var allPasses: [SatellitePass] = []
        
        for satellite in Satellite.examples {
            let passes = predictPasses(
                for: satellite,
                location: location,
                daysAhead: 7
            )
            allPasses.append(contentsOf: passes)
        }
        
        // Sort by start time
        allPasses.sort { $0.riseTime < $1.riseTime }
        
        DispatchQueue.main.async {
            self.upcomingPasses = allPasses
            self.nextPass = allPasses.first
            self.visibleNow = allPasses.filter { $0.isVisibleNow }
            
            // Auto-scheduling removed. User must manually set alarms.
            // self.scheduleNotifications(for: allPasses)
        }
    }
    
    func toggleAlarm(for pass: SatellitePass) {
        if setAlarms.contains(pass.id) {
            removeAlarm(for: pass)
        } else {
            addAlarm(for: pass)
        }
    }
    
    func addAlarm(for pass: SatellitePass) {
        setAlarms.insert(pass.id)
        
        // 1 Minute before pass
        scheduleNotification(
            for: pass,
            minutesBefore: 1,
            title: "🛰️ Satellite Pass Alert",
            body: "Look at the sky! \(pass.satellite.name) is passing overhead."
        )
    }
    
    func removeAlarm(for pass: SatellitePass) {
        setAlarms.remove(pass.id)
        let identifier = "\(pass.satellite.id)_1_\(pass.riseTime.timeIntervalSince1970)"
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [identifier])
    }
    
    func predictPasses(for satellite: Satellite, location: CLLocation, daysAhead: Int) -> [SatellitePass] {
        var passes: [SatellitePass] = []
        
        let startDate = Date()
        let endDate = startDate.addingTimeInterval(Double(daysAhead) * 86400)
        
        // Simplified orbital prediction
        // In production, use TLE (Two-Line Element) data and SGP4 propagator
        
        // Orbital period (example for LEO satellites)
        let orbitalPeriod: TimeInterval = 5400 // ~90 minutes for ISS
        
        var currentTime = startDate
        
        while currentTime < endDate {
            // Calculate satellite position at this time
            let satPosition = calculateSatellitePosition(
                satellite: satellite,
                time: currentTime,
                observerLocation: location
            )
            
            // Check if visible (above horizon)
            if satPosition.elevation > 0 {
                // Calculate pass details
                let pass = calculatePassDetails(
                    satellite: satellite,
                    startTime: currentTime,
                    location: location
                )
                
                if pass.maxElevation > 10 { // Only add if elevation > 10°
                    passes.append(pass)
                }
                
                // Skip to next orbit
                currentTime = currentTime.addingTimeInterval(orbitalPeriod)
            } else {
                // Advance by 5 minutes
                currentTime = currentTime.addingTimeInterval(300)
            }
        }
        
        return passes
    }
    
    func calculatePassDetails(satellite: Satellite, startTime: Date, location: CLLocation) -> SatellitePass {
        // Simulate pass calculation
        let duration: TimeInterval = Double.random(in: 300...600) // 5-10 minutes
        let maxElevation = Double.random(in: 10...85)
        let startAzimuth = Double.random(in: 0...360)
        let endAzimuth = (startAzimuth + Double.random(in: 90...270)).truncatingRemainder(dividingBy: 360)
        
        let riseTime = startTime
        let culminationTime = startTime.addingTimeInterval(duration / 2)
        let setTime = startTime.addingTimeInterval(duration)
        
        // Determine visibility
        let brightness = 2.0 // Default brightness for satellites
        let isVisible = brightness < 4.5 && maxElevation > 30
        
        return SatellitePass(
            satellite: satellite,
            riseTime: riseTime,
            culminationTime: culminationTime,
            setTime: setTime,
            maxElevation: maxElevation,
            riseAzimuth: startAzimuth,
            setAzimuth: endAzimuth,
            magnitude: brightness,
            isVisible: isVisible,
            distance: Double.random(in: 400...800), // km
            illumination: maxElevation > 30 ? "Sunlit" : "In shadow"
        )
    }
    
    func calculateSatellitePosition(satellite: Satellite, time: Date, observerLocation: CLLocation) -> SatellitePosition {
        // Simplified calculation - real implementation would use SGP4
        
        // Example calculation based on orbital parameters
        let lat = observerLocation.coordinate.latitude
        let lon = observerLocation.coordinate.longitude
        
        // Simplified: satellite moves in circular orbit
        let timeFromEpoch = time.timeIntervalSince1970
        let orbitalRate = 2 * Double.pi / 5400 // radians per second (90 min orbit)
        
        let angle = timeFromEpoch * orbitalRate
        
        let satLat = sin(angle) * 51.6 // ISS-like inclination
        let satLon = cos(angle) * 180
        
        // Calculate azimuth and elevation
        let (azimuth, elevation) = calculateAzEl(
            satLat: satLat,
            satLon: satLon,
            obsLat: lat,
            obsLon: lon
        )
        
        return SatellitePosition(
            satid: satellite.id,
            satname: satellite.name,
            satlatitude: satLat,
            satlongitude: satLon,
            sataltitude: 400000, // 400km
            azimuth: azimuth,
            elevation: elevation,
            ra: 0.0,
            dec: 0.0,
            timestamp: Int(time.timeIntervalSince1970)
        )
    }
    
    func calculateAzEl(satLat: Double, satLon: Double, obsLat: Double, obsLon: Double) -> (azimuth: Double, elevation: Double) {
        // Simplified Az/El calculation
        let deltaLat = satLat - obsLat
        let deltaLon = satLon - obsLon
        
        let azimuth = atan2(deltaLon, deltaLat) * 180 / .pi
        let elevation = max(-90, min(90, deltaLat * 2)) // Simplified
        
        return (azimuth: (azimuth + 360).truncatingRemainder(dividingBy: 360),
                elevation: elevation)
    }
    
    // MARK: - Notifications
    
    func scheduleNotifications(for passes: [SatellitePass]) {
        // Remove existing notifications
        notificationCenter.removeAllPendingNotificationRequests()
        
        // Schedule notifications for next 20 passes
        let passesToNotify = Array(passes.prefix(20))
        
        for pass in passesToNotify {
            // Notification 10 minutes before
            scheduleNotification(
                for: pass,
                minutesBefore: 10,
                title: "🛰️ Satellite Pass Approaching",
                body: "\(pass.satellite.name) will reach \(Int(pass.maxElevation))° elevation"
            )
            
            // Notification at rise time
            scheduleNotification(
                for: pass,
                minutesBefore: 0,
                title: "🛰️ Satellite Visible!",
                body: "\(pass.satellite.name) is now in the sky - Look at \(Int(pass.riseAzimuth))°"
            )
            
            // Notification at max elevation (if very visible)
            if pass.isVisible && pass.maxElevation > 45 {
                let timeToMax = pass.culminationTime.timeIntervalSince(pass.riseTime)
                scheduleNotification(
                    for: pass,
                    minutesBefore: -Int(timeToMax / 60),
                    title: "⭐ Bright Satellite Pass!",
                    body: "\(pass.satellite.name) at brightest point - Look up!"
                )
            }
        }
    }
    
    func scheduleNotification(for pass: SatellitePass, minutesBefore: Int, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.badge = 1
        
        // Add rich info
        content.userInfo = [
            "satelliteId": pass.satellite.id,
            "satelliteName": pass.satellite.name,
            "riseTime": pass.riseTime.timeIntervalSince1970,
            "maxElevation": pass.maxElevation,
            "azimuth": pass.riseAzimuth
        ]
        
        // Category for actions
        content.categoryIdentifier = "SATELLITE_PASS"
        
        // Schedule time
        let notificationTime = pass.riseTime.addingTimeInterval(TimeInterval(-minutesBefore * 60))
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: notificationTime
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        
        let identifier = "\(pass.satellite.id)_\(minutesBefore)_\(pass.riseTime.timeIntervalSince1970)"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }
    
    // MARK: - Helper Methods
    
    func getPassesForToday() -> [SatellitePass] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        
        return upcomingPasses.filter { pass in
            pass.riseTime >= today && pass.riseTime < tomorrow
        }
    }
    
    func getVisiblePasses() -> [SatellitePass] {
        upcomingPasses.filter { $0.isVisible }
    }
    
    func getPassesForSatellite(_ satelliteId: String) -> [SatellitePass] {
        upcomingPasses.filter { String($0.satellite.id) == satelliteId }
    }
}

// MARK: - Models

struct SatellitePass: Identifiable {
    let id = UUID()
    let satellite: Satellite
    let riseTime: Date
    let culminationTime: Date
    let setTime: Date
    let maxElevation: Double // degrees
    let riseAzimuth: Double // degrees
    let setAzimuth: Double // degrees
    let magnitude: Double
    let isVisible: Bool
    let distance: Double // km
    let illumination: String
    
    var duration: TimeInterval {
        setTime.timeIntervalSince(riseTime)
    }
    
    var isVisibleNow: Bool {
        let now = Date()
        return now >= riseTime && now <= setTime
    }
    
    var timeUntilRise: TimeInterval {
        riseTime.timeIntervalSince(Date())
    }
    
    var visibilityDescription: String {
        if magnitude < 0 {
            return "Very Bright (like Venus)"
        } else if magnitude < 2 {
            return "Bright (like a bright star)"
        } else if magnitude < 4 {
            return "Visible (naked eye)"
        } else {
            return "Hard to see (binoculars needed)"
        }
    }
}

// MARK: - Pass Prediction View

struct SatellitePassView: View {
    @StateObject private var predictionService = SatellitePassPrediction.shared
    @StateObject private var locationManager = RTKLocationManager.shared
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedFilter: PassFilter = .all
    
    enum PassFilter {
        case all, visible, today, favorite
    }
    
    var filteredPasses: [SatellitePass] {
        switch selectedFilter {
        case .all:
            return predictionService.upcomingPasses
        case .visible:
            return predictionService.getVisiblePasses()
        case .today:
            return predictionService.getPassesForToday()
        case .favorite:
            return predictionService.upcomingPasses.filter { pass in
                favoritesManager.isFavorited(noradId: pass.satellite.noradId)
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Current location display
                        LocationDisplayCard(manager: locationManager)
                            .padding(.horizontal)
                        
                        // Next pass highlight
                        if let nextPass = predictionService.nextPass {
                            NextPassCard(pass: nextPass)
                                .padding(.horizontal)
                        }
                        
                        // Visible now
                        if !predictionService.visibleNow.isEmpty {
                            VisibleNowSection(passes: predictionService.visibleNow)
                        }
                        
                        // Filter tabs
                        Picker("Filter", selection: $selectedFilter) {
                            Text("All").tag(PassFilter.all)
                            Text("Visible").tag(PassFilter.visible)
                            Text("Today").tag(PassFilter.today)
                            Text("Favorites").tag(PassFilter.favorite)
                        }
                        .pickerStyle(.segmented)
                        .padding(.horizontal)
                        
                        // Pass list
                        LazyVStack(spacing: 12) {
                            ForEach(filteredPasses.prefix(50)) { pass in
                                PassCard(pass: pass)
                                    .padding(.horizontal)
                            }
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Satellite Passes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        predictionService.updatePasses()
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .foregroundColor(.cyan)
                    }
                }
            }
            .onAppear {
                locationManager.requestPermission()
                locationManager.startUpdating()
                predictionService.updatePasses()
            }
            // .onReceive(locationManager.$currentLocation) { _ in
            //    predictionService.updatePasses()
            // }
        }
    }
}

struct LocationDisplayCard: View {
    @ObservedObject var manager: RTKLocationManager
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your Location")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(manager.coordinateDisplay.decimalDegrees)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.cyan)
                    
                    Text(manager.coordinateDisplay.dms)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Accuracy indicator
                VStack(spacing: 4) {
                    ZStack {
                        Circle()
                            .stroke(Color(hex: manager.accuracy.color), lineWidth: 3)
                            .frame(width: 50, height: 50)
                        
                        Image(systemName: manager.isRTKEnabled ? "antenna.radiowaves.left.and.right" : "location.fill")
                            .foregroundColor(Color(hex: manager.accuracy.color))
                    }
                    
                    Text(manager.accuracy.description)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Additional info
            Divider()
                .background(Color.white.opacity(0.3))
            
            HStack {
                InfoPill(label: "Altitude", value: manager.coordinateDisplay.altitude, icon: "mountain.2.fill")
                InfoPill(label: "Heading", value: manager.coordinateDisplay.heading, icon: "location.north.fill")
                InfoPill(label: "Speed", value: manager.coordinateDisplay.speed.isEmpty ? "0 m/s" : manager.coordinateDisplay.speed, icon: "speedometer")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct InfoPill: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct NextPassCard: View {
    let pass: SatellitePass
    @State private var timeRemaining: String = ""
    @ObservedObject var predictionService = SatellitePassPrediction.shared
    
    var isAlarmSet: Bool {
        predictionService.setAlarms.contains(pass.id)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("🛰️ Next Pass")
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Alarm Toggle
                Button {
                    withAnimation {
                        predictionService.toggleAlarm(for: pass)
                    }
                } label: {
                    Image(systemName: isAlarmSet ? "bell.fill" : "bell")
                        .foregroundColor(isAlarmSet ? .yellow : .white.opacity(0.6))
                        .padding(8)
                        .background(isAlarmSet ? Color.yellow.opacity(0.2) : Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                if pass.isVisible {
                    Text("⭐ VISIBLE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
            
            HStack(spacing: 20) {
                // Satellite image/icon
                ZStack {
                    Circle()
                        .fill(Color.cyan.opacity(0.3))
                        .frame(width: 80, height: 80)
                    
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .font(.system(size: 40))
                        .foregroundColor(.cyan)
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(pass.satellite.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        Text(pass.riseTime, style: .time)
                            .font(.subheadline)
                            .foregroundColor(.cyan)
                        
                        Text("•")
                            .foregroundColor(.white.opacity(0.5))
                        
                        Text("\(Int(pass.duration / 60)) min")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Text(timeRemaining)
                        .font(.caption)
                        .foregroundColor(.yellow)
                        .onAppear {
                            updateTimeRemaining()
                        }
                }
                
                Spacer()
            }
            
            // Quick stats
            HStack(spacing: 20) {
                PassStat(icon: "arrow.up", value: "\(Int(pass.maxElevation))°", label: "Max Elevation")
                PassStat(icon: "safari", value: "\(Int(pass.riseAzimuth))°", label: "Start Azimuth")
                PassStat(icon: "star.fill", value: String(format: "%.1f", pass.magnitude), label: "Magnitude")
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.cyan.opacity(0.3), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.cyan, lineWidth: 1)
        )
    }
    
    func updateTimeRemaining() {
        let interval = pass.timeUntilRise
        
            if interval < 0 {
                timeRemaining = "PASSING NOW!"
            } else if interval < 3600 {
                timeRemaining = "in \(Int(interval / 60)) minutes"
            } else if interval < 86400 {
                let hours = Int(interval / 3600)
                timeRemaining = "in \(hours) hours"
            } else {
                let days = Int(interval / 86400)
                timeRemaining = "in \(days) days"
            }
    }
}

struct PassStat: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(.cyan)
            
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(label)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
    }
}

struct VisibleNowSection: View {
    let passes: [SatellitePass]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🔴 VISIBLE NOW")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.red)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(passes) { pass in
                        VisibleNowCard(pass: pass)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct VisibleNowCard: View {
    let pass: SatellitePass
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .overlay(
                        Circle()
                            .stroke(Color.red, lineWidth: 4)
                            .scaleEffect(1.5)
                            .opacity(0.5)
                    )
                
                Text(pass.satellite.name)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            Text("Elevation: \(Int(pass.maxElevation))°")
                .font(.subheadline)
                .foregroundColor(.cyan)
            
            Text("Azimuth: \(Int(pass.riseAzimuth))°")
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .padding()
        .frame(width: 180)
        .background(Color.red.opacity(0.2))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 1)
        )
    }
}

struct PassCard: View {
    let pass: SatellitePass
    @ObservedObject var predictionService = SatellitePassPrediction.shared
    
    var isAlarmSet: Bool {
        predictionService.setAlarms.contains(pass.id)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "antenna.radiowaves.left.and.right")
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(pass.satellite.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(pass.satellite.origin == .nasa ? "NASA" : "Roscosmos")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
                
                Spacer()
                
                // Alarm Toggle
                Button {
                    withAnimation {
                        predictionService.toggleAlarm(for: pass)
                    }
                } label: {
                    Image(systemName: isAlarmSet ? "bell.fill" : "bell")
                        .font(.system(size: 18))
                        .foregroundColor(isAlarmSet ? .yellow : .white.opacity(0.6))
                        .padding(8)
                        .background(isAlarmSet ? Color.yellow.opacity(0.2) : Color.clear)
                        .clipShape(Circle())
                        .overlay(
                            Circle()
                                .stroke(isAlarmSet ? Color.yellow : Color.white.opacity(0.2), lineWidth: 1)
                        )
                }
                
                if pass.isVisible {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.green)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(pass.riseTime, style: .time)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Max")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(Int(pass.maxElevation))°")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Duration")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(Int(pass.duration / 60)) min")
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
            
            Text(pass.visibilityDescription)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(pass.isVisible ? Color.green.opacity(0.3) : Color.white.opacity(0.1))
                .foregroundColor(pass.isVisible ? .green : .white.opacity(0.7))
                .cornerRadius(6)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

#Preview {
    SatellitePassView()
}
