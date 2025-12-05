//
//  SupernovaAlertView.swift
//  GalacticalMap
//
//  Supernova keşif ve alarm sistemi
//

import SwiftUI

struct SupernovaAlertView: View {
    @State private var supernovae: [Supernova] = Supernova.recent
    @State private var alerts: [SupernovaAlert] = SupernovaAlert.active
    @State private var selectedSN: Supernova?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Active Alerts
                    if !alerts.isEmpty {
                        ActiveAlertsSection(alerts: alerts)
                    }
                    
                    // Recent Discoveries
                    VStack(alignment: .leading, spacing: 15) {
                        Text("🌟 Son Keşifler")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(supernovae) { sn in
                            SupernovaCard(supernova: sn)
                                .onTapGesture {
                                    selectedSN = sn
                                }
                        }
                    }
                    
                    // About Supernovae
                    InfoSection()
                }
                .padding()
            }
            .navigationTitle("💥 Supernova Tracking")
            .background(Color.black.ignoresSafeArea())
            .sheet(item: $selectedSN) { sn in
                SupernovaDetailView(supernova: sn)
            }
        }
    }
}

struct ActiveAlertsSection: View {
    let alerts: [SupernovaAlert]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: "bell.badge.fill")
                    .foregroundColor(.red)
                Text("Active Alerts")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ForEach(alerts) { alert in
                HStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                    
                    VStack(alignment: .leading) {
                        Text(alert.title)
                            .foregroundColor(.white)
                            .fontWeight(.medium)
                        Text(alert.message)
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Spacer()
                    
                    Text(alert.time, style: .relative)
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
                .padding()
                .background(Color.red.opacity(0.1))
                .cornerRadius(10)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

struct SupernovaCard: View {
    let supernova: Supernova
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(supernova.name)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(supernova.galaxy)
                        .font(.caption)
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                VStack {
                    Text(supernova.type.icon)
                        .font(.system(size: 40))
                    Text(supernova.type.rawValue)
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
            }
            
            Divider()
            
            HStack(spacing: 15) {
                InfoBadge(icon: "📅", value: supernova.discoveryDate.formatted(date: .abbreviated, time: .omitted))
                InfoBadge(icon: "📏", value: supernova.distance)
                InfoBadge(icon: "✨", value: String(format: "Mag %.1f", supernova.peakMagnitude))
            }
            
            if supernova.isVisible {
                HStack {
                    Image(systemName: "eye.fill")
                        .foregroundColor(.green)
                    Text("Observable with a telescope")
                        .font(.caption)
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(Color.green.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(
            LinearGradient(
                colors: [Color.orange.opacity(0.2), Color.red.opacity(0.1)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

struct InfoBadge: View {
    let icon: String
    let value: String
    
    var body: some View {
        HStack(spacing: 5) {
            Text(icon)
                .font(.caption)
            Text(value)
                .font(.caption)
                .foregroundColor(.white)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct InfoSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ℹ️ What is a Supernova?")
                .font(.headline)
                .foregroundColor(.white)
            
            Text("A supernova is a tremendous explosion that occurs at the end of a massive star's life. During the explosion, the star can shine as brightly as an entire galaxy for weeks or months.")
                .font(.caption)
                .foregroundColor(.gray)
            
            VStack(alignment: .leading, spacing: 8) {
                TypeRow(type: "Type Ia", description: "Explosion of white dwarf stars")
                TypeRow(type: "Type II", description: "Collapse of massive stars")
                TypeRow(type: "Hypernova", description: "Ultra-powerful explosion of very massive stars")
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

struct TypeRow: View {
    let type: String
    let description: String
    
    var body: some View {
        HStack {
            Text("•")
                .foregroundColor(.orange)
            VStack(alignment: .leading) {
                Text(type)
                    .foregroundColor(.white)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
        }
    }
}

struct SupernovaDetailView: View {
    let supernova: Supernova
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(supernova.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(supernova.galaxy)
                            .font(.title3)
                            .foregroundColor(.cyan)
                    }
                    
                    Divider()
                    
                    // Data
                    VStack(alignment: .leading, spacing: 15) {
                        Text("📊 Data")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        DetailDataRow(label: "Type", value: supernova.type.rawValue)
                        DetailDataRow(label: "Discovery Date", value: supernova.discoveryDate.formatted())
                        DetailDataRow(label: "Distance", value: supernova.distance)
                        DetailDataRow(label: "Peak Magnitude", value: String(format: "%.1f mag", supernova.peakMagnitude))
                        DetailDataRow(label: "Coordinates", value: supernova.coordinates)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    // Description
                    VStack(alignment: .leading, spacing: 10) {
                        Text("📝 Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(supernova.description)
                            .font(.body)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct DetailDataRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.cyan)
        }
    }
}

// MARK: - Models

struct Supernova: Identifiable {
    let id = UUID()
    let name: String
    let galaxy: String
    let type: SupernovaType
    let discoveryDate: Date
    let distance: String
    let peakMagnitude: Double
    let coordinates: String
    let isVisible: Bool
    let description: String
    
    enum SupernovaType: String {
        case typeIa = "Type Ia"
        case typeII = "Type II"
        case typeIb = "Type Ib"
        case typeIc = "Type Ic"
        case hypernova = "Hypernova"
        
        var icon: String {
            switch self {
            case .typeIa: return "💫"
            case .typeII: return "💥"
            case .typeIb, .typeIc: return "✨"
            case .hypernova: return "🌟"
            }
        }
    }
    
    static var recent: [Supernova] {
        [
            Supernova(
                name: "SN 2024abc",
                galaxy: "NGC 4383",
                type: .typeIa,
                discoveryDate: Date().addingTimeInterval(-86400 * 5),
                distance: "55 million light years",
                peakMagnitude: 12.4,
                coordinates: "RA 12h 25m 24s, Dec +16° 28' 12\"",
                isVisible: true,
                description: "Discovered 5 days ago, this Type Ia supernova was observed in the spiral galaxy NGC 4383. Visible with medium-size telescopes."
            ),
            Supernova(
                name: "SN 2023ixf",
                galaxy: "M101 (Pinwheel Galaxy)",
                type: .typeII,
                discoveryDate: Date().addingTimeInterval(-86400 * 180),
                distance: "21 million light years",
                peakMagnitude: 10.9,
                coordinates: "RA 14h 03m 38s, Dec +54° 18' 42\"",
                isVisible: true,
                description: "The brightest supernova of 2023. Occurred in the M101 galaxy and is easily observable with amateur telescopes."
            ),
            Supernova(
                name: "SN 2024xyz",
                galaxy: "NGC 2207",
                type: .hypernova,
                discoveryDate: Date().addingTimeInterval(-86400 * 30),
                distance: "80 million light years",
                peakMagnitude: 13.2,
                coordinates: "RA 06h 16m 22s, Dec -21° 22' 23\"",
                isVisible: false,
                description: "A rare hypernova event. Formed by the collapse of a very massive star and likely created a black hole."
            )
        ]
    }
}

struct SupernovaAlert: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let time: Date
    let priority: Priority
    
    enum Priority {
        case high, medium, low
    }
    
    static var active: [SupernovaAlert] {
        [
            SupernovaAlert(
                title: "New Discovery: SN 2024abc",
                message: "A bright supernova has been detected in NGC 4383",
                time: Date().addingTimeInterval(-3600 * 2),
                priority: .high
            )
        ]
    }
}

#Preview {
    SupernovaAlertView()
}
