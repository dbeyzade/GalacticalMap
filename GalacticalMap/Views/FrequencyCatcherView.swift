//
//  FrequencyCatcherView.swift
//  GalacticalMap
//
//  Etraftaki frekansları simüle eden ve yakalayan modül
//

import SwiftUI
import CoreLocation
import Combine

struct FrequencyCatcherView: View {
    @StateObject private var scanner = FrequencyScanner()
    @State private var isScanning = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Radar Visualization
                    if isScanning {
                        RadarScanningView(signals: scanner.detectedSignals)
                            .padding()
                            .transition(.scale.combined(with: .opacity))
                    }
                    
                    // Controls
                    HStack {
                        Button(action: {
                            withAnimation {
                                isScanning.toggle()
                                if isScanning {
                                    scanner.startScanning()
                                } else {
                                    scanner.stopScanning()
                                }
                            }
                        }) {
                            Label(isScanning ? "STOP SCANNING" : "START SCANNING", systemImage: isScanning ? "stop.fill" : "antenna.radiowaves.left.and.right")
                                .font(.system(.headline, design: .monospaced))
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(isScanning ? Color.red : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(12)
                                .shadow(radius: 0)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    
                    // Status
                    if isScanning {
                        HStack {
                            ProgressView()
                                .tint(.green)
                            Text("SCANNING LOCAL SPECTRUM...")
                                .font(.system(.caption, design: .monospaced))
                                .foregroundColor(.green)
                        }
                        .padding(.bottom)
                    }
                    
                    // Detected Signals List
                    List {
                        ForEach(scanner.detectedSignals) { signal in
                            NavigationLink(destination: SignalDetailView(signal: signal)) {
                                SignalRow(signal: signal)
                            }
                            .listRowBackground(Color.black)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Frequency Catcher")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("FREQUENCY CATCHER")
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.green)
                }
            }
        }
    }
}

struct SignalDetailView: View {
    let signal: DetectedSignal
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .font(.system(size: 60))
                            .foregroundColor(signal.type.color)
                            .padding()
                            .background(signal.type.color.opacity(0.1))
                            .clipShape(Circle())
                        
                        Text(signal.name)
                            .font(.system(.title2, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(signal.type.rawValue.uppercased())
                            .font(.caption)
                            .fontWeight(.bold)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(signal.type.color)
                            .foregroundColor(.black)
                            .cornerRadius(8)
                    }
                    .padding(.top, 20)
                    
                    // Signal Info Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        DetailItem(title: "FREQUENCY", value: String(format: "%.3f MHz", signal.frequency))
                        DetailItem(title: "RSSI", value: "\(Int(signal.rssi)) dBm")
                        DetailItem(title: "STRENGTH", value: "\(Int(signal.strength * 100))%")
                        DetailItem(title: "MODULATION", value: "QAM-64") // Simulated
                    }
                    .padding()
                    
                    // Waveform Visualization (Simulated)
                    VStack(alignment: .leading) {
                        Text("SIGNAL WAVEFORM")
                            .font(.caption)
                            .foregroundColor(.gray)
                            .padding(.horizontal)
                        
                        WaveformView(color: signal.type.color)
                            .frame(height: 100)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                            .padding(.horizontal)
                    }
                    
                    // Description
                    VStack(alignment: .leading, spacing: 8) {
                        Text("ANALYSIS REPORT")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text(signal.description)
                            .font(.body)
                            .foregroundColor(.white.opacity(0.9))
                            .padding()
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(12)
                    }
                    .padding(.horizontal)
                    
                    Spacer()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(Color.black, for: .navigationBar)
    }
}

struct DetailItem: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.system(.headline, design: .monospaced))
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
    }
}

struct WaveformView: View {
    let color: Color
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let width = geometry.size.width
                let height = geometry.size.height
                let midHeight = height / 2
                
                path.move(to: CGPoint(x: 0, y: midHeight))
                
                for x in stride(from: 0, to: width, by: 2) {
                    let relativeX = x / 20
                    let sine = sin(relativeX)
                    let y = midHeight + (sine * (height * 0.4))
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
            .stroke(color, lineWidth: 2)
        }
    }
}

struct RadarScanningView: View {
    let signals: [DetectedSignal]
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Radar Background
            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    .scaleEffect(0.7)
                
                Circle()
                    .stroke(Color.green.opacity(0.1), lineWidth: 1)
                    .scaleEffect(0.4)
                
                // Crosshairs
                GeometryReader { geo in
                    Path { path in
                        let w = geo.size.width
                        let h = geo.size.height
                        
                        path.move(to: CGPoint(x: w / 2, y: 0))
                        path.addLine(to: CGPoint(x: w / 2, y: h))
                        path.move(to: CGPoint(x: 0, y: h / 2))
                        path.addLine(to: CGPoint(x: w, y: h / 2))
                    }
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
                }
            }
            
            // Detected Signals
            ForEach(signals) { signal in
                SignalBlipView(signal: signal)
            }
            
            // Rotating Sweep
            AngularGradient(
                gradient: Gradient(colors: [.green.opacity(0), .green.opacity(0.5)]),
                center: .center
            )
            .rotationEffect(.degrees(rotation))
            .clipShape(Circle())
        }
        .frame(width: 220, height: 220) // Reduced size
        .onAppear {
            withAnimation(.linear(duration: 2.0).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct SignalBlipView: View {
    let signal: DetectedSignal
    @State private var opacity: Double = 1.0
    
    var body: some View {
        GeometryReader { geometry in
            let radius = geometry.size.width / 2
            let angleRad = signal.azimuth * .pi / 180
            let dist = signal.distance * radius
            
            let x = radius + cos(angleRad) * dist
            let y = radius + sin(angleRad) * dist
            
            VStack(spacing: 2) {
                Circle()
                    .fill(signal.type.color)
                    .frame(width: 8, height: 8)
                    .shadow(color: signal.type.color, radius: 4)
                
                Text(signal.name)
                    .font(.system(size: 8, weight: .bold, design: .monospaced))
                    .foregroundColor(signal.type.color)
                    .padding(2)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(4)
            }
            .position(x: x, y: y)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                    opacity = 0.5
                }
            }
            .opacity(opacity)
        }
    }
}

struct SignalRow: View {
    let signal: DetectedSignal
    
    var body: some View {
        HStack(spacing: 16) {
            // Signal Strength Indicator
            VStack(spacing: 2) {
                ForEach(0..<5) { i in
                    Rectangle()
                        .fill(signal.strength > Double(i) * 0.2 ? signal.type.color : Color.gray.opacity(0.3))
                        .frame(width: 4, height: 6 + Double(i) * 3)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(signal.name)
                        .font(.system(.headline, design: .monospaced))
                        .foregroundColor(.white)
                    Spacer()
                    Text(String(format: "%.1f MHz", signal.frequency))
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                
                Text(signal.description)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
                
                HStack {
                    Text(signal.type.rawValue.uppercased())
                        .font(.system(size: 10, weight: .bold))
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(signal.type.color.opacity(0.2))
                        .foregroundColor(signal.type.color)
                        .cornerRadius(4)
                    
                    Text("RSSI: \(Int(signal.rssi)) dBm")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(.caption)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(signal.type.color.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Logic

class FrequencyScanner: ObservableObject {
    @Published var detectedSignals: [DetectedSignal] = []
    private var timer: Timer?
    
    func startScanning() {
        detectedSignals.removeAll()
        
        // Add some initial noise signals
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            self?.discoverRandomSignal()
        }
    }
    
    func stopScanning() {
        timer?.invalidate()
        timer = nil
    }
    
    private func discoverRandomSignal() {
        let types: [SignalType] = [.cellular, .wifi, .radio, .satellite, .unknown]
        let type = types.randomElement()!
        
        let signal = DetectedSignal(
            id: UUID(),
            name: generateName(for: type),
            frequency: generateFrequency(for: type),
            type: type,
            strength: Double.random(in: 0.3...1.0),
            rssi: Double.random(in: -90...(-40)),
            description: generateDescription(for: type),
            azimuth: Double.random(in: 0...360),
            distance: Double.random(in: 0.2...0.9)
        )
        
        withAnimation {
            detectedSignals.insert(signal, at: 0)
            if detectedSignals.count > 20 {
                detectedSignals.removeLast()
            }
        }
    }
    
    private func generateName(for type: SignalType) -> String {
        switch type {
        case .cellular: return ["LTE Band 3", "5G NR", "GSM 900", "UMTS 2100"].randomElement()!
        case .wifi: return ["Home_WiFi_2.4", "Office_Net_5G", "Free_Public_WiFi", "Linksys_Setup"].randomElement()!
        case .radio: return ["FM Broadcast", "AM Broadcast", "Shortwave Radio", "Police Scanner"].randomElement()!
        case .satellite: return ["GPS L1", "GLONASS G1", "Starlink Uplink", "Iridium Burst"].randomElement()!
        case .unknown: return ["Unknown Encrypted", "Strange Pulse", "Cosmic Noise", "Anomaly Signal"].randomElement()!
        }
    }
    
    private func generateFrequency(for type: SignalType) -> Double {
        switch type {
        case .cellular: return Double.random(in: 700...2600)
        case .wifi: return Double.random(in: 2400...5800)
        case .radio: return Double.random(in: 88...108)
        case .satellite: return Double.random(in: 1200...1600)
        case .unknown: return Double.random(in: 100...9000)
        }
    }
    
    private func generateDescription(for type: SignalType) -> String {
        switch type {
        case .cellular: return "Local cell tower beacon. Strong signal."
        case .wifi: return "Wireless local area network. IEEE 802.11 standard."
        case .radio: return "Public broadcast modulation. Audio content detected."
        case .satellite: return "Orbital positioning signal. High altitude source."
        case .unknown: return "Unidentified modulation pattern. Analyzing..."
        }
    }
}

struct DetectedSignal: Identifiable {
    let id: UUID
    let name: String
    let frequency: Double // MHz
    let type: SignalType
    let strength: Double // 0.0 - 1.0
    let rssi: Double // dBm
    let description: String
    let azimuth: Double // 0-360 degrees
    let distance: Double // 0.0-1.0 from center
}

enum SignalType: String {
    case cellular = "cellular"
    case wifi = "wifi"
    case radio = "radio"
    case satellite = "satellite"
    case unknown = "unknown"
    
    var color: Color {
        switch self {
        case .cellular: return .green
        case .wifi: return .blue
        case .radio: return .orange
        case .satellite: return .purple
        case .unknown: return .red
        }
    }
}

#Preview {
    FrequencyCatcherView()
}
