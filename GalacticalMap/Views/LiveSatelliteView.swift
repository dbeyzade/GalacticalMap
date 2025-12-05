//
//  LiveSatelliteView.swift
//  GalacticalMap
//
//  Canlı uydu izleme görünümü - NASA ve Roscosmos
//

import SwiftUI
import MapKit

struct LiveSatelliteView: View {
    @EnvironmentObject var viewModel: SatelliteViewModel
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedOrigin: SatelliteOrigin? = nil
    @State private var showingLiveStream = false
    @State private var liveStreamURL: String?
    @State private var showingFilters = false
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 20, longitude: 0),
        span: MKCoordinateSpan(latitudeDelta: 180, longitudeDelta: 360)
    )
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Harita görünümü
                Map(coordinateRegion: $region, annotationItems: viewModel.filteredSatellites) { satellite in
                    MapAnnotation(coordinate: satellite.coordinate) {
                        SatelliteMarker(satellite: satellite)
                            .onTapGesture {
                                viewModel.selectedSatellite = satellite
                            }
                    }
                }
                .ignoresSafeArea()
                
                VStack {
                    // Üst bilgi paneli
                    LiveSatelliteHeader(
                        showingFilters: $showingFilters,
                        selectedOrigin: $selectedOrigin
                    )
                    .padding()
                    
                    Spacer()
                    
                    // Alt uydu listesi
                    SatelliteCarousel(
                        satellites: viewModel.filteredSatellites,
                        onSatelliteSelected: { satellite in
                            viewModel.selectedSatellite = satellite
                            withAnimation {
                                region.center = satellite.coordinate
                            }
                        },
                        onLiveStreamTapped: { url in
                            liveStreamURL = url
                            showingLiveStream = true
                        }
                    )
                }
                
                // Seçili uydu detay paneli
                if let satellite = viewModel.selectedSatellite {
                    VStack {
                        Spacer()
                        SatelliteDetailPanel(
                            satellite: satellite,
                            onClose: { viewModel.selectedSatellite = nil },
                            onLiveStream: { url in
                                liveStreamURL = url
                                showingLiveStream = true
                            }
                        )
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                    }
                }
            }
            .navigationTitle("Live Satellite Tracking")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingFilters.toggle()
                    } label: {
                        Image(systemName: "line.3.horizontal.decrease.circle")
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showingFilters) {
                SatelliteFilterView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingLiveStream) {
                if let url = liveStreamURL {
                    LiveStreamView(streamURL: url)
                }
            }
            .task {
                await viewModel.loadSatellitesAbove(
                    latitude: locationManager.coordinate.latitude,
                    longitude: locationManager.coordinate.longitude
                )
                viewModel.startLiveTracking()
            }
        }
    }
}

struct SatelliteMarker: View {
    let satellite: Satellite
    
    var body: some View {
        VStack(spacing: 2) {
            Image(systemName: satellite.type == .iss ? "airport.extreme.tower" : "antenna.radiowaves.left.and.right")
                .font(.system(size: 20))
                .foregroundColor(satellite.origin == .nasa ? .blue : .red)
                .shadow(color: satellite.origin == .nasa ? .blue : .red, radius: 5)
            
            Text(satellite.name)
                .font(.caption2)
                .foregroundColor(.white)
                .padding(2)
                .background(Color.black.opacity(0.7))
                .cornerRadius(4)
        }
    }
}

struct LiveSatelliteHeader: View {
    @Binding var showingFilters: Bool
    @Binding var selectedOrigin: SatelliteOrigin?
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("LIVE SATELLITE TRACKING")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    
                    Text("Real-Time Positions")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                // Canlı gösterge
                HStack(spacing: 6) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 8, height: 8)
                        .overlay(
                            Circle()
                                .stroke(Color.red, lineWidth: 2)
                                .scaleEffect(1.5)
                                .opacity(0.5)
                        )
                    
                    Text("LIVE")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(Color.black.opacity(0.7))
                .cornerRadius(20)
            }
            
            // Hızlı filtreler
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    FilterChip(title: "Tümü", isSelected: selectedOrigin == nil) {
                        selectedOrigin = nil
                    }
                    
                    FilterChip(title: "🇺🇸 NASA", isSelected: selectedOrigin == .nasa) {
                        selectedOrigin = .nasa
                    }
                    
                    FilterChip(title: "🇷🇺 Roscosmos", isSelected: selectedOrigin == .roscosmos) {
                        selectedOrigin = .roscosmos
                    }
                    
                    FilterChip(title: "🇪🇺 ESA", isSelected: selectedOrigin == .esa) {
                        selectedOrigin = .esa
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.cyan : Color.white.opacity(0.2))
                .foregroundColor(isSelected ? .black : .white)
                .cornerRadius(20)
        }
    }
}

struct SatelliteCarousel: View {
    let satellites: [Satellite]
    let onSatelliteSelected: (Satellite) -> Void
    let onLiveStreamTapped: (String) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 16) {
                ForEach(satellites) { satellite in
                    SatelliteCard(
                        satellite: satellite,
                        onTap: { onSatelliteSelected(satellite) },
                        onLiveStream: { 
                            if let url = satellite.liveStreamURL {
                                onLiveStreamTapped(url)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
        .frame(height: 160)
        .padding(.bottom)
    }
}

struct SatelliteCard: View {
    let satellite: Satellite
    let onTap: () -> Void
    let onLiveStream: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(satellite.origin.rawValue)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
                
                Spacer()
                
                if satellite.liveStreamURL != nil {
                    Button(action: onLiveStream) {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 6, height: 6)
                            Text("CANLI")
                                .font(.system(size: 9))
                                .fontWeight(.bold)
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.red.opacity(0.3))
                        .cornerRadius(10)
                    }
                }
            }
            
            Text(satellite.name)
                .font(.headline)
                .foregroundColor(.white)
                .lineLimit(2)
            
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Yükseklik")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(Int(satellite.altitude)) km")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Hız")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(Int(satellite.velocity)) km/h")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.green)
                }
            }
        }
        .padding()
        .frame(width: 200)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(satellite.origin == .nasa ? Color.blue : Color.red, lineWidth: 1)
        )
        .onTapGesture(perform: onTap)
    }
}

struct SatelliteDetailPanel: View {
    let satellite: Satellite
    let onClose: () -> Void
    let onLiveStream: (String) -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            // Başlık
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(satellite.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text(satellite.origin.rawValue)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            
            // Detaylar
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                InfoBox(title: "Altitude", value: "\(Int(satellite.altitude)) km", color: .cyan)
                InfoBox(title: "Speed", value: "\(Int(satellite.velocity)) km/h", color: .green)
                InfoBox(title: "Azimuth", value: "\(Int(satellite.azimuth))°", color: .orange)
                InfoBox(title: "Elevation", value: "\(Int(satellite.elevation))°", color: .purple)
            }
            
            // Açıklama
            Text(satellite.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            
            // Canlı yayın butonu
            if let streamURL = satellite.liveStreamURL {
                Button {
                    onLiveStream(streamURL)
                } label: {
                    HStack {
                        Circle()
                            .fill(Color.red)
                            .frame(width: 12, height: 12)
                        Text("WATCH LIVE")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(.ultraThickMaterial)
        .cornerRadius(24)
        .padding()
    }
}

struct InfoBox: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct SatelliteFilterView: View {
    @ObservedObject var viewModel: SatelliteViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Origin") {
                    ForEach(SatelliteOrigin.allCases, id: \.self) { origin in
                        Button {
                            viewModel.filterOrigin = viewModel.filterOrigin == origin ? nil : origin
                        } label: {
                            HStack {
                                Text(origin.rawValue)
                                Spacer()
                                if viewModel.filterOrigin == origin {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.cyan)
                                }
                            }
                        }
                    }
                }
                
                Section("Type") {
                    ForEach(SatelliteType.allCases, id: \.self) { type in
                        Button {
                            viewModel.filterType = viewModel.filterType == type ? nil : type
                        } label: {
                            HStack {
                                Text(type.rawValue)
                                Spacer()
                                if viewModel.filterType == type {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.cyan)
                                }
                            }
                        }
                    }
                }
                
                Section("Visibility") {
                    Toggle("Only Visible Satellites", isOn: $viewModel.showOnlyVisible)
                    Toggle("Only Favorites", isOn: $viewModel.showOnlyFavorites)
                }
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    LiveSatelliteView()
        .environmentObject(SatelliteViewModel())
        .environmentObject(LocationManager())
}
