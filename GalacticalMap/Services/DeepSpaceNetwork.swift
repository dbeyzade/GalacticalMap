//
//  DeepSpaceNetwork.swift
//  GalacticalMap
//
//  NASA Deep Space Network Emulation
//  Real-time signal tracking, telemetry protocols, antenna scheduling
//

import SwiftUI
import Combine
import CoreLocation

class DeepSpaceNetwork: ObservableObject {
    static let shared = DeepSpaceNetwork()
    
    @Published var antennas: [DSNAntenna] = []
    @Published var activeLinks: [CommunicationLink] = []
    @Published var signalMetrics: SignalMetrics?
    @Published var telemetryPackets: [TelemetryPacket] = []
    @Published var schedule: [AntennaSchedule] = []
    
    private var updateTimer: Timer?
    
    init() {
        setupDSNAntennas()
        startMonitoring()
    }
    
    // MARK: - DSN Antenna Setup
    
    func setupDSNAntennas() {
        antennas = [
            // Goldstone Complex (California)
            DSNAntenna(
                id: "DSS-14",
                name: "DSS-14 (Mars)",
                location: CLLocationCoordinate2D(latitude: 35.4267, longitude: -116.89),
                complex: .goldstone,
                aperture: 70.0,
                frequency: .xBand,
                status: .tracking,
                elevation: 45.2,
                azimuth: 183.5,
                target: "Mars Perseverance Rover",
                signalStrength: -154.3,
                dataRate: 2.1 // Mbps
            ),
            DSNAntenna(
                id: "DSS-25",
                name: "DSS-25 (Voyager 1)",
                location: CLLocationCoordinate2D(latitude: 35.4267, longitude: -116.89),
                complex: .goldstone,
                aperture: 34.0,
                frequency: .sBand,
                status: .tracking,
                elevation: 12.8,
                azimuth: 210.3,
                target: "Voyager 1",
                signalStrength: -192.5,
                dataRate: 0.00016 // 160 bps
            ),
            
            // Madrid Complex (Spain)
            DSNAntenna(
                id: "DSS-63",
                name: "DSS-63 (JWST)",
                location: CLLocationCoordinate2D(latitude: 40.4313, longitude: -4.2481),
                complex: .madrid,
                aperture: 70.0,
                frequency: .kaaBand,
                status: .tracking,
                elevation: 67.4,
                azimuth: 95.2,
                target: "James Webb Space Telescope",
                signalStrength: -168.7,
                dataRate: 28.5
            ),
            DSNAntenna(
                id: "DSS-55",
                name: "DSS-55 (Europa Clipper)",
                location: CLLocationCoordinate2D(latitude: 40.4313, longitude: -4.2481),
                complex: .madrid,
                aperture: 34.0,
                frequency: .xBand,
                status: .acquiring,
                elevation: 23.1,
                azimuth: 142.8,
                target: "Europa Clipper",
                signalStrength: -178.2,
                dataRate: 0.0
            ),
            
            // Canberra Complex (Australia)
            DSNAntenna(
                id: "DSS-43",
                name: "DSS-43 (Voyager 2)",
                location: CLLocationCoordinate2D(latitude: -35.4014, longitude: 148.9819),
                complex: .canberra,
                aperture: 70.0,
                frequency: .saBand,
                status: .tracking,
                elevation: 8.5,
                azimuth: 315.7,
                target: "Voyager 2",
                signalStrength: -194.8,
                dataRate: 0.00016
            ),
            DSNAntenna(
                id: "DSS-36",
                name: "DSS-36 (Parker Solar Probe)",
                location: CLLocationCoordinate2D(latitude: -35.4014, longitude: 148.9819),
                complex: .canberra,
                aperture: 34.0,
                frequency: .xBand,
                status: .tracking,
                elevation: 51.3,
                azimuth: 78.9,
                target: "Parker Solar Probe",
                signalStrength: -162.1,
                dataRate: 5.8
            )
        ]
    }
    
    // MARK: - Real-time Monitoring
    
    func startMonitoring() {
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateAntennaTracking()
            self?.simulateTelemetry()
            self?.updateSignalMetrics()
        }
    }
    
    func updateAntennaTracking() {
        for i in 0..<antennas.count {
            // Simulate antenna movement
            if antennas[i].status == .tracking {
                antennas[i].elevation += Double.random(in: -0.1...0.1)
                antennas[i].azimuth += Double.random(in: -0.2...0.2)
                
                // Signal strength fluctuation
                antennas[i].signalStrength += Double.random(in: -0.5...0.5)
                
                // Data rate variation
                let variation = Double.random(in: 0.95...1.05)
                antennas[i].dataRate *= variation
            }
        }
    }
    
    func simulateTelemetry() {
        // Generate telemetry packets
        guard let activeAntenna = antennas.first(where: { $0.status == .tracking }) else { return }
        
        if Double.random(in: 0...1) > 0.7 { // 30% chance per second
            let packet = TelemetryPacket(
                source: activeAntenna.target ?? "Unknown",
                timestamp: Date(),
                type: TelemetryType.allCases.randomElement() ?? .engineering,
                data: generateTelemetryData(),
                rssi: activeAntenna.signalStrength,
                snr: calculateSNR(rssi: activeAntenna.signalStrength)
            )
            
            telemetryPackets.insert(packet, at: 0)
            
            // Keep only last 50 packets
            if telemetryPackets.count > 50 {
                telemetryPackets.removeLast()
            }
        }
    }
    
    func generateTelemetryData() -> [String: String] {
        [
            "Voltage": String(format: "%.2f V", Double.random(in: 28...32)),
            "Current": String(format: "%.3f A", Double.random(in: 5...15)),
            "Temperature": String(format: "%.1f °C", Double.random(in: -50...50)),
            "Pressure": String(format: "%.4f Pa", Double.random(in: 0...1)),
            "Battery": String(format: "%.1f %%", Double.random(in: 80...100))
        ]
    }
    
    func calculateSNR(rssi: Double) -> Double {
        // Signal-to-Noise Ratio calculation
        let noiseFloor = -180.0 // dBm
        return rssi - noiseFloor
    }
    
    func updateSignalMetrics() {
        let trackingAntennas = antennas.filter { $0.status == .tracking }
        
        guard !trackingAntennas.isEmpty else { return }
        
        let avgSignal = trackingAntennas.map { $0.signalStrength }.reduce(0, +) / Double(trackingAntennas.count)
        let totalDataRate = trackingAntennas.map { $0.dataRate }.reduce(0, +)
        
        signalMetrics = SignalMetrics(
            averageSignalStrength: avgSignal,
            totalDataRate: totalDataRate,
            activeLinks: trackingAntennas.count,
            packetLoss: Double.random(in: 0...0.5),
            latency: calculateLatency()
        )
    }
    
    func calculateLatency() -> TimeInterval {
        // Light speed distance calculation
        // Simplified - would use actual spacecraft distance
        let distances: [String: Double] = [
            "ISS": 408000, // 408 km
            "Moon": 384400000, // 384,400 km
            "Mars": 225000000000, // 225 million km
            "Voyager 1": 24000000000000 // 24 billion km
        ]
        
        let speedOfLight = 299792.458 // km/s
        
        guard let target = antennas.first(where: { $0.status == .tracking })?.target,
              let distance = distances[target] else {
            return 1.3 // Default to lunar distance
        }
        
        return (distance / speedOfLight) * 2 // Round trip
    }
    
    // MARK: - Communication Protocols
    
    func decodeCCSDS(rawData: Data) -> CCSDSPacket? {
        // CCSDS (Consultative Committee for Space Data Systems) protocol
        guard rawData.count >= 6 else { return nil }
        
        // Primary header parsing (simplified)
        let versionNumber = (rawData[0] >> 5) & 0x07
        let type = (rawData[0] >> 4) & 0x01
        let secondaryHeaderFlag = (rawData[0] >> 3) & 0x01
        let apid = UInt16(rawData[0] & 0x07) << 8 | UInt16(rawData[1])
        
        return CCSDSPacket(
            versionNumber: versionNumber,
            packetType: type == 0 ? .telemetry : .command,
            hasSecondaryHeader: secondaryHeaderFlag == 1,
            applicationProcessID: apid,
            sequenceCount: 0,
            packetLength: rawData.count
        )
    }
}

// MARK: - Models

struct DSNAntenna: Identifiable {
    let id: String
    var name: String
    var location: CLLocationCoordinate2D
    var complex: DSNComplex
    var aperture: Double // meters
    var frequency: FrequencyBand
    var status: AntennaStatus
    var elevation: Double // degrees
    var azimuth: Double // degrees
    var target: String?
    var signalStrength: Double // dBm
    var dataRate: Double // Mbps
}

enum DSNComplex {
    case goldstone, madrid, canberra
    
    var name: String {
        switch self {
        case .goldstone: return "Goldstone (GDSCC)"
        case .madrid: return "Madrid (MDSCC)"
        case .canberra: return "Canberra (CDSCC)"
        }
    }
    
    var flag: String {
        switch self {
        case .goldstone: return "🇺🇸"
        case .madrid: return "🇪🇸"
        case .canberra: return "🇦🇺"
        }
    }
}

enum FrequencyBand {
    case saBand, sBand, xBand, kaaBand, kaBand
    
    var name: String {
        switch self {
        case .saBand: return "S/A-Band"
        case .sBand: return "S-Band"
        case .xBand: return "X-Band"
        case .kaaBand: return "Ka/A-Band"
        case .kaBand: return "Ka-Band"
        }
    }
    
    var frequency: String {
        switch self {
        case .saBand: return "2.0-2.3 GHz"
        case .sBand: return "2.2-2.3 GHz"
        case .xBand: return "8.4 GHz"
        case .kaaBand: return "32 GHz"
        case .kaBand: return "32-34 GHz"
        }
    }
}

enum AntennaStatus {
    case idle, acquiring, tracking, commanding, fault
    
    var name: String {
        switch self {
        case .idle: return "idle"
        case .acquiring: return "acquiring"
        case .tracking: return "tracking"
        case .commanding: return "commanding"
        case .fault: return "fault"
        }
    }
    
    var color: Color {
        switch self {
        case .idle: return .gray
        case .acquiring: return .yellow
        case .tracking: return .green
        case .commanding: return .blue
        case .fault: return .red
        }
    }
    
    var icon: String {
        switch self {
        case .idle: return "antenna.radiowaves.left.and.right.slash"
        case .acquiring: return "dot.radiowaves.left.and.right"
        case .tracking: return "antenna.radiowaves.left.and.right"
        case .commanding: return "arrow.up.arrow.down"
        case .fault: return "exclamationmark.triangle"
        }
    }
}

struct CommunicationLink: Identifiable {
    let id = UUID()
    let antenna: String
    let spacecraft: String
    let frequency: FrequencyBand
    let uplink: Bool
    let downlink: Bool
    var signalStrength: Double
    var dataRate: Double
}

struct SignalMetrics {
    var averageSignalStrength: Double
    var totalDataRate: Double
    var activeLinks: Int
    var packetLoss: Double
    var latency: TimeInterval
}

struct TelemetryPacket: Identifiable {
    let id = UUID()
    let source: String
    let timestamp: Date
    let type: TelemetryType
    let data: [String: String]
    let rssi: Double
    let snr: Double
}

enum TelemetryType: String, CaseIterable {
    case engineering = "ENG"
    case science = "SCI"
    case housekeeping = "HK"
    case navigation = "NAV"
    case command = "CMD"
    
    var color: Color {
        switch self {
        case .engineering: return .cyan
        case .science: return .purple
        case .housekeeping: return .green
        case .navigation: return .orange
        case .command: return .red
        }
    }
}

struct AntennaSchedule: Identifiable {
    let id = UUID()
    let antenna: String
    let spacecraft: String
    let startTime: Date
    let endTime: Date
    let activity: ScheduledActivity
}

enum ScheduledActivity {
    case track, command, calibration, maintenance
}

struct CCSDSPacket {
    let versionNumber: UInt8
    let packetType: PacketType
    let hasSecondaryHeader: Bool
    let applicationProcessID: UInt16
    let sequenceCount: UInt16
    let packetLength: Int
    
    enum PacketType {
        case telemetry, command
    }
}

// MARK: - Deep Space Network View

struct DeepSpaceNetworkView: View {
    @StateObject private var dsn = DeepSpaceNetwork.shared
    @State private var selectedAntenna: DSNAntenna?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Network Overview
                        NetworkOverviewCard(metrics: dsn.signalMetrics)
                        
                        // Active Antennas
                        VStack(alignment: .leading, spacing: 12) {
                            Text("ACTIVE ANTENNAS")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .padding(.horizontal)
                            
                            ForEach(dsn.antennas) { antenna in
                                AntennaCard(antenna: antenna)
                                    .onTapGesture {
                                        selectedAntenna = antenna
                                    }
                            }
                        }
                        
                        // Recent Telemetry
                        VStack(alignment: .leading, spacing: 12) {
                            Text("TELEMETRY STREAM")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.green)
                                .padding(.horizontal)
                            
                            ForEach(dsn.telemetryPackets.prefix(10)) { packet in
                                TelemetryPacketCard(packet: packet)
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Deep Space Network")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.cyan)
                        Text("DEEP SPACE NETWORK")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(item: $selectedAntenna) { antenna in
                AntennaDetailView(antenna: antenna)
            }
        }
    }
}

struct NetworkOverviewCard: View {
    let metrics: SignalMetrics?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("NETWORK STATUS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                Spacer()
                
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                
                Text("OPERATIONAL")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
            }
            
            if let metrics = metrics {
                Grid(alignment: .leading, horizontalSpacing: 20, verticalSpacing: 8) {
                    GridRow {
                        MetricItem(label: "ACTIVE LINKS", value: "\(metrics.activeLinks)", color: .green)
                        MetricItem(label: "TOTAL DATA RATE", value: String(format: "%.2f Mbps", metrics.totalDataRate), color: .cyan)
                    }
                    
                    GridRow {
                        MetricItem(label: "AVG SIGNAL", value: String(format: "%.1f dBm", metrics.averageSignalStrength), color: .orange)
                        MetricItem(label: "PACKET LOSS", value: String(format: "%.2f%%", metrics.packetLoss), color: metrics.packetLoss > 1 ? .red : .green)
                    }
                    
                    GridRow {
                        MetricItem(label: "LATENCY", value: formatLatency(metrics.latency), color: .purple)
                        Spacer()
                    }
                }
            }
        }
        .padding()
        .background(Color.cyan.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .padding(.horizontal)
    }
    
    func formatLatency(_ seconds: TimeInterval) -> String {
        if seconds < 1 {
            return String(format: "%.0f ms", seconds * 1000)
        } else if seconds < 60 {
            return String(format: "%.2f s", seconds)
        } else if seconds < 3600 {
            return String(format: "%.1f min", seconds / 60)
        } else {
            return String(format: "%.2f hrs", seconds / 3600)
        }
    }
}

struct MetricItem: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(color)
        }
    }
}

struct AntennaCard: View {
    let antenna: DSNAntenna
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(antenna.complex.flag)
                    .font(.title3)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(antenna.name)
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text("\(antenna.complex.name) • \(Int(antenna.aperture))m")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    HStack(spacing: 4) {
                        Image(systemName: antenna.status.icon)
                            .foregroundColor(antenna.status.color)
                            .font(.system(size: 10))
                        
                        Text(antenna.status.name.uppercased())
                            .font(.system(size: 9, weight: .bold, design: .monospaced))
                            .foregroundColor(antenna.status.color)
                    }
                    
                    if let target = antenna.target {
                        Text(target)
                            .font(.system(size: 8, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 6) {
                GridRow {
                    AntennaMetric(label: "EL", value: String(format: "%.1f°", antenna.elevation), icon: "arrow.up")
                    AntennaMetric(label: "AZ", value: String(format: "%.1f°", antenna.azimuth), icon: "arrow.clockwise")
                    AntennaMetric(label: "RSSI", value: String(format: "%.1f", antenna.signalStrength), icon: "waveform")
                }
                
                GridRow {
                    AntennaMetric(label: "FREQ", value: antenna.frequency.name, icon: "antenna.radiowaves.left.and.right")
                    AntennaMetric(label: "RATE", value: String(format: "%.2f Mbps", antenna.dataRate), icon: "speedometer")
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(antenna.status.color.opacity(0.5), lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

struct AntennaMetric: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(.cyan.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
            }
        }
    }
}

struct TelemetryPacketCard: View {
    let packet: TelemetryPacket
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(packet.type.rawValue)
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(packet.type.color)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(packet.type.color.opacity(0.2))
                
                Text(packet.source)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(packet.timestamp, style: .time)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                ForEach(Array(packet.data.keys.sorted()), id: \.self) { key in
                    GridRow {
                        Text("\(key):")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.gray)
                        Text(packet.data[key] ?? "")
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.green)
                    }
                }
            }
            
            HStack {
                Text("RSSI: \(String(format: "%.1f dBm", packet.rssi))")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text("SNR: \(String(format: "%.1f dB", packet.snr))")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.cyan)
            }
        }
        .padding(10)
        .background(Color.green.opacity(0.03))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.green.opacity(0.2), lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

struct AntennaDetailView: View {
    let antenna: DSNAntenna
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        HStack {
                            Text(antenna.complex.flag)
                                .font(.largeTitle)
                            
                            VStack(alignment: .leading) {
                                Text(antenna.name)
                                    .font(.system(size: 18, weight: .bold, design: .monospaced))
                                    .foregroundColor(.white)
                                
                                Text(antenna.complex.name)
                                    .font(.system(size: 12, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
                        // Detailed metrics
                        VStack(spacing: 0) {
                            DSNDetailRow(label: "Aperture", value: "\(Int(antenna.aperture)) meters")
                            DSNDetailRow(label: "Frequency", value: antenna.frequency.name)
                            DSNDetailRow(label: "Elevation", value: String(format: "%.2f°", antenna.elevation))
                            DSNDetailRow(label: "Azimuth", value: String(format: "%.2f°", antenna.azimuth))
                            DSNDetailRow(label: "Signal Strength", value: String(format: "%.2f dBm", antenna.signalStrength))
                            DSNDetailRow(label: "Data Rate", value: String(format: "%.4f Mbps", antenna.dataRate))
                            if let target = antenna.target {
                                DSNDetailRow(label: "Target", value: target)
                            }
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct DSNDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 12, design: .monospaced))
                .foregroundColor(.gray)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                .foregroundColor(.cyan)
        }
        .padding()
        .background(Color.cyan.opacity(0.05))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.cyan.opacity(0.2)),
            alignment: .bottom
        )
    }
}

#Preview {
    DeepSpaceNetworkView()
}
