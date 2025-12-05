//
//  SpaceMissionControl.swift
//  GalacticalMap
//
//  NASA/Roscosmos Seviyesi Görev Kontrol Merkezi
//  Gerçek zamanlı uzay operasyonları, telemetri, mission planning
//

import SwiftUI
import Combine
import CoreLocation

class SpaceMissionControl: ObservableObject {
    static let shared = SpaceMissionControl()
    
    @Published var activeMissions: [SpaceMission] = []
    @Published var telemetryData: [TelemetryStream] = []
    // @Published var orbitPropagation: OrbitPropagation?
    @Published var groundStationNetwork: [GroundStation] = []
    @Published var spaceWeather: SpaceWeather?
    @Published var solarActivity: SolarActivity?
    
    private var updateTimer: Timer?
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        initializeMissionControl()
        startTelemetryStreams()
        loadGroundStations()
    }
    
    // MARK: - Mission Control Initialization
    
    func initializeMissionControl() {
        // Aktif görevleri yükle
        activeMissions = [
            SpaceMission(
                id: "ISS_EXPEDITION_70",
                name: "ISS Expedition 70",
                agency: .nasa,
                launchDate: Date(timeIntervalSinceNow: -86400 * 180),
                status: .active,
                crew: 7,
                orbitAltitude: 408000, // meters
                orbitInclination: 51.6,
                missionType: .humanSpaceflight,
                objectives: [
                    "Long-duration human life research",
                    "Microgravity experiments",
                    "Earth observation",
                    "Spacewalks"
                ],
                nextEvent: MissionEvent(
                    name: "EVA-90 (Spacewalk)",
                    time: Date(timeIntervalSinceNow: 86400 * 3),
                    description: "Dış panel bakımı ve bilimsel ekipman kurulumu"
                )
            ),
            SpaceMission(
                id: "JWST_SCIENCE",
                name: "James Webb Deep Field",
                agency: .nasa,
                launchDate: Date(timeIntervalSinceNow: -86400 * 1200),
                status: .active,
                crew: 0,
                orbitAltitude: 1500000000, // L2 point
                orbitInclination: 0,
                missionType: .science,
                objectives: [
                    "Early universe observation",
                    "Exoplanet atmosphere analysis",
                    "Galaxy formation studies"
                ],
                nextEvent: MissionEvent(
                    name: "NGC 6302 Deep Observation",
                    time: Date(timeIntervalSinceNow: 86400 * 7),
                    description: "Planetary nebula detaylı spektroskopi"
                )
            ),
            SpaceMission(
                id: "ARTEMIS_II",
                name: "Artemis II",
                agency: .nasa,
                launchDate: Date(timeIntervalSinceNow: 86400 * 90),
                status: .planned,
                crew: 4,
                orbitAltitude: 384400000, // Moon distance
                orbitInclination: 28.5,
                missionType: .lunar,
                objectives: [
                    "Crewed lunar orbit mission",
                    "Orion capsule test",
                    "Lunar landing preparation"
                ],
                nextEvent: MissionEvent(
                    name: "Launch Window Opens",
                    time: Date(timeIntervalSinceNow: 86400 * 90),
                    description: "Kennedy Space Center LC-39B"
                )
            ),
            SpaceMission(
                id: "MARS_SAMPLE_RETURN",
                name: "Mars Sample Return",
                agency: .esa,
                launchDate: Date(timeIntervalSinceNow: 86400 * 365),
                status: .planned,
                crew: 0,
                orbitAltitude: 225000000000, // Mars distance
                orbitInclination: 0,
                missionType: .planetary,
                objectives: [
                    "Collect samples from Mars surface",
                    "Return samples to Earth",
                    "Analyze signs of life on Mars"
                ],
                nextEvent: MissionEvent(
                    name: "Launch Preparation",
                    time: Date(timeIntervalSinceNow: 86400 * 300),
                    description: "Spacecraft integration başlıyor"
                )
            ),
            SpaceMission(
                id: "ROSCOSMOS_LUNA_26",
                name: "Luna-26 Orbiter",
                agency: .roscosmos,
                launchDate: Date(timeIntervalSinceNow: 86400 * 180),
                status: .planned,
                crew: 0,
                orbitAltitude: 384400000,
                orbitInclination: 90,
                missionType: .lunar,
                objectives: [
                    "Map lunar surface",
                    "Resource exploration",
                    "Landing site selection"
                ],
                nextEvent: MissionEvent(
                    name: "Polar Orbit Insertion",
                    time: Date(timeIntervalSinceNow: 86400 * 185),
                    description: "100km kutup yörüngesi"
                )
            )
        ]
    }
    
    // MARK: - Telemetry Streams
    
    func startTelemetryStreams() {
        // ISS Telemetry
        let issTelemetry = TelemetryStream(
            missionId: "ISS_EXPEDITION_70",
            parameters: [
                TelemetryParameter(name: "Altitude", value: "408.2", unit: "km", status: .nominal),
                TelemetryParameter(name: "Velocity", value: "7.66", unit: "km/s", status: .nominal),
                TelemetryParameter(name: "Solar Array Output", value: "84", unit: "kW", status: .nominal),
                TelemetryParameter(name: "Internal Pressure", value: "101.3", unit: "kPa", status: .nominal),
                TelemetryParameter(name: "Temperature", value: "21.5", unit: "°C", status: .nominal),
                TelemetryParameter(name: "CO2 Level", value: "0.38", unit: "%", status: .nominal),
                TelemetryParameter(name: "O2 Level", value: "21.0", unit: "%", status: .nominal),
                TelemetryParameter(name: "Orbital Period", value: "92.68", unit: "min", status: .nominal)
            ],
            lastUpdate: Date(),
            dataRate: "256 kbps"
        )
        
        // JWST Telemetry
        let jwstTelemetry = TelemetryStream(
            missionId: "JWST_SCIENCE",
            parameters: [
                TelemetryParameter(name: "Primary Mirror Temp", value: "-233.15", unit: "°C", status: .nominal),
                TelemetryParameter(name: "Sunshield Layers", value: "5", unit: "deployed", status: .nominal),
                TelemetryParameter(name: "Pointing Accuracy", value: "0.001", unit: "arcsec", status: .nominal),
                TelemetryParameter(name: "Data Downlink", value: "28.8", unit: "Mbps", status: .nominal),
                TelemetryParameter(name: "Solar Array Power", value: "2.0", unit: "kW", status: .nominal),
                TelemetryParameter(name: "Propellant Remaining", value: "92", unit: "%", status: .nominal)
            ],
            lastUpdate: Date(),
            dataRate: "28.8 Mbps"
        )
        
        telemetryData = [issTelemetry, jwstTelemetry]
        
        // Real-time updates every 2 seconds
        updateTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            self?.updateTelemetry()
        }
    }
    
    func updateTelemetry() {
        for i in 0..<telemetryData.count {
            for j in 0..<telemetryData[i].parameters.count {
                // Simulate small variations
                if let currentValue = Double(telemetryData[i].parameters[j].value) {
                    let variation = Double.random(in: -0.02...0.02)
                    let newValue = currentValue * (1.0 + variation)
                    telemetryData[i].parameters[j].value = String(format: "%.2f", newValue)
                }
            }
            telemetryData[i].lastUpdate = Date()
        }
    }
    
    // MARK: - Ground Station Network
    
    func loadGroundStations() {
        groundStationNetwork = [
            GroundStation(
                id: "DSN_GOLDSTONE",
                name: "Goldstone Deep Space Network",
                location: CLLocationCoordinate2D(latitude: 35.4267, longitude: -116.8900),
                agency: .nasa,
                antennaSize: 70, // meters
                frequency: "X-band, Ka-band",
                status: .active,
                currentTarget: "Voyager 1",
                signalStrength: -145 // dBm
            ),
            GroundStation(
                id: "DSN_MADRID",
                name: "Madrid Deep Space Complex",
                location: CLLocationCoordinate2D(latitude: 40.4319, longitude: -4.2481),
                agency: .esa,
                antennaSize: 70,
                frequency: "S-band, X-band, Ka-band",
                status: .active,
                currentTarget: "Mars Express",
                signalStrength: -138
            ),
            GroundStation(
                id: "DSN_CANBERRA",
                name: "Canberra Deep Space Network",
                location: CLLocationCoordinate2D(latitude: -35.4014, longitude: 148.9819),
                agency: .nasa,
                antennaSize: 70,
                frequency: "X-band, Ka-band",
                status: .active,
                currentTarget: "JWST",
                signalStrength: -142
            ),
            GroundStation(
                id: "ROSCOSMOS_YEVPATORIA",
                name: "Yevpatoria RT-70",
                location: CLLocationCoordinate2D(latitude: 45.2, longitude: 33.1),
                agency: .roscosmos,
                antennaSize: 70,
                frequency: "S-band, X-band",
                status: .active,
                currentTarget: "Luna-25",
                signalStrength: -140
            ),
            GroundStation(
                id: "ESTRACK_KOUROU",
                name: "ESA Kourou Station",
                location: CLLocationCoordinate2D(latitude: 5.2514, longitude: -52.8044),
                agency: .esa,
                antennaSize: 15,
                frequency: "S-band",
                status: .active,
                currentTarget: "Sentinel-2",
                signalStrength: -125
            )
        ]
    }
    
    // MARK: - Space Weather & Solar Activity
    
    func updateSpaceWeather() {
        spaceWeather = SpaceWeather(
            solarWindSpeed: 450, // km/s
            solarWindDensity: 7.2, // particles/cm³
            interplanetaryMagneticField: 5.8, // nT
            kpIndex: 3.0, // Geomagnetic activity
            solarFluxIndex: 142, // Solar flux units
            geomagneticStorm: .moderate,
            radiationLevel: .elevated,
            forecast: "Moderate geomagnetic activity expected. Aurora probability increased at high latitudes."
        )
        
        solarActivity = SolarActivity(
            sunspotNumber: 85,
            solarFlares: [
                SolarFlare(class: .M, magnitude: 2.3, time: Date(timeIntervalSinceNow: -3600), region: "AR3483"),
                SolarFlare(class: .C, magnitude: 5.7, time: Date(timeIntervalSinceNow: -7200), region: "AR3481")
            ],
            coronalMassEjections: [
                CoronalMassEjection(
                    time: Date(timeIntervalSinceNow: -86400),
                    speed: 650, // km/s
                    direction: "Earth-directed",
                    earthArrival: Date(timeIntervalSinceNow: 86400 * 2)
                )
            ],
            solarCycle: SolarCycle(number: 25, peakDate: Date(timeIntervalSinceNow: 86400 * 365 * 2))
        )
    }
    
    // MARK: - Orbit Propagation (SGP4)
    
    func propagateOrbit(for satellite: Satellite, at date: Date) -> OrbitalElements {
        // SGP4 (Simplified General Perturbations) algorithm
        // Real implementation would use TLE data
        
        let timeFromEpoch = date.timeIntervalSince1970
        
        // Simplified Keplerian elements
        let semiMajorAxis = 6771000.0 // meters (ISS-like)
        let eccentricity = 0.0003
        let inclination = 51.6 * .pi / 180
        let raan = 45.0 * .pi / 180 // Right Ascension of Ascending Node
        let argOfPerigee = 30.0 * .pi / 180
        let meanAnomaly = (timeFromEpoch / 5558.0).truncatingRemainder(dividingBy: 2 * .pi)
        
        return OrbitalElements(
            semiMajorAxis: semiMajorAxis,
            eccentricity: eccentricity,
            inclination: inclination,
            raan: raan,
            argumentOfPerigee: argOfPerigee,
            meanAnomaly: meanAnomaly,
            epoch: date
        )
    }
}

// MARK: - Models

struct SpaceMission: Identifiable {
    let id: String
    let name: String
    let agency: SpaceAgency
    let launchDate: Date
    let status: MissionStatus
    let crew: Int
    let orbitAltitude: Double // meters
    let orbitInclination: Double // degrees
    let missionType: MissionType
    let objectives: [String]
    let nextEvent: MissionEvent?
    
    enum MissionStatus {
        case planned, active, completed, critical
    }
    
    enum MissionType {
        case humanSpaceflight, science, lunar, planetary, technology
    }
}

enum SpaceAgency {
    case nasa, roscosmos, esa, jaxa, cnsa, isro
    
    var name: String {
        switch self {
        case .nasa: return "NASA"
        case .roscosmos: return "Roscosmos"
        case .esa: return "ESA"
        case .jaxa: return "JAXA"
        case .cnsa: return "CNSA"
        case .isro: return "ISRO"
        }
    }
    
    var flag: String {
        switch self {
        case .nasa: return "🇺🇸"
        case .roscosmos: return "🇷🇺"
        case .esa: return "🇪🇺"
        case .jaxa: return "🇯🇵"
        case .cnsa: return "🇨🇳"
        case .isro: return "🇮🇳"
        }
    }
}

struct MissionEvent {
    let name: String
    let time: Date
    let description: String
}

struct TelemetryStream {
    let missionId: String
    var parameters: [TelemetryParameter]
    var lastUpdate: Date
    let dataRate: String
}

struct TelemetryParameter {
    let name: String
    var value: String
    let unit: String
    var status: ParameterStatus
    
    enum ParameterStatus {
        case nominal, warning, critical
        
        var color: String {
            switch self {
            case .nominal: return "#00FF00"
            case .warning: return "#FFFF00"
            case .critical: return "#FF0000"
            }
        }
    }
}

struct GroundStation: Identifiable {
    let id: String
    let name: String
    let location: CLLocationCoordinate2D
    let agency: SpaceAgency
    let antennaSize: Double // meters
    let frequency: String
    var status: StationStatus
    var currentTarget: String?
    var signalStrength: Int // dBm
    
    enum StationStatus {
        case active, maintenance, offline
    }
}

struct SpaceWeather {
    let solarWindSpeed: Double // km/s
    let solarWindDensity: Double // particles/cm³
    let interplanetaryMagneticField: Double // nT
    let kpIndex: Double // 0-9
    let solarFluxIndex: Int // SFU
    let geomagneticStorm: StormLevel
    let radiationLevel: RadiationLevel
    let forecast: String
    
    enum StormLevel {
        case none, minor, moderate, strong, severe, extreme
    }
    
    enum RadiationLevel {
        case normal, elevated, high, veryHigh, extreme
    }
}

struct SolarActivity {
    let sunspotNumber: Int
    let solarFlares: [SolarFlare]
    let coronalMassEjections: [CoronalMassEjection]
    let solarCycle: SolarCycle
}

struct SolarFlare {
    let `class`: FlareClass
    let magnitude: Double
    let time: Date
    let region: String
    
    enum FlareClass {
        case A, B, C, M, X
    }
}

struct CoronalMassEjection {
    let time: Date
    let speed: Double // km/s
    let direction: String
    let earthArrival: Date?
}

struct SolarCycle {
    let number: Int
    let peakDate: Date
}

struct OrbitalElements {
    let semiMajorAxis: Double
    let eccentricity: Double
    let inclination: Double
    let raan: Double
    let argumentOfPerigee: Double
    let meanAnomaly: Double
    let epoch: Date
}

// MARK: - Mission Control View

struct MissionControlView: View {
    @StateObject private var missionControl = SpaceMissionControl.shared
    @State private var selectedMission: SpaceMission?
    @State private var showTelemetry = true
    @State private var showGroundStations = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Matrix-style background
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Mission Control Header
                        MissionControlHeader()
                        
                        // Active Missions Overview
                        ActiveMissionsPanel(missions: missionControl.activeMissions)
                            .padding()
                        
                        // Telemetry Data
                        if showTelemetry {
                            TelemetryPanel(streams: missionControl.telemetryData)
                                .padding()
                        }
                        
                        // Ground Station Network
                        if showGroundStations {
                            GroundStationPanel(stations: missionControl.groundStationNetwork)
                                .padding()
                        }
                        
                        // Space Weather
                        SpaceWeatherPanel()
                            .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.green)
                        Text("MISSION CONTROL")
                            .font(.system(.headline, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            showTelemetry.toggle()
                        } label: {
                            Label("Telemetry", systemImage: showTelemetry ? "checkmark" : "")
                        }
                        
                        Button {
                            showGroundStations.toggle()
                        } label: {
                            Label("Ground Stations", systemImage: showGroundStations ? "checkmark" : "")
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.green)
                    }
                }
            }
        }
    }
}

struct MissionControlHeader: View {
    @State private var currentTime = Date()
    
    var body: some View {
        VStack(spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("MISSION ELAPSED TIME")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                    
                    Text(currentTime, style: .timer)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("SYSTEM STATUS")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                    
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color.green)
                            .frame(width: 8, height: 8)
                        Text("NOMINAL")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding()
            .background(Color.green.opacity(0.05))
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                currentTime = Date()
            }
        }
    }
}

struct ActiveMissionsPanel: View {
    let missions: [SpaceMission]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ACTIVE MISSIONS")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("\(missions.filter { $0.status == .active }.count) ONLINE")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.green.opacity(0.7))
            }
            
            ForEach(missions) { mission in
                MissionCard(mission: mission)
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct MissionCard: View {
    let mission: SpaceMission
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(mission.agency.flag)
                Text(mission.name)
                    .font(.system(size: 14, weight: .semibold, design: .monospaced))
                    .foregroundColor(.green)
                
                Spacer()
                
                StatusIndicator(status: mission.status)
            }
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 4) {
                GridRow {
                    Text("ALT:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                    Text("\(Int(mission.orbitAltitude / 1000)) km")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("INC:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                    Text(String(format: "%.1f°", mission.orbitInclination))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                }
                
                GridRow {
                    Text("CREW:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                    Text("\(mission.crew)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("TYPE:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                    Text(typeString(mission.missionType))
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
            
            if let nextEvent = mission.nextEvent {
                Divider()
                    .background(Color.green.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT EVENT:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green.opacity(0.7))
                    
                    Text(nextEvent.name)
                        .font(.system(size: 11, weight: .semibold, design: .monospaced))
                        .foregroundColor(.yellow)
                    
                    Text(nextEvent.time, style: .relative)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
        }
        .padding(12)
        .background(Color.black.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.green.opacity(0.5), lineWidth: 1)
        )
    }
    
    func typeString(_ type: SpaceMission.MissionType) -> String {
        switch type {
        case .humanSpaceflight: return "HUMAN"
        case .science: return "SCIENCE"
        case .lunar: return "LUNAR"
        case .planetary: return "PLANETARY"
        case .technology: return "TECH"
        }
    }
}

struct StatusIndicator: View {
    let status: SpaceMission.MissionStatus
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(statusColor)
                .frame(width: 6, height: 6)
            
            Text(statusText)
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(statusColor.opacity(0.2))
    }
    
    var statusColor: Color {
        switch status {
        case .active: return .green
        case .planned: return .blue
        case .completed: return .gray
        case .critical: return .red
        }
    }
    
    var statusText: String {
        switch status {
        case .active: return "ACTIVE"
        case .planned: return "PLANNED"
        case .completed: return "COMPLETE"
        case .critical: return "CRITICAL"
        }
    }
}

struct TelemetryPanel: View {
    let streams: [TelemetryStream]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("TELEMETRY DATA")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            ForEach(streams, id: \.missionId) { stream in
                TelemetryStreamView(stream: stream)
            }
        }
        .padding()
        .background(Color.cyan.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}

struct TelemetryStreamView: View {
    let stream: TelemetryStream
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(stream.missionId)
                    .font(.system(size: 12, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                Text("↓ \(stream.dataRate)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.7))
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(stream.parameters, id: \.name) { param in
                    TelemetryParameterView(parameter: param)
                }
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cyan.opacity(0.5), lineWidth: 1)
        )
    }
}

struct TelemetryParameterView: View {
    let parameter: TelemetryParameter
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(parameter.name)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.cyan.opacity(0.7))
                
                HStack(spacing: 4) {
                    Text(parameter.value)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(Color(hex: parameter.status.color))
                    
                    Text(parameter.unit)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.7))
                }
            }
            
            Spacer()
        }
        .padding(6)
        .background(Color.black.opacity(0.3))
    }
}

struct GroundStationPanel: View {
    let stations: [GroundStation]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("GROUND STATION NETWORK")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
            
            ForEach(stations) { station in
                GroundStationView(station: station)
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
}

struct GroundStationView: View {
    let station: GroundStation
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(station.name)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundColor(.orange)
                
                if let target = station.currentTarget {
                    Text("→ \(target)")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.yellow)
                }
                
                Text("\(Int(station.antennaSize))m • \(station.frequency)")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.orange.opacity(0.7))
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Circle()
                    .fill(station.status == .active ? Color.green : Color.gray)
                    .frame(width: 8, height: 8)
                
                Text("\(station.signalStrength) dBm")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.orange.opacity(0.7))
            }
        }
        .padding(10)
        .background(Color.black.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
}

struct SpaceWeatherPanel: View {
    @StateObject private var missionControl = SpaceMissionControl.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("SPACE WEATHER")
                .font(.system(size: 14, weight: .bold, design: .monospaced))
                .foregroundColor(.yellow)
            
            if let weather = missionControl.spaceWeather {
                VStack(spacing: 8) {
                    Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                        GridRow {
                            Text("SOLAR WIND:")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.yellow.opacity(0.7))
                            Text("\(Int(weather.solarWindSpeed)) km/s")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.yellow)
                        }
                        
                        GridRow {
                            Text("KP INDEX:")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.yellow.opacity(0.7))
                            Text(String(format: "%.1f", weather.kpIndex))
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(weather.kpIndex > 5 ? .red : .yellow)
                        }
                        
                        GridRow {
                            Text("RADIATION:")
                                .font(.system(size: 10, design: .monospaced))
                                .foregroundColor(.yellow.opacity(0.7))
                            Text("ELEVATED")
                                .font(.system(size: 11, weight: .bold, design: .monospaced))
                                .foregroundColor(.orange)
                        }
                    }
                    
                    Text(weather.forecast)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.yellow.opacity(0.8))
                        .padding(8)
                        .background(Color.black.opacity(0.3))
                }
            }
        }
        .padding()
        .background(Color.yellow.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.yellow.opacity(0.3), lineWidth: 1)
        )
        .onAppear {
            missionControl.updateSpaceWeather()
        }
    }
}

#Preview {
    MissionControlView()
}
