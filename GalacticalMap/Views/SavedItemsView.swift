//
//  SavedItemsView.swift
//  GalacticalMap
//
//  Kaydedilmiş yıldızlar, anomaliler ve gözlemler
//

import SwiftUI

struct SavedItemsView: View {
    @EnvironmentObject var starViewModel: StarMapViewModel
    @EnvironmentObject var anomalyViewModel: AnomalyViewModel
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Segmented control
                    Picker("Category", selection: $selectedTab) {
                        Text("Stars").tag(0)
                        Text("Anomalies").tag(1)
                        Text("Observations").tag(2)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    .background(.ultraThinMaterial)
                    
                    // İçerik
                    TabView(selection: $selectedTab) {
                        SavedStarsTab(viewModel: starViewModel)
                            .tag(0)
                        
                        SavedAnomaliesTab(viewModel: anomalyViewModel)
                            .tag(1)
                        
                        ObservationsTab()
                            .tag(2)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Saved Items")
        }
    }
}

struct SavedStarsTab: View {
    @ObservedObject var viewModel: StarMapViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.savedStars.isEmpty {
                        EmptyStateView(
                            icon: "star.fill",
                            title: "No Saved Stars Yet",
                            message: "Save your favorite stars from the star map"
                        )
                } else {
                    ForEach(viewModel.savedStars) { star in
                        NavigationLink(destination: StarDetailView(star: star, viewModel: viewModel)) {
                            SavedStarCard(star: star)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
}

struct SavedStarCard: View {
    let star: Star
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(star.commonName ?? star.name)
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(star.constellation.rawValue)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                Spacer()
                
                ZStack {
                    Circle()
                        .fill(starColor(star))
                        .frame(width: 40, height: 40)
                        .blur(radius: 8)
                    
                    Image(systemName: "star.fill")
                        .foregroundColor(starColor(star))
                }
            }
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Observation Count")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.6))
                    Text("\(star.observationCount)")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                }
                
                Spacer()
                
                if let date = star.savedDate {
                    VStack(alignment: .trailing, spacing: 4) {
                        Text("Saved Date")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                        Text(date, style: .date)
                            .font(.caption)
                            .fontWeight(.semibold)
                            .foregroundColor(.green)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private func starColor(_ star: Star) -> Color {
        switch star.spectralType.first {
        case "O", "B": return .blue
        case "A": return .cyan
        case "F", "G": return .yellow
        case "K": return .orange
        case "M": return .red
        default: return .white
        }
    }
}

struct SavedAnomaliesTab: View {
    @ObservedObject var viewModel: AnomalyViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if viewModel.savedAnomalies.isEmpty {
                        EmptyStateView(
                            icon: "sparkles",
                            title: "No Saved Anomalies Yet",
                            message: "Save interesting sky objects from the Anomalies tab"
                        )
                } else {
                    ForEach(viewModel.savedAnomalies) { anomaly in
                        NavigationLink(destination: AnomalyDetailView(anomaly: anomaly, viewModel: viewModel)) {
                            SavedAnomalyCard(anomaly: anomaly)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
}

struct SavedAnomalyCard: View {
    let anomaly: SkyAnomaly
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradientForType(anomaly.type))
                    .frame(width: 80, height: 80)
                
                Image(systemName: iconForType(anomaly.type))
                    .font(.title)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            VStack(alignment: .leading, spacing: 6) {
                Text(anomaly.commonName ?? anomaly.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(anomaly.catalogNumber)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                Text(anomaly.type.rawValue)
                    .font(.caption2)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(colorForType(anomaly.type))
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private func iconForType(_ type: AnomalyType) -> String {
        switch type {
        case .nebula, .planetaryNebula, .darkNebula: return "cloud.fill"
        case .galaxy: return "circle.hexagongrid.fill"
        case .supernova: return "burst.fill"
        case .blackHole: return "circle.fill"
        case .quasar: return "light.beacon.max.fill"
        case .pulsar: return "waveform.path.ecg"
        case .openCluster, .globularCluster: return "circle.grid.cross.fill"
        }
    }
    
    private func colorForType(_ type: AnomalyType) -> Color {
        switch type {
        case .nebula, .planetaryNebula: return .pink
        case .galaxy: return .purple
        case .blackHole: return .indigo
        case .supernova: return .orange
        default: return .blue
        }
    }
    
    private func gradientForType(_ type: AnomalyType) -> LinearGradient {
        switch type {
        case .nebula, .planetaryNebula:
            return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .galaxy:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blackHole:
            return LinearGradient(colors: [.black, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct ObservationsTab: View {
    @State private var observations: [SavedObservation] = []
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                if observations.isEmpty {
                        EmptyStateView(
                            icon: "note.text",
                            title: "No Observation Records Yet",
                            message: "Record your sky observations and take notes"
                        )
                    
                    Button {
                        // Add new observation
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Observation")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.cyan)
                        .foregroundColor(.black)
                        .cornerRadius(12)
                    }
                    .padding(.horizontal, 40)
                } else {
                    ForEach(observations) { observation in
                        SavedObservationCard(observation: observation)
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.top)
        }
    }
}

struct SavedObservationCard: View {
    let observation: SavedObservation
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(observation.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(observation.date, style: .date)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Text(observation.notes)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(3)
            
            HStack {
                Image(systemName: "location.fill")
                    .font(.caption)
                    .foregroundColor(.cyan)
                Text(observation.location)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct EmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text(title)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

#Preview {
    SavedItemsView()
        .environmentObject(StarMapViewModel())
        .environmentObject(AnomalyViewModel())
}
