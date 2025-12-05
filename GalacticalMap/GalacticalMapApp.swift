//
//  GalacticalMapApp.swift
//  GalacticalMap
//
//  Created on 08/11/2025.
//

import SwiftUI

@main
struct GalacticalMapApp: App {
    
    @StateObject private var locationManager = LocationManager()
    @StateObject private var satelliteViewModel = SatelliteViewModel()
    @StateObject private var starMapViewModel = StarMapViewModel()
    @StateObject private var anomalyViewModel = AnomalyViewModel()
    
    @AppStorage("launchCount") private var launchCount = 0
    @AppStorage("isSubscribed") private var isSubscribed = false
    @State private var showForcedPremium = false
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(locationManager)
                .environmentObject(satelliteViewModel)
                .environmentObject(starMapViewModel)
                .environmentObject(anomalyViewModel)
                .onAppear {
                    locationManager.requestPermission()
                    // Configure Google Street View API key securely from Info.plist / env / UserDefaults
                    if let key = Bundle.main.object(forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY") as? String, !key.isEmpty {
                        StreetViewConfig.apiKey = key
                    } else if let envKey = ProcessInfo.processInfo.environment["GOOGLE_MAPS_API_KEY"], !envKey.isEmpty {
                        StreetViewConfig.apiKey = envKey
                    } else if let saved = UserDefaults.standard.string(forKey: "GOOGLE_MAPS_API_KEY"), !saved.isEmpty {
                        StreetViewConfig.apiKey = saved
                    }
                    
                    // Launch count logic
                    if !isSubscribed {
                        launchCount += 1
                        if launchCount > 10 {
                            showForcedPremium = true
                        }
                    }
                }
                .fullScreenCover(isPresented: $showForcedPremium) {
                    PremiumSubscriptionView(isForced: true)
                }
        }
    }
}

struct MainAppTabView: View {
    @State private var stars: [SimpleStarData] = SimpleStarData.sampleStars
    @State private var satellites: [SimpleSatelliteData] = SimpleSatelliteData.sampleSatellites
    @State private var favorites: [String] = []
    
    var body: some View {
        TabView {
            // Star Map
            NavigationStack {
                List(stars) { star in
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                        VStack(alignment: .leading) {
                            Text(star.name)
                                .font(.headline)
                                .foregroundColor(.white)
                        Text("Magnitude: \(star.magnitude, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                        Spacer()
                        Button {
                            toggleFavorite(star.name)
                        } label: {
                            Image(systemName: favorites.contains(star.name) ? "heart.fill" : "heart")
                                .foregroundColor(.red)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.black)
                .navigationTitle("Star Map")
                .scrollContentBackground(.hidden)
            }
            .tabItem {
                Label("Gökyüzü", systemImage: "star.fill")
            }
            
            // Satellite Tracking
            NavigationStack {
                List(satellites) { satellite in
                    HStack {
                        Image(systemName: "antenna.radiowaves.left.and.right")
                            .foregroundColor(.cyan)
                        VStack(alignment: .leading) {
                            Text(satellite.name)
                                .font(.headline)
                                .foregroundColor(.white)
                        Text("Orbit: \(satellite.altitude) km")
                            .font(.caption)
                            .foregroundColor(.gray)
                        }
                    }
                }
                .listStyle(.plain)
                .background(Color.black)
                .navigationTitle("Satellite Tracking")
                .scrollContentBackground(.hidden)
            }
            .tabItem {
                Label("Uydu", systemImage: "antenna.radiowaves.left.and.right")
            }
            
            // Favorites
            NavigationStack {
                Group {
                    if favorites.isEmpty {
                        VStack {
                            Image(systemName: "heart.slash")
                                .font(.system(size: 60))
                                .foregroundColor(.gray)
                            Text("No favorites yet")
                                .foregroundColor(.white)
                                .padding()
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .background(Color.black)
                    } else {
                        List(favorites, id: \.self) { favorite in
                            HStack {
                                Image(systemName: "heart.fill")
                                    .foregroundColor(.red)
                                Text(favorite)
                                    .foregroundColor(.white)
                            }
                        }
                        .listStyle(.plain)
                        .background(Color.black)
                        .scrollContentBackground(.hidden)
                    }
                }
                .navigationTitle("Favorites")
            }
            .tabItem {
                Label("Favoriler", systemImage: "heart.fill")
            }
            
            // Settings
            NavigationStack {
                List {
                    Section("Features") {
                        FeatureRow(icon: "star.fill", title: "Star Map", description: "\(stars.count) stars")
                        FeatureRow(icon: "antenna.radiowaves.left.and.right", title: "Satellite Tracking", description: "\(satellites.count) satellites")
                        FeatureRow(icon: "heart.fill", title: "Favorites", description: "\(favorites.count) items")
                    }
                    
                    Section("App") {
                        HStack {
                            Text("Versiyon")
                            Spacer()
                            Text("1.0")
                                .foregroundColor(.gray)
                        }
                        HStack {
                            Text("Platform")
                            Spacer()
                            Text("iOS 18.0+")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .navigationTitle("Settings")
                .scrollContentBackground(.hidden)
                .background(Color.black)
            }
            .tabItem {
                Label("Settings", systemImage: "gear")
            }
        }
        .accentColor(.cyan)
    }
    
    func toggleFavorite(_ name: String) {
        if let index = favorites.firstIndex(of: name) {
            favorites.remove(at: index)
        } else {
            favorites.append(name)
        }
    }
}

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(.cyan)
            VStack(alignment: .leading) {
                Text(title)
                    .foregroundColor(.white)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
        }
    }
}

// MARK: - Data Models

struct SimpleStarData: Identifiable {
    let id = UUID()
    let name: String
    let magnitude: Double
    
    static var sampleStars: [SimpleStarData] {
        [
            SimpleStarData(name: "Sirius", magnitude: -1.46),
            SimpleStarData(name: "Canopus", magnitude: -0.72),
            SimpleStarData(name: "Arcturus", magnitude: -0.05),
            SimpleStarData(name: "Vega", magnitude: 0.03),
            SimpleStarData(name: "Rigel", magnitude: 0.12),
            SimpleStarData(name: "Betelgeuse", magnitude: 0.42),
            SimpleStarData(name: "Altair", magnitude: 0.77),
            SimpleStarData(name: "Aldebaran", magnitude: 0.85),
            SimpleStarData(name: "Spica", magnitude: 1.04),
            SimpleStarData(name: "Polaris", magnitude: 1.98)
        ]
    }
}

struct SimpleSatelliteData: Identifiable {
    let id = UUID()
    let name: String
    let altitude: Int
    
    static var sampleSatellites: [SimpleSatelliteData] {
        [
            SimpleSatelliteData(name: "ISS (Uluslararası Uzay İstasyonu)", altitude: 408),
            SimpleSatelliteData(name: "Hubble Uzay Teleskopu", altitude: 547),
            SimpleSatelliteData(name: "Türksat 5A", altitude: 35786),
            SimpleSatelliteData(name: "Starlink-1", altitude: 550),
            SimpleSatelliteData(name: "GPS III SV01", altitude: 20200),
            SimpleSatelliteData(name: "Tiangong (Çin Uzay İstasyonu)", altitude: 390),
            SimpleSatelliteData(name: "GOES-16", altitude: 35786),
            SimpleSatelliteData(name: "Sentinel-2A", altitude: 786)
        ]
    }
}

struct MainAppView: View {
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack {
            // Cosmic background
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                // Star Map
                SimpleStarView()
                    .tag(0)
                    .tabItem {
                        Label("Gökyüzü", systemImage: "star.fill")
                    }
                
                // Satellite Tracking
                SimpleSatelliteView()
                    .tag(1)
                    .tabItem {
                        Label("Uydu", systemImage: "antenna.radiowaves.left.and.right")
                    }
                
                // Saved Items
                SimpleSavedView()
                    .tag(2)
                    .tabItem {
                        Label("Kaydedilenler", systemImage: "heart.fill")
                    }
                
                // Anomalies
                SimpleAnomalyView()
                    .tag(3)
                    .tabItem {
                        Label("Anomaliler", systemImage: "exclamationmark.circle.fill")
                    }
                
                // Settings/Info
                SimpleSettingsView()
                    .tag(4)
                    .tabItem {
                        Label("Ayarlar", systemImage: "gear")
                    }
            }
            .accentColor(.cyan)
        }
    }
}

// MARK: - Simple Views

struct SimpleStarView: View {
    var body: some View {
        VStack {
            Text("⭐ Yıldız Haritası")
                .font(.title2)
                .foregroundColor(.white)
            Spacer()
            Text("Gökyüzündeki yıldızları keşfedin")
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .padding()
    }
}

struct SimpleSatelliteView: View {
    var body: some View {
        VStack {
            Text("🛰️ Uydu Takibi")
                .font(.title2)
                .foregroundColor(.white)
            Spacer()
            Text("Canlı uydu konumları")
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .padding()
    }
}

struct SimpleSavedView: View {
    var body: some View {
        VStack {
            Text("❤️ Kaydedilenler")
                .font(.title2)
                .foregroundColor(.white)
            Spacer()
            Text("Favorileriniz burada gösterilecek")
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .padding()
    }
}

struct SimpleAnomalyView: View {
    var body: some View {
        VStack {
            Text("⚠️ Anomaliler")
                .font(.title2)
                .foregroundColor(.white)
            Spacer()
            Text("Uzay anomalileri")
                .foregroundColor(.white.opacity(0.7))
            Spacer()
        }
        .padding()
    }
}

struct SimpleSettingsView: View {
    var body: some View {
        VStack {
            Text("GalacticalMap v1.0")
                .font(.title)
                .foregroundColor(.white)
            
            Text("Profesyonel Uzay Gözlem Platformu")
                .foregroundColor(.white.opacity(0.7))
                .padding()
            
            Spacer()
            
            VStack(alignment: .leading, spacing: 10) {
                Text("📍 Features:")
                    .font(.headline)
                    .foregroundColor(.cyan)
                
                Text("• Satellite Tracking")
                Text("• Star Map")
                Text("• AR Sky")
                Text("• Telescope Control")
                Text("• Spectroscopy Analysis")
            }
            .foregroundColor(.white.opacity(0.8))
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
            
            Spacer()
        }
        .padding()
    }
}
