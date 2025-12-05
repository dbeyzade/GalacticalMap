//
//  StarMapView.swift
//  GalacticalMap
//
//  Yıldız haritası görünümü - Professional Edition
//

import SwiftUI

struct StarMapView: View {
    @EnvironmentObject var viewModel: StarMapViewModel
    @EnvironmentObject var locationManager: LocationManager
    @State private var selectedViewMode = 0 // 0: List, 1: Sky Map
    @State private var showingStarDetail = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Deep Space Background
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Custom Segmented Control
                    HStack(spacing: 0) {
                        Button {
                            withAnimation { selectedViewMode = 0 }
                        } label: {
                            VStack {
                                Text("Database")
                                    .font(.headline)
                                    .foregroundColor(selectedViewMode == 0 ? .cyan : .gray)
                                Rectangle()
                                    .fill(selectedViewMode == 0 ? Color.cyan : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        
                        Button {
                            withAnimation { selectedViewMode = 1 }
                        } label: {
                            VStack {
                                Text("Sky Chart")
                                    .font(.headline)
                                    .foregroundColor(selectedViewMode == 1 ? .cyan : .gray)
                                Rectangle()
                                    .fill(selectedViewMode == 1 ? Color.cyan : Color.clear)
                                    .frame(height: 2)
                            }
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding(.top)
                    .background(Color.black.opacity(0.5))
                    
                    if selectedViewMode == 0 {
                        // List View
                        ScrollView {
                            VStack(spacing: 20) {
                                // Stats Dashboard
                                StatsPanel(viewModel: viewModel)
                                    .padding(.horizontal)
                                    .padding(.top)
                                
                                // Constellations Horizontal Scroll
                                ConstellationsSection(viewModel: viewModel)
                                
                                // Star List
                                StarsListSection(viewModel: viewModel)
                            }
                            .padding(.bottom, 80)
                        }
                        .transition(.move(edge: .leading))
                    } else {
                        // Sky Chart View
                        SkyChartVisualization(stars: viewModel.filteredStars)
                            .transition(.move(edge: .trailing))
                    }
                }
            }
            .navigationTitle("Star Map Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        ForEach(StarMapViewModel.StarSortOption.allCases, id: \.self) { option in
                            Button {
                                viewModel.sortBy = option
                            } label: {
                                HStack {
                                    Text(option.rawValue)
                                    if viewModel.sortBy == option {
                                        Image(systemName: "checkmark")
                                    }
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.cyan)
                    }
                }
            }
        }
    }
}

struct SkyChartVisualization: View {
    let stars: [Star]
    @State private var scale: CGFloat = 1.0
    @State private var offset: CGSize = .zero
    @State private var lastOffset: CGSize = .zero
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Color.black.opacity(0.8)
                
                // Grid Lines
                Path { path in
                    let width = geometry.size.width
                    let height = geometry.size.height
                    let step: CGFloat = 50
                    
                    for x in stride(from: 0, to: width, by: step) {
                        path.move(to: CGPoint(x: x, y: 0))
                        path.addLine(to: CGPoint(x: x, y: height))
                    }
                    
                    for y in stride(from: 0, to: height, by: step) {
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                }
                .stroke(Color.blue.opacity(0.1), lineWidth: 0.5)
                
                // Stars
                ForEach(stars.prefix(50)) { star in // Limit for performance in this demo
                    Circle()
                        .fill(starColor(for: star))
                        .frame(width: max(2, 8 - CGFloat(star.magnitude)), height: max(2, 8 - CGFloat(star.magnitude)))
                        .position(
                            x: geometry.size.width / 2 + CGFloat.random(in: -150...150) * scale + offset.width,
                            y: geometry.size.height / 2 + CGFloat.random(in: -250...250) * scale + offset.height
                        ) // Simulated position since we don't have RA/Dec in this simple model
                        .shadow(color: starColor(for: star).opacity(0.8), radius: 4)
                }
                
                VStack {
                    Spacer()
                    Text("Simulated Sky View")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding()
                }
            }
            .gesture(
                DragGesture()
                    .onChanged { value in
                        offset = CGSize(width: lastOffset.width + value.translation.width,
                                      height: lastOffset.height + value.translation.height)
                    }
                    .onEnded { _ in
                        lastOffset = offset
                    }
            )
            .gesture(
                MagnificationGesture()
                    .onChanged { value in
                        scale = value
                    }
            )
        }
        .clipShape(Rectangle())
    }
    
    private func starColor(for star: Star) -> Color {
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

struct StatsPanel: View {
    @ObservedObject var viewModel: StarMapViewModel
    
    var body: some View {
        HStack(spacing: 12) {
            StatCard(title: "Total Stars", value: "\(viewModel.stars.count)", icon: "star.fill", color: .yellow)
            StatCard(title: "Saved", value: "\(viewModel.savedStars.count)", icon: "bookmark.fill", color: .cyan)
            StatCard(title: "Visible", value: "\(viewModel.visibleStars.count)", icon: "eye.fill", color: .green)
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                Spacer()
                Text(value)
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.white.opacity(0.6))
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(LinearGradient(colors: [color.opacity(0.5), .clear], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
                )
        )
    }
}

struct ConstellationsSection: View {
    @ObservedObject var viewModel: StarMapViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CONSTELLATIONS")
                .font(.caption)
                .fontWeight(.bold)
                .tracking(2)
                .foregroundColor(.gray)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(Constellation.allCases.prefix(10), id: \.self) { constellation in
                        ConstellationCard(
                            constellation: constellation,
                            starCount: viewModel.getStarsInConstellation(constellation).count
                        ) {
                            viewModel.filterConstellation = constellation
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct ConstellationCard: View {
    let constellation: Constellation
    let starCount: Int
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: "sparkles")
                        .font(.title2)
                        .foregroundColor(.cyan)
                    Spacer()
                    Text("\(starCount)")
                        .font(.caption)
                        .padding(4)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                }
                
                Text(constellation.rawValue)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            .padding()
            .frame(width: 140, height: 100)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(LinearGradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.1)], startPoint: .topLeading, endPoint: .bottomTrailing))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

struct StarsListSection: View {
    @ObservedObject var viewModel: StarMapViewModel
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("STAR CATALOG")
                    .font(.caption)
                    .fontWeight(.bold)
                    .tracking(2)
                    .foregroundColor(.gray)
                
                Spacer()
                
                Button {
                    withAnimation {
                        viewModel.showOnlySaved.toggle()
                    }
                } label: {
                    Text(viewModel.showOnlySaved ? "Show All" : "Saved Only")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(viewModel.showOnlySaved ? Color.cyan : Color.white.opacity(0.1))
                        .foregroundColor(viewModel.showOnlySaved ? .black : .white)
                        .cornerRadius(20)
                }
            }
            .padding(.horizontal)
            
            LazyVStack(spacing: 12) {
                ForEach(viewModel.filteredStars.prefix(50)) { star in
                    NavigationLink(destination: StarDetailView(star: star, viewModel: viewModel)) {
                        StarRow(star: star)
                    }
                }
            }
        }
    }
}

struct StarRow: View {
    let star: Star
    
    var body: some View {
        HStack(spacing: 16) {
            // Star Visual
            ZStack {
                Circle()
                    .fill(starColor.opacity(0.2))
                    .frame(width: 40, height: 40)
                
                Circle()
                    .fill(starColor)
                    .frame(width: 12, height: 12)
                    .shadow(color: starColor, radius: 5)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(star.commonName ?? star.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(star.constellation.rawValue)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(String(format: "%.1f", star.magnitude)) mag")
                    .font(.caption)
                    .foregroundColor(.cyan)
                    .fontWeight(.bold)
                
                Text("\(Int(star.distance)) ly")
                    .font(.caption2)
                    .foregroundColor(.gray)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.white.opacity(0.3))
        }
        .padding()
        .background(Color.white.opacity(0.03))
        .cornerRadius(12)
        .padding(.horizontal)
    }
    
    private var starColor: Color {
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

struct StarDetailView: View {
    let star: Star
    @ObservedObject var viewModel: StarMapViewModel
    @State private var notes = ""
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Star Header
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(starColor.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .blur(radius: 20)
                        
                        Circle()
                            .fill(starColor)
                            .frame(width: 60, height: 60)
                            .shadow(color: starColor, radius: 20)
                    }
                    .padding(.top)
                    
                    VStack(spacing: 8) {
                        Text(star.commonName ?? star.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text(star.constellation.rawValue)
                            .font(.title3)
                            .foregroundColor(.gray)
                    }
                }
                
                // Data Grid
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    DetailCard(title: "Magnitude", value: String(format: "%.2f", star.magnitude), unit: "mag")
                    DetailCard(title: "Distance", value: "\(Int(star.distance))", unit: "ly")
                    DetailCard(title: "Temperature", value: "\(Int(star.temperature))", unit: "K")
                    DetailCard(title: "Spectral Type", value: star.spectralType, unit: "")
                }
                .padding(.horizontal)
                
                // Actions
                Button {
                    if star.isSaved {
                        viewModel.unsaveStar(star)
                    } else {
                        viewModel.saveStar(star)
                    }
                } label: {
                    HStack {
                        Image(systemName: star.isSaved ? "bookmark.fill" : "bookmark")
                        Text(star.isSaved ? "Remove from Saved" : "Save to Favorites")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(star.isSaved ? Color.red.opacity(0.2) : Color.cyan.opacity(0.2))
                    .foregroundColor(star.isSaved ? .red : .cyan)
                    .cornerRadius(12)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(star.isSaved ? Color.red : Color.cyan, lineWidth: 1)
                    )
                }
                .padding(.horizontal)
            }
            .padding(.bottom)
        }
        .background(SpaceBackgroundView())
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private var starColor: Color {
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

struct DetailCard: View {
    let title: String
    let value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if !unit.isEmpty {
                    Text(unit)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.05))
        .cornerRadius(16)
    }
}

#Preview {
    StarMapView()
        .environmentObject(StarMapViewModel())
        .environmentObject(LocationManager())
}
