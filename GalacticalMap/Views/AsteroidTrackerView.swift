//
//  AsteroidTrackerView.swift
//  GalacticalMap
//
//  Göktaşı (NEO) takip sistemi
//

import SwiftUI

struct AsteroidTrackerView: View {
    @State private var asteroids: [NearEarthObject] = NearEarthObject.database
    @State private var selectedAsteroid: NearEarthObject?
    @State private var showOnlyHazardous = false
    
    var filteredAsteroids: [NearEarthObject] {
        if showOnlyHazardous {
            return asteroids.filter { $0.isPotentiallyHazardous }
        }
        return asteroids
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Hazard Toggle
                HStack {
                    Toggle("🚨 Only Hazardous", isOn: $showOnlyHazardous)
                        .tint(.red)
                }
                .padding()
                .background(.ultraThinMaterial)
                
                ScrollView {
                    VStack(spacing: 15) {
                        // Upcoming Close Approaches
                        ForEach(filteredAsteroids) { asteroid in
                            AsteroidCard(asteroid: asteroid)
                                .onTapGesture {
                                    selectedAsteroid = asteroid
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("🛸 Asteroid Tracking")
            .background(Color.black.ignoresSafeArea())
            .sheet(item: $selectedAsteroid) { asteroid in
                AsteroidDetailView(asteroid: asteroid)
            }
        }
    }
}

struct AsteroidCard: View {
    let asteroid: NearEarthObject
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(asteroid.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("ID: \(asteroid.id)")
                        .font(.caption2)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if asteroid.isPotentiallyHazardous {
                    Text("⚠️ HAZARDOUS")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                        .padding(5)
                        .background(Color.red.opacity(0.2))
                        .cornerRadius(5)
                }
            }
            
            Divider()
            
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Label("Approach", systemImage: "calendar")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(asteroid.closeApproachDate, style: .date)
                        .foregroundColor(.cyan)
                        .fontWeight(.medium)
                }
                
                VStack(alignment: .leading, spacing: 5) {
                    Label("Distance", systemImage: "arrow.left.and.right")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(asteroid.missDistance)
                        .foregroundColor(.orange)
                        .fontWeight(.medium)
                }
            }
            
            HStack(spacing: 20) {
                DataBadge(icon: "📏", label: "Diameter", value: asteroid.diameter)
                DataBadge(icon: "⚡", label: "Speed", value: asteroid.velocity)
            }
        }
        .padding()
        .background(
            asteroid.isPotentiallyHazardous ?
            LinearGradient(colors: [Color.red.opacity(0.2), Color.orange.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing) :
            LinearGradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(15)
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(asteroid.isPotentiallyHazardous ? Color.red.opacity(0.5) : Color.clear, lineWidth: 2)
        )
    }
}

struct DataBadge: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(icon)
            VStack(alignment: .leading) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.gray)
                Text(value)
                    .font(.caption)
                    .foregroundColor(.white)
            }
        }
        .padding(8)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
    }
}

struct AsteroidDetailView: View {
    let asteroid: NearEarthObject
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    VStack(alignment: .leading, spacing: 10) {
                        Text(asteroid.name)
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if asteroid.isPotentiallyHazardous {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                        Text("Potentially Hazardous Asteroid (PHA)")
                            }
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.red.opacity(0.2))
                            .cornerRadius(10)
                        }
                    }
                    
                    Divider()
                    
                    // Orbital Data
                    VStack(alignment: .leading, spacing: 10) {
                        Text("📊 Orbital Data")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        AsteroidDetailRow(label: "Approach Date", value: asteroid.closeApproachDate.formatted())
                        AsteroidDetailRow(label: "Closest Approach", value: asteroid.missDistance)
                        AsteroidDetailRow(label: "Relative Velocity", value: asteroid.velocity)
                        AsteroidDetailRow(label: "Diameter", value: asteroid.diameter)
                        AsteroidDetailRow(label: "Magnitude", value: asteroid.magnitude)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    
                    // Additional Info
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ℹ️ Additional Information")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text("This asteroid is tracked by NASA's Near-Earth Object (NEO) program. All approaching bodies are continuously monitored and potential hazards are assessed.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
                .padding()
            }
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct AsteroidDetailRow: View {
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

// MARK: - Model

struct NearEarthObject: Identifiable {
    let id: String
    let name: String
    let closeApproachDate: Date
    let missDistance: String
    let velocity: String
    let diameter: String
    let magnitude: String
    let isPotentiallyHazardous: Bool
    
    static var database: [NearEarthObject] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            NearEarthObject(
                id: "2023 DW",
                name: "2023 DW",
                closeApproachDate: calendar.date(byAdding: .day, value: 15, to: today)!,
                missDistance: "3.2 milyon km",
                velocity: "24.5 km/s",
                diameter: "~50 m",
                magnitude: "24.2",
                isPotentiallyHazardous: true
            ),
            NearEarthObject(
                id: "99942",
                name: "Apophis",
                closeApproachDate: calendar.date(byAdding: .day, value: 800, to: today)!,
                missDistance: "31,000 km",
                velocity: "7.4 km/s",
                diameter: "~340 m",
                magnitude: "19.7",
                isPotentiallyHazardous: true
            ),
            NearEarthObject(
                id: "2024 AB",
                name: "2024 AB",
                closeApproachDate: calendar.date(byAdding: .day, value: 5, to: today)!,
                missDistance: "1.5 milyon km",
                velocity: "18.2 km/s",
                diameter: "~25 m",
                magnitude: "26.1",
                isPotentiallyHazardous: false
            ),
            NearEarthObject(
                id: "101955",
                name: "Bennu",
                closeApproachDate: calendar.date(byAdding: .day, value: 60, to: today)!,
                missDistance: "0.12 AU",
                velocity: "8.1 km/s",
                diameter: "~490 m",
                magnitude: "20.9",
                isPotentiallyHazardous: true
            ),
            NearEarthObject(
                id: "2024 CD",
                name: "2024 CD",
                closeApproachDate: calendar.date(byAdding: .day, value: 30, to: today)!,
                missDistance: "4.8 milyon km",
                velocity: "31.2 km/s",
                diameter: "~100 m",
                magnitude: "22.5",
                isPotentiallyHazardous: false
            )
        ]
    }
}

#Preview {
    AsteroidTrackerView()
}
