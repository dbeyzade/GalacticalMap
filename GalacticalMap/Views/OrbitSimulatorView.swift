//
//  OrbitSimulatorView.swift
//  GalacticalMap
//
//  Yörünge simülatörü - Uydu fırlatma oyunu
//

import SwiftUI

struct OrbitSimulatorView: View {
    @State private var altitude: Double = 400
    @State private var velocity: Double = 7.8
    @State private var isSimulating = false
    @State private var orbitType: OrbitType = .leo
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background Space
                OrbitSpaceBackgroundView()
                
                ScrollView {
                    VStack(spacing: 25) {
                        // Orbit Visualizer
                        OrbitVisualizerView(altitude: altitude, velocity: velocity, isSimulating: isSimulating)
                            .frame(height: 350)
                            .shadow(color: .cyan.opacity(0.3), radius: 20)
                        
                        // Controls
                        VStack(spacing: 25) {
                            // Header
                            Text("Mission Control")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // Altitude Slider
                            ControlSlider(
                                title: "Yükseklik",
                                value: $altitude,
                                range: 200...36000,
                                unit: "km",
                                icon: "arrow.up.and.down",
                                color: .cyan
                            )
                            
                            // Velocity Slider
                            ControlSlider(
                                title: "Hız",
                                value: $velocity,
                                range: 6.0...11.0,
                                unit: "km/s",
                                icon: "gauge.with.dots.needle.bottom.50percent",
                                color: .orange
                            )
                            
                            // Orbit Type
                            VStack(alignment: .leading, spacing: 10) {
                                Label("Yörünge Tipi", systemImage: "circle.dashed")
                                    .font(.caption)
                                    .foregroundStyle(.gray)
                                
                                Picker("Yörünge Tipi", selection: $orbitType) {
                                    ForEach(OrbitType.allCases, id: \.self) { type in
                                        Text(type.rawValue).tag(type)
                                    }
                                }
                                .pickerStyle(.segmented)
                            }
                            
                            // Launch Button
                            Button(action: {
                                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                                    isSimulating.toggle()
                                }
                            }) {
                                HStack {
                                    Image(systemName: isSimulating ? "pause.fill" : "rocket.fill")
                                    Text(isSimulating ? "Görevi Durdur" : "Fırlat!")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: isSimulating ? [.red, .orange] : [.blue, .cyan],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .shadow(color: isSimulating ? .red.opacity(0.5) : .cyan.opacity(0.5), radius: 10, y: 5)
                            }
                        }
                        .padding(20)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(.white.opacity(0.1), lineWidth: 1)
                        )
                        
                        // Orbit Info
                        OrbitInfoCard(altitude: altitude, velocity: velocity)
                    }
                    .padding()
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("🚀 Yörünge Simülatörü")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

struct ControlSlider: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.caption)
                    .foregroundStyle(.gray)
                Spacer()
                Text("\(value, specifier: "%.0f") \(unit)")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundStyle(color)
            }
            
            Slider(value: $value, in: range) {
                Text(title)
            } minimumValueLabel: {
                Text("\(Int(range.lowerBound))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            } maximumValueLabel: {
                Text("\(Int(range.upperBound))")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .tint(color)
        }
    }
}

struct OrbitSpaceBackgroundView: View {
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            // Stars
            GeometryReader { geometry in
                ForEach(0..<50) { _ in
                    Circle()
                        .fill(Color.white)
                        .frame(width: CGFloat.random(in: 1...3), height: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .opacity(Double.random(in: 0.3...1.0))
                }
            }
            
            // Nebula Effect
            RadialGradient(
                colors: [Color.purple.opacity(0.2), Color.blue.opacity(0.1), Color.clear],
                center: .topLeading,
                startRadius: 100,
                endRadius: 600
            )
            .ignoresSafeArea()
            
            RadialGradient(
                colors: [Color.orange.opacity(0.1), Color.clear],
                center: .bottomTrailing,
                startRadius: 50,
                endRadius: 400
            )
            .ignoresSafeArea()
        }
    }
}

struct OrbitVisualizerView: View {
    let altitude: Double
    let velocity: Double
    let isSimulating: Bool
    @State private var rotation: Double = 0
    
    // Visual scaling
    private var earthRadius: CGFloat { 60 }
    private var orbitScale: CGFloat {
        // Scale altitude for visual representation (not to scale)
        return 1.0 + (altitude / 10000.0)
    }
    
    var body: some View {
        ZStack {
            // Orbit Path
            Circle()
                .stroke(
                    LinearGradient(
                        colors: [.cyan.opacity(0.5), .blue.opacity(0.2)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 2, dash: [10, 5])
                )
                .frame(width: earthRadius * 2 * orbitScale, height: earthRadius * 2 * orbitScale)
                .rotationEffect(.degrees(rotation * 0.1)) // Rotate the orbit ring slightly
            
            // Earth
            ZStack {
                // Atmosphere Glow
                Circle()
                    .fill(Color.blue.opacity(0.3))
                    .frame(width: earthRadius * 2.4, height: earthRadius * 2.4)
                    .blur(radius: 10)
                
                // Planet Body
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color(orbitHex: "1a237e"), Color.black],
                            center: .center,
                            startRadius: 10,
                            endRadius: earthRadius
                        )
                    )
                    .overlay(
                        // Simple continents suggestion
                        Circle()
                            .stroke(Color.blue.opacity(0.4), lineWidth: 2)
                            .clipShape(Circle())
                    )
                    .frame(width: earthRadius * 2, height: earthRadius * 2)
                    .shadow(color: .blue.opacity(0.5), radius: 15)
            }
            
            // Satellite
            if isSimulating {
                SatelliteView()
                    .offset(y: -earthRadius * orbitScale)
                    .rotationEffect(.degrees(rotation))
            } else {
                SatelliteView()
                    .offset(y: -earthRadius * orbitScale)
            }
        }
        .onChange(of: isSimulating) { newValue in
            if newValue {
                // Start animation loop
                let duration = 60.0 / velocity // Simple speed correlation
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            } else {
                withAnimation {
                    rotation = 0
                }
            }
        }
    }
}

struct SatelliteView: View {
    var body: some View {
        VStack(spacing: 2) {
            // Solar Panels
            HStack(spacing: 0) {
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 6)
                    .border(Color.white.opacity(0.5), width: 0.5)
                
                Rectangle() // Body
                    .fill(Color.gray)
                    .frame(width: 6, height: 8)
                
                Rectangle()
                    .fill(Color.blue)
                    .frame(width: 12, height: 6)
                    .border(Color.white.opacity(0.5), width: 0.5)
            }
            // Antenna
            Circle()
                .trim(from: 0.5, to: 1)
                .stroke(Color.gray, lineWidth: 1)
                .frame(width: 6, height: 6)
        }
        .shadow(color: .white.opacity(0.8), radius: 2)
    }
}

struct OrbitInfoCard: View {
    let altitude: Double
    let velocity: Double
    
    var period: Double {
        let radius = 6371 + altitude
        return 2 * .pi * radius / (velocity * 60)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Label("Telemetri Verileri", systemImage: "chart.bar.xaxis")
                .font(.headline)
                .foregroundStyle(.white)
            
            Divider().background(.white.opacity(0.2))
            
            HStack(spacing: 20) {
                OrbitInfoBox(
                    title: "Periyot",
                    value: String(format: "%.1f", period),
                    unit: "dk",
                    icon: "clock"
                )
                
                OrbitInfoBox(
                    title: "Yarıçap",
                    value: String(format: "%.0f", 6371 + altitude),
                    unit: "km",
                    icon: "circle.dotted"
                )
                
                OrbitInfoBox(
                    title: "Kaçış",
                    value: "11.2",
                    unit: "km/s",
                    icon: "arrow.up.right"
                )
            }
        }
        .padding(20)
        .background(.ultraThinMaterial)
        .cornerRadius(24)
        .overlay(
            RoundedRectangle(cornerRadius: 24)
                .stroke(.white.opacity(0.1), lineWidth: 1)
        )
    }
}

struct OrbitInfoBox: View {
    let title: String
    let value: String
    let unit: String
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack {
                Image(systemName: icon)
                    .font(.caption2)
                Text(title)
                    .font(.caption)
            }
            .foregroundStyle(.gray)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(.title3, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                Text(unit)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

enum OrbitType: String, CaseIterable {
    case leo = "LEO"
    case meo = "MEO"
    case geo = "GEO"
    case heo = "HEO"
}

extension Color {
    init(orbitHex: String) {
        let hex = orbitHex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

#Preview {
    OrbitSimulatorView()
        .preferredColorScheme(.dark)
}