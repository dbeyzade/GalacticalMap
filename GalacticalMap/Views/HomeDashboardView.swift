import SwiftUI
import Combine
import Foundation
import CoreLocation

struct HomeDashboardView: View {
    @StateObject private var satelliteVM = SatelliteViewModel()
    @StateObject private var locationManager = LocationManager()
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var showLiveFromHome = false
    @State private var showHomeStream = false
    @State private var showISSLiveSheet = false
    @State private var showFavoritesSheet = false
    @State private var homeStreamURL: String = ""
    @State private var showEarthFromFavorite = false
    @State private var favoriteLocationCoord: CLLocationCoordinate2D? = nil
    @State private var showPremiumSheet = false
    @AppStorage("isSubscribed") private var isSubscribed = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView().ignoresSafeArea()
                GeometryReader { geo in
                    let isCompact = geo.size.width < 380
                    let columns = [
                        GridItem(.flexible(), spacing: isCompact ? 6 : 10),
                        GridItem(.flexible(), spacing: isCompact ? 6 : 10),
                        GridItem(.flexible(), spacing: isCompact ? 6 : 10)
                    ]
                    ScrollView {
                        VStack(spacing: isCompact ? 12 : 16) {
                            // Premium Banner
                            if isSubscribed {
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Premium Member")
                                            .font(.subheadline)
                                            .fontWeight(.bold)
                                            .foregroundColor(.white)
                                        Text("All features unlocked")
                                            .font(.caption2)
                                            .foregroundColor(.white.opacity(0.9))
                                    }
                                    Spacer()
                                    Image(systemName: "checkmark.seal.fill")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                }
                                .padding(.vertical, 8)
                                .padding(.horizontal, 12)
                                .background(
                                    LinearGradient(colors: [.orange.opacity(0.8), .yellow.opacity(0.8)], startPoint: .leading, endPoint: .trailing)
                                )
                                .cornerRadius(12)
                                .padding(.horizontal, isCompact ? 6 : 10)
                                .padding(.top, isCompact ? 6 : 10)
                            } else {
                                Button {
                                    showPremiumSheet = true
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Go Premium")
                                                .font(.subheadline)
                                                .fontWeight(.bold)
                                                .foregroundColor(.white)
                                            Text("Unlock all features")
                                                .font(.caption2)
                                                .foregroundColor(.white.opacity(0.8))
                                        }
                                        Spacer()
                                        Image(systemName: "crown.fill")
                                            .font(.headline)
                                            .foregroundColor(.yellow)
                                    }
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 12)
                                    .background(
                                        LinearGradient(colors: [.purple, .blue], startPoint: .leading, endPoint: .trailing)
                                    )
                                    .cornerRadius(12)
                                    .shadow(radius: 0)
                                }
                                .buttonStyle(.plain)
                                .padding(.horizontal, isCompact ? 6 : 10)
                                .padding(.top, isCompact ? 6 : 10)
                            }

                            // Üst kategori kartları (6 adet)
                            LazyVGrid(columns: columns, spacing: isCompact ? 12 : 16) {
                                FeatureCard(title: "Solar System", emoji: "🪐", color: .cyan, compact: isCompact) {
                                    AnyView(SolarSystemEyesView())
                                }
                                FeatureCard(title: "Visible Earth", emoji: "🌍", color: .green, compact: isCompact) {
                                    AnyView(NASAVisibleEarthView())
                                }
                                FeatureCard(title: "Sky Watcher", emoji: "👽", color: .indigo, compact: isCompact) {
                                    AnyView(SkyWatcherModeSelectionView())
                                }
                                FeatureCard(title: "Mission Control", emoji: "📟", color: .gray, compact: isCompact) {
                                    AnyView(MissionControlView())
                                }
                                FeatureCard(title: "Orbital Lab", emoji: "📐", color: .orange, compact: isCompact) {
                                    AnyView(OrbitalMechanicsView())
                                }
                                FeatureCard(title: "ISS 3D", emoji: "🌐", color: .indigo, compact: isCompact) {
                                    AnyView(ISS3DUserCodeView())
                                }
                                FeatureCard(title: "AR", emoji: "🧭", color: .green, compact: isCompact) { AnyView(ARSkyView()) }
                                FeatureCard(title: "3D Sky", emoji: "🧊", color: .blue, compact: isCompact) { AnyView(RealTime3DSkyView()) }
                                FeatureCard(title: "Star Map", emoji: "⭐", color: .yellow, compact: isCompact) {
                                    AnyView(StarMapView()
                                        .environmentObject(StarMapViewModel())
                                        .environmentObject(LocationManager()))
                                }
                                FeatureCard(title: "Observation", emoji: "🎥", color: .purple, compact: isCompact) { AnyView(SkyObservationView()) }
                                FeatureCard(title: "Meteor", emoji: "☄️", color: .orange, compact: isCompact) { AnyView(MeteorShowerView()) }
                                FeatureCard(title: "Moon", emoji: "🌕", color: .gray, compact: isCompact) { AnyView(MoonPhasesView()) }
                            }

                            // Ortadaki uydu slider (tek satır, sadece uydular)
                            HomeSatelliteTickerView(
                                satellites: satelliteVM.filteredSatellites,
                                compact: isCompact,
                                onTap: { sat in
                                    if sat.type == .iss {
                                        showISSLiveSheet = true
                                    } else if let u = sat.liveStreamURL, !u.isEmpty {
                                        homeStreamURL = u
                                        showHomeStream = true
                                    } else {
                                        satelliteVM.selectedSatellite = sat
                                        showLiveFromHome = true
                                    }
                                }
                            )
                            .padding(.vertical, isCompact ? 8 : 12)

                            // Alt kategori kartları (kalanlar)
                            LazyVGrid(columns: columns, spacing: isCompact ? 12 : 16) {
                                FeatureCard(title: "Sun", emoji: "☀️", color: .yellow, compact: isCompact) { AnyView(SolarActivityView()) }
                                FeatureCard(title: "Asteroids", emoji: "🪨", color: .purple, compact: isCompact) { AnyView(AsteroidTrackerView()) }
                                FeatureCard(title: "Mars Rover", emoji: "🚙", color: .red, compact: isCompact) { AnyView(MarsRoverView()) }
                                FeatureCard(title: "Signal Receiver", emoji: "📡", color: .teal, compact: isCompact) { AnyView(RadioAstronomyView()) }
                                FeatureCard(title: "Orbit", emoji: "🪐", color: .cyan, compact: isCompact) { AnyView(OrbitSimulatorView()) }
                                FeatureCard(title: "Station 3D", emoji: "🏗️", color: .indigo, compact: isCompact) { AnyView(SpaceStation3DTourView()) }
                                FeatureCard(title: "Favorites", emoji: "❤️", color: .pink, compact: isCompact) { AnyView(AdvancedFavoritesView()) }
                                FeatureCard(title: "Exoplanets", emoji: "🔭", color: .mint, compact: isCompact) { AnyView(ExoplanetExplorerView()) }
                                FeatureCard(title: "Freq. Catcher", emoji: "", color: .green, compact: isCompact, customIcon: AnyView(RadarSpinView(compact: isCompact))) { AnyView(FrequencyCatcherView()) }
                            }

                        }
                        .padding(isCompact ? 6 : 10)
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle("Home")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showFavoritesSheet = true
                    } label: {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                    }
                }
            }
            .sheet(isPresented: $showLiveFromHome) {
                LiveSatelliteView()
                    .environmentObject(satelliteVM)
                    .environmentObject(locationManager)
            }
            .sheet(isPresented: $showHomeStream) {
                LiveStreamView(streamURL: homeStreamURL)
            }
            .sheet(isPresented: $showISSLiveSheet) {
                ISSLiveView()
            }
            .sheet(isPresented: $showFavoritesSheet) {
                FavoritesQuickListView(
                    items: favoritesManager.favoriteItems.filter { $0.type == .location },
                    onSelect: { item in
                        if let coord = item.locationCoordinate?.clCoordinate {
                            favoriteLocationCoord = coord
                            showEarthFromFavorite = true
                        }
                    }
                )
            }
            .sheet(isPresented: $showEarthFromFavorite) {
                EarthEyesFix(initialCoordinate: favoriteLocationCoord)
                    .environmentObject(locationManager)
            }
            .sheet(isPresented: $showPremiumSheet) {
                PremiumSubscriptionView()
            }
            .task {
                await satelliteVM.loadSatellitesAbove(
                    latitude: 41.0082,
                    longitude: 28.9784
                )
                satelliteVM.startLiveTracking()
            }
        }
    }
}

struct FeatureCard: View {
    let title: String
    let emoji: String
    let color: Color
    let compact: Bool
    var customIcon: AnyView? = nil
    let destination: () -> AnyView
    
    var body: some View {
        NavigationLink(destination: destination()) {
            ZStack {
                // Background removed as requested
                // RoundedRectangle(cornerRadius: 12)
                //    .fill(LinearGradient(colors: [color.opacity(0.18), .black.opacity(0.2)], startPoint: .topLeading, endPoint: .bottomTrailing))
                
                // Minimal background for tap target
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.black.opacity(0.01))
                
                VStack(spacing: compact ? 6 : 8) {
                    if let customIcon = customIcon {
                        customIcon
                    } else {
                        Text(emoji)
                            .font(.system(size: compact ? 28 : 34))
                            .foregroundColor(.white)
                    }
                    Text(title)
                        .font(compact ? .caption : .subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(1)
                        .minimumScaleFactor(0.8)
                }
                .padding(compact ? 10 : 14)
            }
            .frame(height: compact ? 80 : 90)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct HomeSatelliteTickerView: View {
    let satellites: [Satellite]
    let compact: Bool
    let onTap: (Satellite) -> Void
    @State private var currentIndex = 0
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: compact ? 10 : 14) {
                    ForEach(satellites) { sat in
                        let emoji = emojiForSatellite(type: sat.type)
                        VStack(spacing: 6) {
                            Text(emoji)
                                .font(.system(size: compact ? 32 : 40))
                                .frame(width: compact ? 64 : 72, height: compact ? 64 : 72)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                            Text(sat.name)
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                                .lineLimit(1)
                                .frame(width: compact ? 64 : 72)
                        }
                        .id(sat.id)
                        .onTapGesture { onTap(sat) }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: compact ? 110 : 130)
            .onReceive(Timer.publish(every: 3.0, on: .main, in: .common).autoconnect()) { _ in
                guard !satellites.isEmpty else { return }
                currentIndex = (currentIndex + 1) % satellites.count
                withAnimation(.easeInOut(duration: 1.2)) {
                    proxy.scrollTo(satellites[currentIndex].id, anchor: .center)
                }
            }
        }
    }
    
    private func emojiForSatellite(type: SatelliteType) -> String {
        switch type {
        case .iss: return "🛰️"
        case .earth: return "🌍"
        case .weather: return "🌦️"
        case .communication: return "📡"
        case .scientific: return "🔭"
        case .navigation: return "🧭"
        case .military: return "🛡️"
        default: return "🛰️"
        }
    }
}

struct FavoritesQuickListView: View {
    let items: [FavoriteItem]
    var onSelect: ((FavoriteItem) -> Void)? = nil
    @Environment(\.dismiss) var dismiss
    var body: some View {
        NavigationStack {
            Group {
                if items.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "heart.slash")
                            .font(.system(size: 56))
                            .foregroundColor(.gray)
                        Text("No favorite locations")
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black)
                } else {
                    List(items) { item in
                        Button {
                            onSelect?(item)
                            dismiss()
                        } label: {
                            HStack {
                                Image(systemName: "mappin.and.ellipse")
                                    .foregroundColor(.cyan)
                                VStack(alignment: .leading) {
                                    Text(item.title)
                                        .foregroundColor(.white)
                                    if let sub = item.subtitle {
                                        Text(sub)
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 6)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .background(Color.black)
                }
            }
            .navigationTitle("Favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct RadarSpinView: View {
    let compact: Bool
    @State private var rotation: Double = 0
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(Color.green.opacity(0.5), lineWidth: 1.5)
            
            // Scanning line
            Rectangle()
                .fill(LinearGradient(colors: [.green, .clear], startPoint: .top, endPoint: .bottom))
                .frame(width: 2, height: compact ? 8 : 10)
                .offset(y: -(compact ? 4 : 5))
                .rotationEffect(.degrees(rotation))
            
            // Center point
            Circle()
                .fill(Color.green)
                .frame(width: 3, height: 3)
        }
        .frame(width: compact ? 24 : 32, height: compact ? 24 : 32)
        .onAppear {
            withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}
