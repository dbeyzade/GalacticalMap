//
//  SolarActivityView.swift
//  GalacticalMap
//
//  Güneş aktivitesi - Professional Edition
//

import SwiftUI

struct SolarActivityView: View {
    @State private var solarData: SolarData = SolarData.current
    @State private var flares: [SolarFlareEvent] = SolarFlareEvent.recent
    @State private var animateSun = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Animated Sun Visualization
                        ZStack {
                            // Outer Glow
                            Circle()
                                .fill(RadialGradient(colors: [.orange.opacity(0.3), .clear], center: .center, startRadius: 100, endRadius: 180))
                                .scaleEffect(animateSun ? 1.1 : 1.0)
                                .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: animateSun)
                            
                            // Sun Disk
                            Circle()
                                .fill(RadialGradient(colors: [.yellow, .orange, .red], center: .center, startRadius: 20, endRadius: 100))
                                .frame(width: 200, height: 200)
                                .overlay(
                                    Circle()
                                        .stroke(Color.orange.opacity(0.5), lineWidth: 2)
                                )
                                .shadow(color: .orange, radius: 50)
                            
                            // Sunspots (Simulated)
                            Circle()
                                .fill(Color.black.opacity(0.6))
                                .frame(width: 8, height: 8)
                                .offset(x: 40, y: -30)
                            
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .frame(width: 12, height: 12)
                                .offset(x: -20, y: 50)
                            
                            VStack {
                                Text("LIVE")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.red)
                                    .foregroundColor(.white)
                                    .cornerRadius(4)
                                Spacer()
                            }
                            .padding(.top, -120)
                        }
                        .frame(height: 250)
                        .onAppear {
                            animateSun = true
                        }
                        
                        // Key Metrics Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                            SolarMetricCard(title: "Sunspots", value: "\(solarData.sunspotCount)", icon: "sun.max.fill", color: .orange)
                            SolarMetricCard(title: "Solar Flux", value: solarData.solarFlux, icon: "wave.3.right", color: .yellow)
                            SolarMetricCard(title: "K-Index", value: "\(solarData.kIndex)", icon: "chart.bar.fill", color: solarData.kIndex > 4 ? .red : .green)
                            SolarMetricCard(title: "Wind Speed", value: "\(solarData.solarWindSpeed) km/s", icon: "wind", color: .cyan)
                        }
                        .padding(.horizontal)
                        
                        // Solar Flare Timeline
                        VStack(alignment: .leading, spacing: 16) {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundColor(.yellow)
                                Text("X-RAY FLUX ALERTS")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                            }
                            .padding(.horizontal)
                            
                            if flares.isEmpty {
                                Text("No recent solar flares detected.")
                                    .foregroundColor(.gray)
                                    .padding()
                            } else {
                                ForEach(flares) { flare in
                                    FlareRow(flare: flare)
                                }
                            }
                        }
                        .padding(.vertical)
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal)
                        
                        // Geomagnetic Status
                        VStack(alignment: .leading, spacing: 16) {
                            Text("GEOMAGNETIC STATUS")
                                .font(.headline)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                                .padding(.horizontal)
                            
                            HStack(spacing: 20) {
                                ZStack {
                                    Circle()
                                        .stroke(Color.white.opacity(0.1), lineWidth: 10)
                                        .frame(width: 100, height: 100)
                                    
                                    Circle()
                                        .trim(from: 0, to: 0.4)
                                        .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                        .frame(width: 100, height: 100)
                                        .rotationEffect(.degrees(-90))
                                    
                                    VStack {
                                        Text("Kp \(solarData.kIndex)")
                                            .font(.title2)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("Stable")
                                            .font(.caption)
                                            .foregroundColor(.green)
                                    }
                                }
                                
                                VStack(alignment: .leading, spacing: 12) {
                                    StatusRow(label: "Field Magnitude", value: "5.4 nT")
                                    StatusRow(label: "Bz Component", value: "-1.2 nT")
                                    StatusRow(label: "Density", value: "\(solarData.solarWindDensity) p/cm³")
                                }
                            }
                            .padding()
                        }
                        .background(Color.white.opacity(0.05))
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Solar Dynamics")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SolarMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(color)
                Spacer()
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Text(title)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
        .padding()
        .background(Color.white.opacity(0.08))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(LinearGradient(colors: [color.opacity(0.3), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
        )
    }
}

struct FlareRow: View {
    let flare: SolarFlareEvent
    
    var body: some View {
        HStack(spacing: 16) {
            Text(flare.classification)
                .font(.title3)
                .fontWeight(.black)
                .foregroundColor(flare.color)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(flare.impact)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .lineLimit(1)
                
                Text(flare.time, style: .relative)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if flare.affectsEarth {
                Image(systemName: "globe.americas.fill")
                    .foregroundColor(.blue)
            }
        }
        .padding()
        .background(Color.black.opacity(0.3))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

struct StatusRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundColor(.white)
        }
        .font(.subheadline)
    }
}

// MARK: - Models (Kept same but ensured availability)

struct SolarData {
    let sunspotCount: Int
    let solarFlux: String
    let kIndex: Int
    let activityLevel: String
    let solarWindSpeed: Int
    let solarWindDensity: Double
    
    static var current: SolarData {
        SolarData(
            sunspotCount: 85,
            solarFlux: "145 sfu",
            kIndex: 4,
            activityLevel: "Moderate",
            solarWindSpeed: 420,
            solarWindDensity: 6.2
        )
    }
}

struct SolarFlareEvent: Identifiable {
    let id = UUID()
    let classification: String
    let time: Date
    let impact: String
    let affectsEarth: Bool
    
    var color: Color {
        switch classification.first {
        case "X": return .red
        case "M": return .orange
        case "C": return .yellow
        default: return .gray
        }
    }
    
    static var recent: [SolarFlareEvent] {
        [
            SolarFlareEvent(
                classification: "M5.2",
                time: Date().addingTimeInterval(-3600),
                impact: "Medium Radio Blackout",
                affectsEarth: true
            ),
            SolarFlareEvent(
                classification: "C8.1",
                time: Date().addingTimeInterval(-7200),
                impact: "Minor Event",
                affectsEarth: false
            ),
            SolarFlareEvent(
                classification: "X1.3",
                time: Date().addingTimeInterval(-14400),
                impact: "Strong Blackout, GPS Issues",
                affectsEarth: true
            )
        ]
    }
}

#Preview {
    SolarActivityView()
}
