//
//  AnomaliesView.swift
//  GalacticalMap
//
//  Gökyüzü anomalileri görünümü
//

import SwiftUI

struct AnomaliesView: View {
    @EnvironmentObject var viewModel: AnomalyViewModel
    @State private var selectedCategory: AnomalyType?
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Kategori seçici
                        CategorySelector(selectedCategory: $selectedCategory)
                            .padding(.horizontal)
                        
                        // İstatistikler
                        AnomalyStatsPanel(viewModel: viewModel)
                            .padding(.horizontal)
                        
                        // Öne çıkan anomaliler
                        FeaturedAnomaliesSection(viewModel: viewModel)
                        
                        // Anomali listesi
                        AnomaliesListSection(
                            viewModel: viewModel,
                            selectedCategory: selectedCategory
                        )
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Sky Anomalies")
            .searchable(text: $viewModel.searchText, prompt: "Search anomalies...")
        }
    }
}

struct CategorySelector: View {
    @Binding var selectedCategory: AnomalyType?
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                CategoryChip(
                    title: "All",
                    icon: "sparkles",
                    isSelected: selectedCategory == nil
                ) {
                    selectedCategory = nil
                }
                
                ForEach(AnomalyType.allCases, id: \.self) { type in
                    CategoryChip(
                        title: type.rawValue,
                        icon: iconForType(type),
                        isSelected: selectedCategory == type
                    ) {
                        selectedCategory = type
                    }
                }
            }
        }
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
}

struct CategoryChip: View {
    let title: String
    let icon: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.caption)
                Text(title)
                    .font(.caption)
                    .fontWeight(.semibold)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.purple : Color.white.opacity(0.2))
            .foregroundColor(.white)
            .cornerRadius(20)
        }
    }
}

struct AnomalyStatsPanel: View {
    @ObservedObject var viewModel: AnomalyViewModel
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            MiniStatCard(title: "Nebulae", value: "\(viewModel.nebulae.count)", color: .pink)
            MiniStatCard(title: "Galaxies", value: "\(viewModel.galaxies.count)", color: .purple)
            MiniStatCard(title: "Black Holes", value: "\(viewModel.blackHoles.count)", color: .indigo)
            MiniStatCard(title: "Clusters", value: "\(viewModel.clusters.count)", color: .blue)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

struct MiniStatCard: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct FeaturedAnomaliesSection: View {
    @ObservedObject var viewModel: AnomalyViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Featured")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(viewModel.anomalies.prefix(5)) { anomaly in
                        NavigationLink(destination: AnomalyDetailView(anomaly: anomaly, viewModel: viewModel)) {
                            FeaturedAnomalyCard(anomaly: anomaly)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FeaturedAnomalyCard: View {
    let anomaly: SkyAnomaly
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Görsel placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(gradientForType(anomaly.type))
                    .frame(height: 160)
                
                VStack {
                    Image(systemName: iconForType(anomaly.type))
                        .font(.system(size: 50))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(anomaly.commonName ?? anomaly.name)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                Text(anomaly.catalogNumber)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                HStack {
                    Label("\(String(format: "%.1f", anomaly.magnitude))", systemImage: "eye")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Spacer()
                    
                    Text(anomaly.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.purple.opacity(0.6))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }
            .padding(.horizontal, 8)
        }
        .frame(width: 280)
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
    
    private func gradientForType(_ type: AnomalyType) -> LinearGradient {
        switch type {
        case .nebula, .planetaryNebula:
            return LinearGradient(colors: [.pink, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .galaxy:
            return LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .blackHole:
            return LinearGradient(colors: [.black, .indigo], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .supernova:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct AnomaliesListSection: View {
    @ObservedObject var viewModel: AnomalyViewModel
    let selectedCategory: AnomalyType?
    
    var anomaliesToShow: [SkyAnomaly] {
        if let category = selectedCategory {
            return viewModel.filteredAnomalies.filter { $0.type == category }
        }
        return viewModel.filteredAnomalies
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Anomalies")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ForEach(anomaliesToShow) { anomaly in
                NavigationLink(destination: AnomalyDetailView(anomaly: anomaly, viewModel: viewModel)) {
                    AnomalyRow(anomaly: anomaly)
                }
            }
        }
    }
}

struct AnomalyRow: View {
    let anomaly: SkyAnomaly
    
    var body: some View {
        HStack(spacing: 16) {
            // İkon
            ZStack {
                Circle()
                    .fill(colorForType(anomaly.type))
                    .frame(width: 50, height: 50)
                    .blur(radius: 10)
                
                Image(systemName: iconForType(anomaly.type))
                    .font(.title3)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(anomaly.commonName ?? anomaly.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack {
                    Text(anomaly.catalogNumber)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text("•")
                        .foregroundColor(.white.opacity(0.5))
                    
                    Text(anomaly.type.rawValue)
                        .font(.caption)
                        .foregroundColor(colorForType(anomaly.type))
                }
                
                HStack(spacing: 12) {
                    Label("\(String(format: "%.1f", anomaly.magnitude))", systemImage: "eye")
                        .font(.caption2)
                        .foregroundColor(.yellow)
                    
                    Label(distanceString(anomaly.distance), systemImage: "ruler")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
            }
            
            Spacer()
            
            if anomaly.isSaved {
                Image(systemName: "bookmark.fill")
                    .foregroundColor(.purple)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .padding(.horizontal)
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
        case .quasar: return .yellow
        case .pulsar: return .green
        default: return .blue
        }
    }
    
    private func distanceString(_ distance: Double) -> String {
        if distance > 1_000_000 {
            return String(format: "%.1f Mly", distance / 1_000_000)
        } else {
            return "\(Int(distance)) ly"
        }
    }
}

struct AnomalyDetailView: View {
    let anomaly: SkyAnomaly
    @ObservedObject var viewModel: AnomalyViewModel
    @State private var notes = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Image
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(gradientForType(anomaly.type))
                        .frame(height: 250)
                    
                    Image(systemName: iconForType(anomaly.type))
                        .font(.system(size: 80))
                        .foregroundColor(.white.opacity(0.3))
                }
                .padding(.horizontal)
                
                // Header
                VStack(spacing: 8) {
                    Text(anomaly.commonName ?? anomaly.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text(anomaly.catalogNumber)
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.7))
                    
                    Text(anomaly.type.rawValue)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(colorForType(anomaly.type))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                .padding()
                
                // Basic information
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    DetailCard(title: "Magnitude", value: String(format: "%.1f", anomaly.magnitude), unit: "mag")
                    DetailCard(title: "Distance", value: distanceString(anomaly.distance), unit: "")
                    DetailCard(title: "Size", value: String(format: "%.1f", anomaly.size), unit: "arcmin")
                    DetailCard(title: "Constellation", value: anomaly.constellation.rawValue, unit: "")
                }
                .padding(.horizontal)
                
                // Description
                VStack(alignment: .leading, spacing: 12) {
                    Text("About")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(anomaly.description)
                        .font(.body)
                        .foregroundColor(.white.opacity(0.9))
                        .lineSpacing(6)
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Discovery info
                if let discoveredBy = anomaly.discoveredBy, let discoveryDate = anomaly.discoveryDate {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Discovery")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Discovered By")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(discoveredBy)
                                    .font(.body)
                                    .foregroundColor(.cyan)
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("Year")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.7))
                                Text(discoveryDate, format: .dateTime.year())
                                    .font(.body)
                                    .foregroundColor(.cyan)
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(16)
                    .padding(.horizontal)
                }
                
                // Observation notes
                VStack(alignment: .leading, spacing: 12) {
                    Text("Your Observation Notes")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    TextEditor(text: $notes)
                        .frame(height: 120)
                        .padding(8)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(12)
                        .foregroundColor(.white)
                    
                    Button {
                        viewModel.addNotes(to: anomaly, notes: notes)
                    } label: {
                        Text("Save Note")
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.purple)
                            .foregroundColor(.white)
                            .fontWeight(.bold)
                            .cornerRadius(12)
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(16)
                .padding(.horizontal)
                
                // Save button
                Button {
                    if anomaly.isSaved {
                        viewModel.unsaveAnomaly(anomaly)
                    } else {
                        viewModel.saveAnomaly(anomaly)
                    }
                } label: {
                    HStack {
                        Image(systemName: anomaly.isSaved ? "bookmark.fill" : "bookmark")
                        Text(anomaly.isSaved ? "Remove from Saved" : "Save")
                            .fontWeight(.bold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(anomaly.isSaved ? Color.red : Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(SpaceBackgroundView())
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            notes = anomaly.observationNotes ?? ""
        }
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
        case .quasar: return .yellow
        case .pulsar: return .green
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
        case .supernova:
            return LinearGradient(colors: [.orange, .red], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
    
    private func distanceString(_ distance: Double) -> String {
        if distance > 1_000_000 {
            return String(format: "%.1f Mly", distance / 1_000_000)
        } else {
            return "\(Int(distance)) ly"
        }
    }
}

#Preview {
    AnomaliesView()
        .environmentObject(AnomalyViewModel())
}
