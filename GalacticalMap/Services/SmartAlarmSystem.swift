//
//  SmartAlarmSystem.swift
//  GalacticalMap
//
//  Akıllı Alarm Sistemi
//  Uydu geçişleri, yeni anomaliler, özel olaylar için özelleştirilebilir alarmlar
//

import Foundation
import UserNotifications
import SwiftUI
import AVFoundation
import Combine
import CoreLocation

class SmartAlarmSystem: NSObject, ObservableObject {
    static let shared = SmartAlarmSystem()
    
    @Published var alarms: [SmartAlarm] = []
    @Published var triggeredAlarms: [TriggeredAlarm] = []
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var soundPlayer: AVAudioPlayer?
    
    override init() {
        super.init()
        setupNotificationCategories()
        loadAlarms()
    }
    
    // MARK: - Setup
    
    func setupNotificationCategories() {
        // Satellite Pass Actions
        let viewAction = UNNotificationAction(
            identifier: "VIEW_SATELLITE",
            title: "Göster",
            options: [.foreground]
        )
        
        let trackAction = UNNotificationAction(
            identifier: "TRACK_SATELLITE",
            title: "Takip Et",
            options: [.foreground]
        )
        
        let satelliteCategory = UNNotificationCategory(
            identifier: "SATELLITE_ALARM",
            actions: [viewAction, trackAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Anomaly Detection Actions
        let viewAnomalyAction = UNNotificationAction(
            identifier: "VIEW_ANOMALY",
            title: "İncele",
            options: [.foreground]
        )
        
        let saveAnomalyAction = UNNotificationAction(
            identifier: "SAVE_ANOMALY",
            title: "Kaydet",
            options: []
        )
        
        let anomalyCategory = UNNotificationCategory(
            identifier: "ANOMALY_ALARM",
            actions: [viewAnomalyAction, saveAnomalyAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Celestial Event Actions
        let remindLaterAction = UNNotificationAction(
            identifier: "REMIND_LATER",
            title: "10 dk sonra hatırlat",
            options: []
        )
        
        let eventCategory = UNNotificationCategory(
            identifier: "EVENT_ALARM",
            actions: [viewAction, remindLaterAction],
            intentIdentifiers: [],
            options: []
        )
        
        notificationCenter.setNotificationCategories([
            satelliteCategory,
            anomalyCategory,
            eventCategory
        ])
    }
    
    // MARK: - Alarm Management
    
    func createAlarm(_ alarm: SmartAlarm) {
        alarms.append(alarm)
        saveAlarms()
        
        if alarm.isEnabled {
            scheduleAlarm(alarm)
        }
    }
    
    func updateAlarm(_ alarm: SmartAlarm) {
        if let index = alarms.firstIndex(where: { $0.id == alarm.id }) {
            alarms[index] = alarm
            saveAlarms()
            
            // Re-schedule
            cancelAlarm(alarm)
            if alarm.isEnabled {
                scheduleAlarm(alarm)
            }
        }
    }
    
    func deleteAlarm(_ alarm: SmartAlarm) {
        cancelAlarm(alarm)
        alarms.removeAll { $0.id == alarm.id }
        saveAlarms()
    }
    
    func toggleAlarm(_ alarmId: UUID) {
        if let index = alarms.firstIndex(where: { $0.id == alarmId }) {
            alarms[index].isEnabled.toggle()
            
            if alarms[index].isEnabled {
                scheduleAlarm(alarms[index])
            } else {
                cancelAlarm(alarms[index])
            }
            
            saveAlarms()
        }
    }
    
    // MARK: - Scheduling
    
    func scheduleAlarm(_ alarm: SmartAlarm) {
        switch alarm.type {
        case .satellitePass(let satelliteId, let minElevation):
            scheduleSatellitePassAlarm(alarm, satelliteId: satelliteId, minElevation: minElevation)
            
        case .anomalyDetection(let anomalyTypes):
            scheduleAnomalyDetectionAlarm(alarm, types: anomalyTypes)
            
        case .celestialEvent(let eventType):
            scheduleCelestialEventAlarm(alarm, eventType: eventType)
            
        case .custom(let conditions):
            scheduleCustomAlarm(alarm, conditions: conditions)
        }
    }
    
    func scheduleSatellitePassAlarm(_ alarm: SmartAlarm, satelliteId: String?, minElevation: Double) {
        // Get upcoming satellite passes
        let passes = SatellitePassPrediction.shared.upcomingPasses
        
        let relevantPasses: [SatellitePass]
        if let satId = satelliteId {
            relevantPasses = passes.filter { String($0.satellite.id) == satId && $0.maxElevation >= minElevation }
        } else {
            relevantPasses = passes.filter { $0.maxElevation >= minElevation }
        }
        
        // Schedule notifications for each pass
        for pass in relevantPasses.prefix(10) {
            let content = UNMutableNotificationContent()
            content.title = alarm.title
            content.body = "🛰️ \(pass.satellite.name) - \(Int(pass.maxElevation))° yüksekliğe ulaşacak"
            content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.soundName))
            content.categoryIdentifier = "SATELLITE_ALARM"
            content.userInfo = [
                "alarmId": alarm.id.uuidString,
                "satelliteId": pass.satellite.id,
                "passTime": pass.riseTime.timeIntervalSince1970
            ]
            
            let triggerDate = pass.riseTime.addingTimeInterval(TimeInterval(-alarm.minutesBefore * 60))
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "alarm_\(alarm.id)_\(pass.satellite.id)_\(pass.riseTime.timeIntervalSince1970)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request)
        }
    }
    
    func scheduleAnomalyDetectionAlarm(_ alarm: SmartAlarm, types: [AnomalyType]) {
        // Monitor for new anomaly detections
        // This would integrate with real-time sky monitoring
        
        // For demo, schedule a test notification
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = "🌌 Yeni gökyüzü anomalisi tespit edildi!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.soundName))
        content.categoryIdentifier = "ANOMALY_ALARM"
        
        // Test: trigger in 1 minute for demo
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 60, repeats: false)
        let request = UNNotificationRequest(
            identifier: "alarm_anomaly_\(alarm.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func scheduleCelestialEventAlarm(_ alarm: SmartAlarm, eventType: CelestialEventType) {
        // Schedule for known celestial events
        let upcomingEvents = getUpcomingEvents(type: eventType)
        
        for event in upcomingEvents.prefix(5) {
            let content = UNMutableNotificationContent()
            content.title = alarm.title
            content.body = "⭐ \(event.name) - \(event.description)"
            content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.soundName))
            content.categoryIdentifier = "EVENT_ALARM"
            
            let triggerDate = event.time.addingTimeInterval(TimeInterval(-alarm.minutesBefore * 60))
            let components = Calendar.current.dateComponents(
                [.year, .month, .day, .hour, .minute],
                from: triggerDate
            )
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
            let request = UNNotificationRequest(
                identifier: "alarm_event_\(alarm.id)_\(event.id)",
                content: content,
                trigger: trigger
            )
            
            notificationCenter.add(request)
        }
    }
    
    func scheduleCustomAlarm(_ alarm: SmartAlarm, conditions: [AlarmCondition]) {
        // Custom condition-based alarms
        // Monitor conditions and trigger when met
        
        for condition in conditions {
            switch condition {
            case .timeOfDay(let hour, let minute):
                scheduleTimeBasedAlarm(alarm, hour: hour, minute: minute)
                
            case .location(let latitude, let longitude, let radius):
                scheduleLocationBasedAlarm(alarm, lat: latitude, lon: longitude, radius: radius)
                
            case .weatherCondition(let condition):
                scheduleWeatherBasedAlarm(alarm, condition: condition)
                
            case .moonPhase(let phase):
                scheduleMoonPhaseAlarm(alarm, phase: phase)
            }
        }
    }
    
    func scheduleTimeBasedAlarm(_ alarm: SmartAlarm, hour: Int, minute: Int) {
        var components = DateComponents()
        components.hour = hour
        components.minute = minute
        
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = alarm.message
        content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.soundName))
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        let request = UNNotificationRequest(
            identifier: "alarm_time_\(alarm.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func scheduleLocationBasedAlarm(_ alarm: SmartAlarm, lat: Double, lon: Double, radius: Double) {
        // Location-based trigger
        let center = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        let region = CLCircularRegion(center: center, radius: radius, identifier: alarm.id.uuidString)
        region.notifyOnEntry = true
        
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = "Belirlediğiniz konuma ulaştınız - Gökyüzünü gözlemleyin!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.soundName))
        
        let trigger = UNLocationNotificationTrigger(region: region, repeats: false)
        let request = UNNotificationRequest(
            identifier: "alarm_location_\(alarm.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func scheduleWeatherBasedAlarm(_ alarm: SmartAlarm, condition: String) {
        // Weather-based triggers
        // Would integrate with weather API
    }
    
    func scheduleMoonPhaseAlarm(_ alarm: SmartAlarm, phase: String) {
        // Calculate next occurrence of moon phase
        let nextPhaseDate = calculateNextMoonPhase(phase)
        
        let content = UNMutableNotificationContent()
        content.title = alarm.title
        content.body = "🌙 \(phase) - Gözlem için ideal zaman!"
        content.sound = UNNotificationSound(named: UNNotificationSoundName(alarm.soundName))
        
        let components = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: nextPhaseDate
        )
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(
            identifier: "alarm_moon_\(alarm.id)",
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request)
    }
    
    func cancelAlarm(_ alarm: SmartAlarm) {
        // Remove all notifications for this alarm
        notificationCenter.getPendingNotificationRequests { requests in
            let idsToRemove = requests
                .filter { $0.identifier.contains(alarm.id.uuidString) }
                .map { $0.identifier }
            
            self.notificationCenter.removePendingNotificationRequests(withIdentifiers: idsToRemove)
        }
    }
    
    // MARK: - Helpers
    
    func getUpcomingEvents(type: CelestialEventType) -> [CelestialEvent] {
        // Return upcoming celestial events
        var events: [CelestialEvent] = []
        
        switch type {
        case .meteorShower:
            events.append(CelestialEvent(
                id: "perseids_2025",
                name: "Perseid Meteor Yağmuru",
                description: "Yılın en parlak meteor yağmuru",
                time: Date().addingTimeInterval(86400 * 7),
                type: .meteorShower
            ))
            
        case .eclipse:
            events.append(CelestialEvent(
                id: "lunar_eclipse_2025",
                name: "Kısmi Ay Tutulması",
                description: "Görülebilir kısmi ay tutulması",
                time: Date().addingTimeInterval(86400 * 30),
                type: .eclipse
            ))
            
        case .planetaryConjunction:
            events.append(CelestialEvent(
                id: "venus_jupiter_2025",
                name: "Venüs-Jüpiter Kavuşumu",
                description: "İki gezegen yakın görünecek",
                time: Date().addingTimeInterval(86400 * 14),
                type: .planetaryConjunction
            ))
            
        case .cometVisibility:
            break
            
        case .all:
            events = getUpcomingEvents(type: .meteorShower) +
                    getUpcomingEvents(type: .eclipse) +
                    getUpcomingEvents(type: .planetaryConjunction)
        }
        
        return events.sorted { $0.time < $1.time }
    }
    
    func calculateNextMoonPhase(_ phase: String) -> Date {
        // Simplified moon phase calculation
        // Real implementation would use astronomical algorithms
        return Date().addingTimeInterval(86400 * 7)
    }
    
    // MARK: - Persistence
    
    func saveAlarms() {
        if let encoded = try? JSONEncoder().encode(alarms) {
            UserDefaults.standard.set(encoded, forKey: "smart_alarms")
        }
    }
    
    func loadAlarms() {
        if let data = UserDefaults.standard.data(forKey: "smart_alarms"),
           let decoded = try? JSONDecoder().decode([SmartAlarm].self, from: data) {
            alarms = decoded
        } else {
            // Create default alarms
            createDefaultAlarms()
        }
    }
    
    func createDefaultAlarms() {
        let issAlarm = SmartAlarm(
            title: "ISS Geçişi",
            message: "Uluslararası Uzay İstasyonu yakında görünecek",
            type: .satellitePass(satelliteId: "iss", minElevation: 30),
            isEnabled: true,
            minutesBefore: 10,
            soundName: "satellite_alert.wav",
            vibrate: true,
            repeat: true
        )
        
        let anomalyAlarm = SmartAlarm(
            title: "Yeni Anomali",
            message: "Gökyüzünde yeni anomali tespit edildi",
            type: .anomalyDetection(anomalyTypes: [.nebula, .galaxy, .blackHole]),
            isEnabled: false,
            minutesBefore: 0,
            soundName: "anomaly_detected.wav",
            vibrate: true,
            repeat: false
        )
        
        let meteorAlarm = SmartAlarm(
            title: "Meteor Yağmuru",
            message: "Meteor yağmuru başlıyor",
            type: .celestialEvent(eventType: .meteorShower),
            isEnabled: true,
            minutesBefore: 30,
            soundName: "celestial_event.wav",
            vibrate: true,
            repeat: false
        )
        
        alarms = [issAlarm, anomalyAlarm, meteorAlarm]
        saveAlarms()
    }
}

// MARK: - Models

struct SmartAlarm: Identifiable, Codable {
    let id: UUID
    var title: String
    var message: String
    var type: AlarmType
    var isEnabled: Bool
    var minutesBefore: Int
    var soundName: String
    var vibrate: Bool
    var `repeat`: Bool
    var createdDate: Date
    
    init(id: UUID = UUID(),
         title: String,
         message: String,
         type: AlarmType,
         isEnabled: Bool,
         minutesBefore: Int,
         soundName: String,
         vibrate: Bool,
         repeat: Bool) {
        self.id = id
        self.title = title
        self.message = message
        self.type = type
        self.isEnabled = isEnabled
        self.minutesBefore = minutesBefore
        self.soundName = soundName
        self.vibrate = vibrate
        self.repeat = `repeat`
        self.createdDate = Date()
    }
}

enum AlarmType: Codable, Hashable {
    case satellitePass(satelliteId: String?, minElevation: Double)
    case anomalyDetection(anomalyTypes: [AnomalyType])
    case celestialEvent(eventType: CelestialEventType)
    case custom(conditions: [AlarmCondition])
}

enum AlarmCondition: Codable, Hashable {
    case timeOfDay(hour: Int, minute: Int)
    case location(latitude: Double, longitude: Double, radius: Double)
    case weatherCondition(String)
    case moonPhase(String)
}

enum CelestialEventType: String, Codable, CaseIterable {
    case meteorShower = "Meteor Yağmuru"
    case eclipse = "Tutulma"
    case planetaryConjunction = "Gezegen Kavuşumu"
    case cometVisibility = "Kuyruklu Yıldız"
    case all = "Tümü"
}

struct CelestialEvent: Identifiable {
    let id: String
    let name: String
    let description: String
    let time: Date
    let type: CelestialEventType
}

struct TriggeredAlarm: Identifiable {
    let id = UUID()
    let alarm: SmartAlarm
    let triggerTime: Date
    let acknowledged: Bool
}

// MARK: - Alarm Management View

struct AlarmManagementView: View {
    @StateObject private var alarmSystem = SmartAlarmSystem.shared
    @State private var showingAddAlarm = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        // Quick stats
                        HStack(spacing: 20) {
                            StatCard(
                                title: "Aktif",
                                value: "\(alarmSystem.alarms.filter { $0.isEnabled }.count)",
                                icon: "bell.fill",
                                color: .green
                            )
                            
                            StatCard(
                                title: "Toplam",
                                value: "\(alarmSystem.alarms.count)",
                                icon: "alarm.fill",
                                color: .cyan
                            )
                        }
                        .padding(.horizontal)
                        
                        // Alarm list
                        ForEach(alarmSystem.alarms) { alarm in
                            AlarmCard(alarm: alarm)
                                .padding(.horizontal)
                        }
                        
                        if alarmSystem.alarms.isEmpty {
                            EmptyAlarmsView()
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Alarmlar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingAddAlarm = true
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundColor(.cyan)
                            .font(.title2)
                    }
                }
            }
            .sheet(isPresented: $showingAddAlarm) {
                AddAlarmView()
            }
        }
    }
}

struct AlarmCard: View {
    let alarm: SmartAlarm
    @StateObject private var alarmSystem = SmartAlarmSystem.shared
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(alarm.isEnabled ? Color.green.opacity(0.3) : Color.gray.opacity(0.3))
                    .frame(width: 60, height: 60)
                
                Image(systemName: iconForType(alarm.type))
                    .font(.title2)
                    .foregroundColor(alarm.isEnabled ? .green : .gray)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(alarm.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(alarm.message)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)
                
                if alarm.minutesBefore > 0 {
                    Text("\(alarm.minutesBefore) dakika önce")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
            }
            
            Spacer()
            
            Toggle("", isOn: Binding(
                get: { alarm.isEnabled },
                set: { _ in alarmSystem.toggleAlarm(alarm.id) }
            ))
            .tint(.green)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    func iconForType(_ type: AlarmType) -> String {
        switch type {
        case .satellitePass:
            return "antenna.radiowaves.left.and.right"
        case .anomalyDetection:
            return "sparkles"
        case .celestialEvent:
            return "star.fill"
        case .custom:
            return "slider.horizontal.3"
        }
    }
}

struct EmptyAlarmsView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "alarm.fill")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("Henüz Alarm Yok")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Uydu geçişleri ve özel olaylar için alarm oluşturun")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

struct AddAlarmView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var alarmSystem = SmartAlarmSystem.shared
    
    @State private var title = ""
    @State private var message = ""
    @State private var selectedType = 0
    @State private var minutesBefore = 10
    @State private var vibrate = true
    @State private var repeatAlarm = false
    
    let alarmTypes = ["Uydu Geçişi", "Anomali Tespiti", "Gök Olayı", "Özel"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Alarm Bilgileri") {
                    TextField("Başlık", text: $title)
                    TextField("Mesaj", text: $message)
                }
                
                Section("Alarm Tipi") {
                    Picker("Tip", selection: $selectedType) {
                        ForEach(0..<alarmTypes.count, id: \.self) { index in
                            Text(alarmTypes[index]).tag(index)
                        }
                    }
                }
                
                Section("Ayarlar") {
                    Stepper("Önceden: \(minutesBefore) dk", value: $minutesBefore, in: 0...60, step: 5)
                    Toggle("Titreşim", isOn: $vibrate)
                    Toggle("Tekrarla", isOn: $repeatAlarm)
                }
            }
            .navigationTitle("Yeni Alarm")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        createAlarm()
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    func createAlarm() {
        let type: AlarmType
        
        switch selectedType {
        case 0:
            type = .satellitePass(satelliteId: nil, minElevation: 30)
        case 1:
            type = .anomalyDetection(anomalyTypes: [.nebula, .galaxy])
        case 2:
            type = .celestialEvent(eventType: .all)
        default:
            type = .custom(conditions: [])
        }
        
        let alarm = SmartAlarm(
            title: title,
            message: message,
            type: type,
            isEnabled: true,
            minutesBefore: minutesBefore,
            soundName: "default.wav",
            vibrate: vibrate,
            repeat: repeatAlarm
        )
        
        alarmSystem.createAlarm(alarm)
    }
}

#Preview {
    AlarmManagementView()
}
