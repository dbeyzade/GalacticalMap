//
//  GravitationalWaveDetector.swift
//  GalacticalMap
//
//  LIGO-Style Gravitational Wave Detection & Analysis
//  Binary black hole mergers, neutron star collisions, chirp mass calculations
//

import SwiftUI
import Combine
import Accelerate

class GravitationalWaveDetector: ObservableObject {
    static let shared = GravitationalWaveDetector()
    
    @Published var detectedEvents: [GWEvent] = []
    @Published var strainData: [StrainPoint] = []
    @Published var analysisResults: GWAnalysis?
    @Published var isMonitoring = false
    
    // Physical constants
    let G = 6.67430e-11 // Gravitational constant (m³/(kg·s²))
    let c = 299792458.0 // Speed of light (m/s)
    let solarMass = 1.989e30 // kg
    let parsec = 3.0857e16 // meters
    
    // LIGO sensitivity
    let ligoSensitivity = 1e-22 // Dimensionless strain (h)
    
    init() {
        loadHistoricalEvents()
    }
    
    // MARK: - Gravitational Wave Detection
    
    func detectGravitationalWave(strain: [Double], sampleRate: Double) -> GWDetection? {
        // Matched filtering technique used by LIGO
        
        guard strain.count > 1000 else { return nil }
        
        // Remove noise (high-pass filter at 20 Hz)
        let filteredStrain = highPassFilter(data: strain, cutoffHz: 20, sampleRate: sampleRate)
        
        // Whitening (normalize power spectral density)
        let whitenedStrain = whiten(data: filteredStrain, sampleRate: sampleRate)
        
        // Generate template bank for different mass combinations
        var bestMatch: (snr: Double, m1: Double, m2: Double, template: [Double]) = (0, 0, 0, [])
        
        // Search mass range: 5-100 solar masses
        for m1 in stride(from: 5.0, to: 100.0, by: 5.0) {
            for m2 in stride(from: 5.0, to: m1 + 1, by: 5.0) {
                let template = generateChirpTemplate(
                    mass1: m1 * solarMass,
                    mass2: m2 * solarMass,
                    sampleRate: sampleRate
                )
                
                let snr = matchedFilter(signal: whitenedStrain, template: template)
                
                if snr > bestMatch.snr {
                    bestMatch = (snr, m1, m2, template)
                }
            }
        }
        
        // Require SNR > 8 for detection (LIGO threshold)
        guard bestMatch.snr > 8.0 else { return nil }
        
        let chirpMass = calculateChirpMass(mass1: bestMatch.m1 * solarMass, mass2: bestMatch.m2 * solarMass)
        let totalMass = bestMatch.m1 + bestMatch.m2
        
        return GWDetection(
            signalToNoise: bestMatch.snr,
            mass1: bestMatch.m1,
            mass2: bestMatch.m2,
            chirpMass: chirpMass / solarMass,
            totalMass: totalMass,
            peakStrain: filteredStrain.max() ?? 0,
            template: bestMatch.template
        )
    }
    
    // MARK: - Chirp Mass Calculation
    
    func calculateChirpMass(mass1: Double, mass2: Double) -> Double {
        // M_chirp = (m1 * m2)^(3/5) / (m1 + m2)^(1/5)
        
        let numerator = pow(mass1 * mass2, 3.0/5.0)
        let denominator = pow(mass1 + mass2, 1.0/5.0)
        
        return numerator / denominator
    }
    
    func calculateReducedMass(mass1: Double, mass2: Double) -> Double {
        // μ = (m1 * m2) / (m1 + m2)
        return (mass1 * mass2) / (mass1 + mass2)
    }
    
    // MARK: - Waveform Generation
    
    func generateChirpTemplate(mass1: Double, mass2: Double, sampleRate: Double, duration: Double = 1.0) -> [Double] {
        // Generate inspiral waveform using post-Newtonian approximation
        
        let M = mass1 + mass2 // Total mass
        let mu = calculateReducedMass(mass1: mass1, mass2: mass2)
        let eta = mu / M // Symmetric mass ratio
        let chirpMass = calculateChirpMass(mass1: mass1, mass2: mass2)
        
        let samples = Int(duration * sampleRate)
        var waveform: [Double] = []
        
        for i in 0..<samples {
            let t = Double(i) / sampleRate
            
            // Time to coalescence
            let tau = duration - t
            
            // Frequency evolution (chirp)
            let f = chirpFrequency(tau: tau, chirpMass: chirpMass)
            
            // Phase evolution
            let phase = chirpPhase(tau: tau, chirpMass: chirpMass)
            
            // Amplitude (decreases as orbital separation decreases)
            let amplitude = chirpAmplitude(tau: tau, chirpMass: chirpMass, eta: eta)
            
            // Plus polarization (simplified)
            let hPlus = amplitude * cos(phase)
            
            waveform.append(hPlus)
        }
        
        return waveform
    }
    
    func chirpFrequency(tau: Double, chirpMass: Double) -> Double {
        // f(τ) = (1/8π) * (5/τ)^(3/8) * (G*M_chirp/c³)^(-5/8)
        
        guard tau > 0 else { return 100.0 } // Avoid division by zero
        
        let factor1 = 1.0 / (8 * .pi)
        let factor2 = pow(5.0 / tau, 3.0/8.0)
        let factor3 = pow((G * chirpMass) / pow(c, 3), -5.0/8.0)
        
        return factor1 * factor2 * factor3
    }
    
    func chirpPhase(tau: Double, chirpMass: Double) -> Double {
        // Φ(τ) = -2 * (τ/5)^(5/8) * (G*M_chirp/c³)^(-5/8)
        
        guard tau > 0 else { return 0 }
        
        let factor1 = -2.0
        let factor2 = pow(tau / 5.0, 5.0/8.0)
        let factor3 = pow((G * chirpMass) / pow(c, 3), -5.0/8.0)
        
        return factor1 * factor2 * factor3
    }
    
    func chirpAmplitude(tau: Double, chirpMass: Double, eta: Double) -> Double {
        // A(τ) ∝ (G*M_chirp/c²)^(5/4) * τ^(-1/4)
        
        guard tau > 0 else { return 0 }
        
        let factor1 = pow((G * chirpMass) / pow(c, 2), 5.0/4.0)
        let factor2 = pow(tau, -1.0/4.0)
        
        return factor1 * factor2 * 1e22 // Scale for visibility
    }
    
    // MARK: - Signal Processing
    
    func highPassFilter(data: [Double], cutoffHz: Double, sampleRate: Double) -> [Double] {
        // Simple high-pass Butterworth filter
        
        var filtered: [Double] = []
        let RC = 1.0 / (2 * .pi * cutoffHz)
        let dt = 1.0 / sampleRate
        let alpha = RC / (RC + dt)
        
        var previousInput = data[0]
        var previousOutput = 0.0
        
        for input in data {
            let output = alpha * (previousOutput + input - previousInput)
            filtered.append(output)
            
            previousInput = input
            previousOutput = output
        }
        
        return filtered
    }
    
    func whiten(data: [Double], sampleRate: Double) -> [Double] {
        // Spectral whitening - normalize frequency content
        
        // Simplified: just normalize to unit variance
        let mean = data.reduce(0, +) / Double(data.count)
        let variance = data.map { pow($0 - mean, 2) }.reduce(0, +) / Double(data.count)
        let std = sqrt(variance)
        
        return data.map { ($0 - mean) / std }
    }
    
    func matchedFilter(signal: [Double], template: [Double]) -> Double {
        // Cross-correlation for matched filtering
        
        guard signal.count == template.count else { return 0 }
        
        var correlation = 0.0
        var signalPower = 0.0
        var templatePower = 0.0
        
        for i in 0..<signal.count {
            correlation += signal[i] * template[i]
            signalPower += pow(signal[i], 2)
            templatePower += pow(template[i], 2)
        }
        
        let snr = correlation / sqrt(signalPower * templatePower) * sqrt(Double(signal.count))
        
        return snr
    }
    
    // MARK: - Source Localization
    
    func estimateDistance(observedStrain: Double, mass1: Double, mass2: Double) -> Double {
        // Distance estimation from observed strain amplitude
        // h ≈ (4/D) * (G*M_chirp/c²)^(5/4) * (π*f)^(2/3)
        
        let chirpMass = calculateChirpMass(mass1: mass1 * solarMass, mass2: mass2 * solarMass)
        let f = 100.0 // Peak frequency ~100 Hz
        
        let numerator = 4 * pow((G * chirpMass) / pow(c, 2), 5.0/4.0) * pow(.pi * f, 2.0/3.0)
        let distance = numerator / observedStrain
        
        return distance / (1e6 * parsec) // Convert to Megaparsecs
    }
    
    func calculateRedshift(distance: Double) -> Double {
        // Hubble's law: z = H₀ * D / c
        let hubble = 70.0 // km/s/Mpc
        let z = (hubble * distance) / (c / 1000.0)
        return z
    }
    
    // MARK: - Energy Radiated
    
    func calculateRadiatedEnergy(mass1: Double, mass2: Double, finalMass: Double) -> Double {
        // E = (M_initial - M_final) * c²
        
        let initialMass = (mass1 + mass2) * solarMass
        let final = finalMass * solarMass
        let massDeficit = initialMass - final
        
        let energy = massDeficit * pow(c, 2)
        
        return energy
    }
    
    func calculatePeakLuminosity(chirpMass: Double) -> Double {
        // L_peak ≈ c⁵/G ≈ 3.6 × 10⁵² W (for equal mass binaries)
        
        let L = pow(c, 5) / G
        
        // Scale by chirp mass
        let scaleFactor = pow(chirpMass / (10 * solarMass), 2)
        
        return L * scaleFactor
    }
    
    // MARK: - Historical Events Database
    
    func loadHistoricalEvents() {
        detectedEvents = [
            GWEvent(
                name: "GW150914",
                date: Date(timeIntervalSince1970: 1442304517), // Sep 14, 2015
                type: .binaryBlackHole,
                mass1: 36.0,
                mass2: 29.0,
                finalMass: 62.0,
                distance: 410, // Mpc
                peakStrain: 1.0e-21,
                significance: 5.1, // sigma
                description: "First gravitational wave detection! Binary black hole merger."
            ),
            GWEvent(
                name: "GW170817",
                date: Date(timeIntervalSince1970: 1503137191), // Aug 17, 2017
                type: .binaryNeutronStar,
                mass1: 1.46,
                mass2: 1.27,
                finalMass: 2.74,
                distance: 40, // Mpc
                peakStrain: 2.5e-22,
                significance: 32.4,
                description: "First neutron star merger with electromagnetic counterpart (GRB 170817A, kilonova AT 2017gfo)"
            ),
            GWEvent(
                name: "GW190521",
                date: Date(timeIntervalSince1970: 1558474154), // May 21, 2019
                type: .binaryBlackHole,
                mass1: 85.0,
                mass2: 66.0,
                finalMass: 142.0,
                distance: 5300, // Mpc
                peakStrain: 8.0e-22,
                significance: 14.7,
                description: "Most massive black hole merger. First intermediate-mass black hole!"
            ),
            GWEvent(
                name: "GW200115",
                date: Date(timeIntervalSince1970: 1579089767), // Jan 15, 2020
                type: .neutronStarBlackHole,
                mass1: 5.7,
                mass2: 1.5,
                finalMass: 7.2,
                distance: 300, // Mpc
                peakStrain: 4.2e-22,
                significance: 8.4,
                description: "First confirmed neutron star - black hole merger"
            ),
            GWEvent(
                name: "GW230529",
                date: Date(timeIntervalSince1970: 1685361600), // May 29, 2023
                type: .binaryNeutronStar,
                mass1: 1.4,
                mass2: 1.3,
                finalMass: 2.5,
                distance: 650, // Mpc
                peakStrain: 1.8e-22,
                significance: 11.2,
                description: "Recent neutron star merger with possible r-process nucleosynthesis"
            )
        ]
    }
    
    // MARK: - Real-time Monitoring Simulation
    
    func startMonitoring() {
        isMonitoring = true
        
        // Simulate strain data
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] timer in
            guard let self = self, self.isMonitoring else {
                timer.invalidate()
                return
            }
            
            // Generate simulated noise + possible signal
            let noise = Double.random(in: -1e-22...1e-22)
            
            self.strainData.append(StrainPoint(
                time: Date(),
                strain: noise
            ))
            
            // Keep only last 100 points
            if self.strainData.count > 100 {
                self.strainData.removeFirst()
            }
        }
    }
    
    func stopMonitoring() {
        isMonitoring = false
    }
}

// MARK: - Models

struct GWEvent: Identifiable {
    let id = UUID()
    let name: String
    let date: Date
    let type: GWEventType
    let mass1: Double // Solar masses
    let mass2: Double
    let finalMass: Double
    let distance: Double // Megaparsecs
    let peakStrain: Double
    let significance: Double // Sigma
    let description: String
    
    var radiatedEnergy: Double {
        let detector = GravitationalWaveDetector.shared
        return detector.calculateRadiatedEnergy(
            mass1: mass1,
            mass2: mass2,
            finalMass: finalMass
        )
    }
    
    var radiatedMass: Double {
        return mass1 + mass2 - finalMass
    }
}

enum GWEventType: String {
    case binaryBlackHole = "Binary Black Hole"
    case binaryNeutronStar = "Binary Neutron Star"
    case neutronStarBlackHole = "Neutron Star - Black Hole"
    case unknown = "Unknown"
    
    var icon: String {
        switch self {
        case .binaryBlackHole: return "circle.circle.fill"
        case .binaryNeutronStar: return "star.fill"
        case .neutronStarBlackHole: return "star.circle.fill"
        case .unknown: return "questionmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .binaryBlackHole: return .purple
        case .binaryNeutronStar: return .orange
        case .neutronStarBlackHole: return .blue
        case .unknown: return .gray
        }
    }
}

struct GWDetection {
    let signalToNoise: Double
    let mass1: Double // Solar masses
    let mass2: Double
    let chirpMass: Double
    let totalMass: Double
    let peakStrain: Double
    let template: [Double]
}

struct GWAnalysis {
    let detection: GWDetection
    let distance: Double // Mpc
    let redshift: Double
    let radiatedEnergy: Double // Joules
    let peakLuminosity: Double // Watts
    let confidence: Double // 0-1
}

struct StrainPoint {
    let time: Date
    let strain: Double
}

// MARK: - Gravitational Wave Observatory View

struct GravitationalWaveView: View {
    @StateObject private var detector = GravitationalWaveDetector.shared
    @State private var selectedEvent: GWEvent?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // LIGO Status
                        LIGOStatusCard(isMonitoring: detector.isMonitoring)
                        
                        // Real-time strain monitor
                        if detector.isMonitoring {
                            StrainMonitorView(data: detector.strainData)
                        }
                        
                        // Control buttons
                        HStack(spacing: 12) {
                            Button {
                                if detector.isMonitoring {
                                    detector.stopMonitoring()
                                } else {
                                    detector.startMonitoring()
                                }
                            } label: {
                                Label(detector.isMonitoring ? "STOP" : "START", systemImage: detector.isMonitoring ? "stop.fill" : "play.fill")
                                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                                    .foregroundColor(.black)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(detector.isMonitoring ? Color.red : Color.green)
                            }
                        }
                        .padding(.horizontal)
                        
                        // Historical detections
                        VStack(alignment: .leading, spacing: 12) {
                            Text("CONFIRMED DETECTIONS")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.purple)
                                .padding(.horizontal)
                            
                            ForEach(detector.detectedEvents) { event in
                                GWEventCard(event: event)
                                    .onTapGesture {
                                        selectedEvent = event
                                    }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Gravitational Waves")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path.ecg")
                            .foregroundColor(.purple)
                        Text("GRAVITATIONAL WAVE OBSERVATORY")
                            .font(.system(size: 13, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                }
            }
            .sheet(item: $selectedEvent) { event in
                GWEventDetailView(event: event)
            }
        }
    }
}

struct LIGOStatusCard: View {
    let isMonitoring: Bool
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("LIGO-STYLE DETECTOR")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.white)
                
                Spacer()
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(isMonitoring ? Color.green : Color.red)
                        .frame(width: 10, height: 10)
                    
                    Text(isMonitoring ? "OBSERVING" : "OFFLINE")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(isMonitoring ? .green : .red)
                }
            }
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    StatItem(label: "SENSITIVITY", value: "10⁻²² strain", icon: "ruler")
                    StatItem(label: "ARM LENGTH", value: "4 km", icon: "arrow.left.and.right")
                }
                
                GridRow {
                    StatItem(label: "FREQUENCY", value: "10-5000 Hz", icon: "waveform")
                    StatItem(label: "LASER POWER", value: "100 kW", icon: "light.beacon.max")
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.purple.opacity(0.5), lineWidth: 2)
        )
    }
}

struct StatItem: View {
    let label: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(.purple.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.purple)
            }
        }
    }
}

struct StrainMonitorView: View {
    let data: [StrainPoint]
    
    private var maxStrain: Double { 2e-22 }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            headerView
            chartView
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    private var headerView: some View {
        Text("REAL-TIME STRAIN (h)")
            .font(.system(size: 10, weight: .bold, design: .monospaced))
            .foregroundColor(.green)
    }
    
    private var chartView: some View {
        GeometryReader { geometry in
            ZStack {
                strainPath(in: geometry)
                    .stroke(Color.green, lineWidth: 1)
                
                zeroLine(in: geometry)
                    .stroke(Color.white.opacity(0.3), style: StrokeStyle(lineWidth: 1, dash: [5]))
            }
        }
        .frame(height: 120)
        .background(Color.black)
    }
    
    private func strainPath(in geometry: GeometryProxy) -> Path {
        Path { path in
            guard !data.isEmpty else { return }
            
            let width = geometry.size.width
            let height = geometry.size.height
            
            for (index, point) in data.enumerated() {
                let x = width * Double(index) / Double(max(data.count - 1, 1))
                let y = height / 2 - (point.strain / maxStrain) * (height / 2)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
    }
    
    private func zeroLine(in geometry: GeometryProxy) -> Path {
        Path { path in
            let y = geometry.size.height / 2
            path.move(to: CGPoint(x: 0, y: y))
            path.addLine(to: CGPoint(x: geometry.size.width, y: y))
        }
    }
}

struct GWEventCard: View {
    let event: GWEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: event.type.icon)
                    .font(.title2)
                    .foregroundColor(event.type.color)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(event.type.rawValue)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(event.type.color)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text(event.date, style: .date)
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    HStack(spacing: 4) {
                        Text("\(String(format: "%.1f", event.significance))σ")
                            .font(.system(size: 11, weight: .bold, design: .monospaced))
                            .foregroundColor(.yellow)
                        
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.green)
                    }
                }
            }
            
            Text(event.description)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)
                .lineLimit(2)
            
            Divider().background(Color.gray.opacity(0.3))
            
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    MassLabel(value: event.mass1, label: "M₁")
                    MassLabel(value: event.mass2, label: "M₂")
                    MassLabel(value: event.finalMass, label: "M_final")
                }
                
                GridRow {
                    DistanceLabel(value: event.distance)
                    StrainLabel(value: event.peakStrain)
                    EnergyLabel(value: event.radiatedMass)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(event.type.color.opacity(0.5), lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

struct MassLabel: View {
    let value: Double
    let label: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
            Text("\(String(format: "%.1f", value)) M☉")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.purple)
        }
    }
}

struct DistanceLabel: View {
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("DISTANCE")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
            Text("\(Int(value)) Mpc")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.cyan)
        }
    }
}

struct StrainLabel: View {
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("PEAK h")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
            Text(String(format: "%.1e", value))
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.green)
        }
    }
}

struct EnergyLabel: View {
    let value: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("RADIATED")
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.gray)
            Text("\(String(format: "%.1f", value)) M☉c²")
                .font(.system(size: 9, weight: .semibold, design: .monospaced))
                .foregroundColor(.orange)
        }
    }
}

struct GWEventDetailView: View {
    let event: GWEvent
    @Environment(\.dismiss) var dismiss
    
    var detector: GravitationalWaveDetector {
        GravitationalWaveDetector.shared
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Event name
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Image(systemName: event.type.icon)
                                    .font(.largeTitle)
                                    .foregroundColor(event.type.color)
                                
                                VStack(alignment: .leading) {
                                    Text(event.name)
                                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                                        .foregroundColor(.white)
                                    
                                    Text(event.type.rawValue)
                                        .font(.system(size: 14, design: .monospaced))
                                        .foregroundColor(event.type.color)
                                }
                            }
                            
                            Text(event.description)
                                .font(.system(size: 12, design: .monospaced))
                                .foregroundColor(.gray)
                        }
                        .padding()
                        
                        // Masses
                        DetailPanel(title: "COMPONENT MASSES") {
                            DetailValueRow(label: "Primary (M₁)", value: "\(String(format: "%.2f", event.mass1)) M☉")
                            DetailValueRow(label: "Secondary (M₂)", value: "\(String(format: "%.2f", event.mass2)) M☉")
                            DetailValueRow(label: "Final Mass", value: "\(String(format: "%.2f", event.finalMass)) M☉")
                            DetailValueRow(label: "Radiated Mass", value: "\(String(format: "%.2f", event.radiatedMass)) M☉", highlight: true)
                            
                            let chirpMass = detector.calculateChirpMass(
                                mass1: event.mass1 * detector.solarMass,
                                mass2: event.mass2 * detector.solarMass
                            ) / detector.solarMass
                            DetailValueRow(label: "Chirp Mass", value: String(format: "%.2f M☉", chirpMass))
                        }
                        
                        // Energy
                        DetailPanel(title: "RADIATED ENERGY") {
                            DetailValueRow(
                                label: "Energy",
                                value: String(format: "%.2e J", event.radiatedEnergy),
                                highlight: true
                            )
                            DetailValueRow(
                                label: "Equivalent Mass",
                                value: "\(String(format: "%.2f", event.radiatedMass)) M☉ = \(String(format: "%.2e", event.radiatedMass * detector.solarMass)) kg"
                            )
                            
                            let luminosity = detector.calculatePeakLuminosity(
                                chirpMass: detector.calculateChirpMass(
                                    mass1: event.mass1 * detector.solarMass,
                                    mass2: event.mass2 * detector.solarMass
                                )
                            )
                            DetailValueRow(
                                label: "Peak Luminosity",
                                value: String(format: "%.2e W", luminosity)
                            )
                        }
                        
                        // Detection details
                        DetailPanel(title: "DETECTION") {
                            DetailValueRow(label: "Date", value: event.date.formatted())
                            DetailValueRow(label: "Distance", value: "\(Int(event.distance)) Mpc (\(String(format: "%.2e", Double(event.distance) * 3.26e6)) ly)")
                            DetailValueRow(label: "Peak Strain (h)", value: String(format: "%.2e", event.peakStrain))
                            DetailValueRow(label: "Significance", value: "\(String(format: "%.1f", event.significance))σ", highlight: true)
                            
                            let z = detector.calculateRedshift(distance: event.distance)
                            DetailValueRow(label: "Redshift (z)", value: String(format: "%.6f", z))
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
                    .foregroundColor(.purple)
                }
            }
        }
    }
}

struct DetailPanel<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.purple)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content()
            }
            .background(Color.purple.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct DetailValueRow: View {
    let label: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: highlight ? 12 : 11, weight: highlight ? .bold : .semibold, design: .monospaced))
                .foregroundColor(highlight ? .yellow : .white)
        }
        .padding()
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.purple.opacity(0.1)),
            alignment: .bottom
        )
    }
}

#Preview {
    GravitationalWaveView()
}
