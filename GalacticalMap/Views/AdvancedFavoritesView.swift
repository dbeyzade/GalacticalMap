//
//  AdvancedFavoritesView.swift
//  GalacticalMap
//
//  Profesyonel Favoriler Yönetimi - Her şeyi kaydet!
//

import SwiftUI
import PhotosUI

struct AdvancedFavoritesView: View {
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var selectedFilter: FavoriteType? = nil
    @State private var showingCollections = false
    @State private var showingAddMenu = false
    @State private var showingCreateCollection = false
    @State private var viewMode: ViewMode = .grid
    
    enum ViewMode {
        case grid, list, timeline
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // İstatistikler
                        StatsSection(manager: favoritesManager)
                            .padding(.horizontal)
                        
                        // Koleksiyonlar
                        if showingCollections {
                            CollectionsCarousel(manager: favoritesManager)
                        }
                        
                        // Öne çıkanlar
                        if !favoritesManager.featuredFavorites.isEmpty {
                            FeaturedSection(items: favoritesManager.featuredFavorites, manager: favoritesManager)
                        }
                        
                        // Son görüntülenenler
                        if !favoritesManager.recentlyViewed.isEmpty {
                            RecentlyViewedSection(items: favoritesManager.recentlyViewed, manager: favoritesManager)
                        }
                        
                        // Tüm favoriler
                        AllFavoritesSection(
                            manager: favoritesManager,
                            viewMode: viewMode
                        )
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("My Favorites")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingCollections.toggle()
                    } label: {
                        Image(systemName: "folder.fill")
                            .foregroundColor(.cyan)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            viewMode = .grid
                        } label: {
                            Label("Grid", systemImage: "square.grid.2x2")
                        }
                        
                        Button {
                            viewMode = .list
                        } label: {
                            Label("List", systemImage: "list.bullet")
                        }
                        
                        Button {
                            viewMode = .timeline
                        } label: {
                            Label("Timeline", systemImage: "timeline.selection")
                        }
                        
                        Divider()
                        
                        Picker("Sort", selection: $favoritesManager.sortOption) {
                            ForEach(FavoritesManager.SortOption.allCases, id: \.self) { option in
                                Text(option.rawValue).tag(option)
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                            .foregroundColor(.cyan)
                    }
                }
            }
            .searchable(text: $favoritesManager.searchText, prompt: "Search favorites...")
            .sheet(isPresented: $showingCreateCollection) {
                CreateCollectionView(manager: favoritesManager)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // Hızlı ekleme butonu
            FloatingAddButton(showingMenu: $showingAddMenu)
                .padding()
        }
    }
}

struct StatsSection: View {
    @ObservedObject var manager: FavoritesManager
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Statistics")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Spacer()
            }
            
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatCard(
                    title: "Total",
                    value: "\(manager.totalFavorites)",
                    icon: "heart.fill",
                    color: .red
                )
                
                StatCard(
                    title: "Featured",
                    value: "\(manager.featuredFavorites.count)",
                    icon: "star.fill",
                    color: .yellow
                )
                
                StatCard(
                    title: "Collections",
                    value: "\(manager.collections.count)",
                    icon: "folder.fill",
                    color: .cyan
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(20)
    }
}

struct CollectionsCarousel: View {
    @ObservedObject var manager: FavoritesManager
    @State private var showingCreateNew = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Collections")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding(.horizontal)
                
                Spacer()
                
                Button {
                    showingCreateNew = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.cyan)
                        .padding(.horizontal)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(manager.collections) { collection in
                        CollectionCard(collection: collection, manager: manager)
                    }
                }
                .padding(.horizontal)
            }
        }
        .sheet(isPresented: $showingCreateNew) {
            CreateCollectionView(manager: manager)
        }
    }
}

struct CollectionCard: View {
    let collection: FavoriteCollection
    @ObservedObject var manager: FavoritesManager
    
    var body: some View {
        Button {
            manager.selectedCollection = collection
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Image(systemName: collection.icon)
                        .font(.title)
                        .foregroundColor(Color(hex: collection.color))
                    
                    Spacer()
                    
                    Text("\(collection.itemCount)")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                }
                
                Text(collection.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let description = collection.description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(2)
                }
            }
            .padding()
            .frame(width: 180, height: 140)
            .background(
                LinearGradient(
                    colors: [
                        Color(hex: collection.color).opacity(0.3),
                        Color(hex: collection.color).opacity(0.1)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: collection.color), lineWidth: 1)
            )
        }
    }
}

struct FeaturedSection: View {
    let items: [FavoriteItem]
    @ObservedObject var manager: FavoritesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("⭐ Featured")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(items) { item in
                        NavigationLink(destination: FavoriteDetailView(item: item, manager: manager)) {
                            FeaturedItemCard(item: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct FeaturedItemCard: View {
    let item: FavoriteItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Görsel veya ikon
            ZStack {
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 250, height: 150)
                        .clipped()
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(gradientForType(item.type))
                        .frame(width: 250, height: 150)
                        .overlay(
                            Image(systemName: iconForType(item.type))
                                .font(.system(size: 50))
                                .foregroundColor(.white.opacity(0.5))
                        )
                }
                
                // Öne çıkan rozeti
                VStack {
                    HStack {
                        Image(systemName: "star.fill")
                            .foregroundColor(.yellow)
                            .padding(8)
                            .background(Color.black.opacity(0.7))
                            .clipShape(Circle())
                        Spacer()
                    }
                    Spacer()
                }
                .padding(8)
            }
            .cornerRadius(12)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack {
                    if let rating = item.rating {
                        HStack(spacing: 2) {
                            ForEach(0..<5) { index in
                                Image(systemName: index < rating ? "star.fill" : "star")
                                    .font(.caption2)
                                    .foregroundColor(.yellow)
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Text(item.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.cyan.opacity(0.3))
                        .cornerRadius(8)
                        .foregroundColor(.white)
                }
            }
        }
        .frame(width: 250)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
    
    private func iconForType(_ type: FavoriteType) -> String {
        switch type {
        case .satellite: return "antenna.radiowaves.left.and.right"
        case .star: return "star.fill"
        case .anomaly: return "sparkles"
        case .constellation: return "star.circle"
        case .screenshot: return "camera.fill"
        case .video: return "video.fill"
        case .observation: return "note.text"
        case .location: return "location.fill"
        case .event: return "calendar"
        case .livestream: return "livephoto"
        }
    }
    
    private func gradientForType(_ type: FavoriteType) -> LinearGradient {
        switch type {
        case .satellite:
            return LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .star:
            return LinearGradient(colors: [.yellow, .orange], startPoint: .topLeading, endPoint: .bottomTrailing)
        case .anomaly:
            return LinearGradient(colors: [.purple, .pink], startPoint: .topLeading, endPoint: .bottomTrailing)
        default:
            return LinearGradient(colors: [.cyan, .blue], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }
}

struct RecentlyViewedSection: View {
    let items: [FavoriteItem]
    @ObservedObject var manager: FavoritesManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("🕐 Recently Viewed")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(items) { item in
                        NavigationLink(destination: FavoriteDetailView(item: item, manager: manager)) {
                            CompactFavoriteCard(item: item)
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}

struct CompactFavoriteCard: View {
    let item: FavoriteItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let imageData = item.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 80)
                    .cornerRadius(8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 120, height: 80)
                    
                    Image(systemName: iconForType(item.type))
                        .font(.title2)
                        .foregroundColor(.cyan)
                }
            }
            
            Text(item.title)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .lineLimit(2)
                .frame(width: 120, alignment: .leading)
            
            if let lastViewed = item.lastViewedDate {
                Text(lastViewed, style: .relative)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
            }
        }
    }
    
    private func iconForType(_ type: FavoriteType) -> String {
        switch type {
        case .satellite: return "antenna.radiowaves.left.and.right"
        case .star: return "star.fill"
        case .anomaly: return "sparkles"
        case .constellation: return "star.circle"
        case .screenshot: return "camera.fill"
        case .video: return "video.fill"
        case .observation: return "note.text"
        case .location: return "location.fill"
        case .event: return "calendar"
        case .livestream: return "livephoto"
        }
    }
}

struct AllFavoritesSection: View {
    @ObservedObject var manager: FavoritesManager
    let viewMode: AdvancedFavoritesView.ViewMode
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("All Favorites")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            if manager.filteredFavorites.isEmpty {
                EmptyFavoritesView()
            } else {
                switch viewMode {
                case .grid:
                    GridFavoritesView(items: manager.filteredFavorites, manager: manager)
                case .list:
                    ListFavoritesView(items: manager.filteredFavorites, manager: manager)
                case .timeline:
                    TimelineFavoritesView(items: manager.filteredFavorites, manager: manager)
                }
            }
        }
    }
}

struct GridFavoritesView: View {
    let items: [FavoriteItem]
    @ObservedObject var manager: FavoritesManager
    
    let columns = [GridItem(.flexible()), GridItem(.flexible())]
    
    var body: some View {
        LazyVGrid(columns: columns, spacing: 16) {
            ForEach(items) { item in
                NavigationLink(destination: FavoriteDetailView(item: item, manager: manager)) {
                    GridFavoriteCard(item: item, manager: manager)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct GridFavoriteCard: View {
    let item: FavoriteItem
    @ObservedObject var manager: FavoritesManager
    
    var body: some View {
        VStack(spacing: 0) {
            // Image/Icon
            ZStack {
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } else {
                    Rectangle()
                        .fill(Color.white.opacity(0.1))
                        .overlay(
                            Image(systemName: iconForType(item.type))
                                .font(.largeTitle)
                                .foregroundColor(.cyan)
                        )
                }
            }
            .frame(height: 120)
            .clipped()
            
            VStack(alignment: .leading, spacing: 6) {
                Text(item.title)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .lineLimit(2)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                        .lineLimit(1)
                }
                
                HStack {
                    Text(item.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 3)
                        .background(Color.cyan.opacity(0.3))
                        .cornerRadius(6)
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        manager.toggleFeatured(item)
                    } label: {
                        Image(systemName: item.isFeatured ? "star.fill" : "star")
                            .font(.caption)
                            .foregroundColor(.yellow)
                    }
                }
            }
            .padding(8)
        }
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func iconForType(_ type: FavoriteType) -> String {
        switch type {
        case .satellite: return "antenna.radiowaves.left.and.right"
        case .star: return "star.fill"
        case .anomaly: return "sparkles"
        case .constellation: return "star.circle"
        case .screenshot: return "camera.fill"
        case .video: return "video.fill"
        case .observation: return "note.text"
        case .location: return "location.fill"
        case .event: return "calendar"
        case .livestream: return "livephoto"
        }
    }
}

struct ListFavoritesView: View {
    let items: [FavoriteItem]
    @ObservedObject var manager: FavoritesManager
    
    var body: some View {
        VStack(spacing: 12) {
            ForEach(items) { item in
                NavigationLink(destination: FavoriteDetailView(item: item, manager: manager)) {
                    ListFavoriteRow(item: item, manager: manager)
                }
            }
        }
        .padding(.horizontal)
    }
}

struct ListFavoriteRow: View {
    let item: FavoriteItem
    @ObservedObject var manager: FavoritesManager
    
    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageData = item.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 60, height: 60)
                    .cornerRadius(8)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Image(systemName: iconForType(item.type))
                        .foregroundColor(.cyan)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                if let subtitle = item.subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.7))
                }
                
                HStack(spacing: 8) {
                    Text(item.type.rawValue)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.3))
                        .cornerRadius(4)
                        .foregroundColor(.white)
                    
                    if item.viewCount > 0 {
                        Label("\(item.viewCount)", systemImage: "eye.fill")
                            .font(.caption2)
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
            }
            
            Spacer()
            
            Button {
                manager.toggleFeatured(item)
            } label: {
                Image(systemName: item.isFeatured ? "star.fill" : "star")
                    .foregroundColor(.yellow)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func iconForType(_ type: FavoriteType) -> String {
        switch type {
        case .satellite: return "antenna.radiowaves.left.and.right"
        case .star: return "star.fill"
        case .anomaly: return "sparkles"
        case .constellation: return "star.circle"
        case .screenshot: return "camera.fill"
        case .video: return "video.fill"
        case .observation: return "note.text"
        case .location: return "location.fill"
        case .event: return "calendar"
        case .livestream: return "livephoto"
        }
    }
}

struct TimelineFavoritesView: View {
    let items: [FavoriteItem]
    @ObservedObject var manager: FavoritesManager
    
    var groupedByDate: [(Date, [FavoriteItem])] {
        let grouped = Dictionary(grouping: items) { item in
            Calendar.current.startOfDay(for: item.createdDate)
        }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(groupedByDate, id: \.0) { date, items in
                VStack(alignment: .leading, spacing: 12) {
                    Text(date, style: .date)
                        .font(.headline)
                        .foregroundColor(.cyan)
                        .padding(.horizontal)
                    
                    ForEach(items) { item in
                        NavigationLink(destination: FavoriteDetailView(item: item, manager: manager)) {
                            CompactFavoriteCard(item: item)
                                .padding(.horizontal)
                        }
                    }
                }
            }
        }
    }
}

struct EmptyFavoritesView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "heart.slash")
                .font(.system(size: 60))
                .foregroundColor(.white.opacity(0.3))
            
            Text("No Favorites Yet")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("Add stars, satellites, and more to your favorites")
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .padding(.vertical, 60)
    }
}

struct FloatingAddButton: View {
    @Binding var showingMenu: Bool
    
    var body: some View {
        Button {
            showingMenu.toggle()
        } label: {
            Image(systemName: "plus")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.black)
                .frame(width: 60, height: 60)
                .background(
                    LinearGradient(
                        colors: [.cyan, .blue],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(Circle())
                .shadow(color: .cyan.opacity(0.5), radius: 10)
        }
        .rotationEffect(.degrees(showingMenu ? 45 : 0))
        .animation(.spring(), value: showingMenu)
    }
}

struct CreateCollectionView: View {
    @ObservedObject var manager: FavoritesManager
    @Environment(\.dismiss) var dismiss
    
    @State private var name = ""
    @State private var description = ""
    @State private var selectedColor = "#00D4FF"
    @State private var selectedIcon = "star.fill"
    
    let colors = ["#FFD700", "#FF6B6B", "#4ECDC4", "#95E1D3", "#00D4FF", "#9B59B6", "#E74C3C"]
    let icons = ["star.fill", "heart.fill", "bookmark.fill", "folder.fill", "tag.fill", "flag.fill"]
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Info") {
                    TextField("Collection Name", text: $name)
                    TextField("Description (optional)", text: $description)
                }
                
                Section("Color") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(colors, id: \.self) { color in
                                Circle()
                                    .fill(Color(hex: color))
                                    .frame(width: 40, height: 40)
                                    .overlay(
                                        Circle()
                                            .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                    )
                                    .onTapGesture {
                                        selectedColor = color
                                    }
                            }
                        }
                    }
                }
                
                Section("Icon") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(icons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .font(.title2)
                                    .foregroundColor(selectedIcon == icon ? .cyan : .white)
                                    .frame(width: 40, height: 40)
                                    .background(Color.white.opacity(selectedIcon == icon ? 0.2 : 0.1))
                                    .cornerRadius(8)
                                    .onTapGesture {
                                        selectedIcon = icon
                                    }
                            }
                        }
                    }
                }
            }
            .navigationTitle("New Collection")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Create") {
                        manager.createCollection(
                            name: name,
                            description: description.isEmpty ? nil : description,
                            color: selectedColor,
                            icon: selectedIcon
                        )
                        dismiss()
                    }
                    .disabled(name.isEmpty)
                }
            }
        }
    }
}

struct FavoriteDetailView: View {
    let item: FavoriteItem
    @ObservedObject var manager: FavoritesManager
    @State private var showingDeleteAlert = false
    @State private var notes = ""
    @State private var rating: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Hero image/icon
                if let imageData = item.imageData,
                   let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .cornerRadius(16)
                        .padding()
                } else {
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 200)
                        
                        Image(systemName: iconForType(item.type))
                            .font(.system(size: 80))
                            .foregroundColor(.cyan)
                    }
                    .padding()
                }
                
                // Title & subtitle
                VStack(spacing: 8) {
                    Text(item.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let subtitle = item.subtitle {
                        Text(subtitle)
                            .font(.title3)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                
                // Rating
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { index in
                        Button {
                            rating = index
                            manager.setRating(for: item, rating: index)
                        } label: {
                            Image(systemName: index <= (item.rating ?? 0) ? "star.fill" : "star")
                                .font(.title2)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding()
                
                // Description
                if let description = item.description {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Description")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        Text(description)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                    .padding(.horizontal)
                }
                
                // Stats
                HStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Text("\(item.viewCount)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.cyan)
                        Text("Views")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    
                    Divider()
                        .frame(height: 40)
                    
                    VStack(spacing: 4) {
                        Text(item.createdDate, style: .date)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(.cyan)
                        Text("Added Date")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .padding(.horizontal)
                
                // Actions
                HStack(spacing: 12) {
                    Button {
                        manager.toggleFeatured(item)
                    } label: {
                        HStack {
                            Image(systemName: item.isFeatured ? "star.fill" : "star")
                            Text(item.isFeatured ? "Remove from Featured" : "Make Featured")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(item.isFeatured ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                    
                    Button {
                        // Share
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .padding()
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
                
                // Delete button
                Button {
                    showingDeleteAlert = true
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Remove from Favorites")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red.opacity(0.3))
                    .foregroundColor(.red)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(SpaceBackgroundView())
        .navigationBarTitleDisplayMode(.inline)
        .alert("Remove from Favorites", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Remove", role: .destructive) {
                manager.removeFavorite(item)
            }
        } message: {
            Text("Are you sure you want to remove this item from favorites?")
        }
        .onAppear {
            manager.incrementViewCount(item)
            notes = item.notes ?? ""
            rating = item.rating ?? 0
        }
    }
    
    private func iconForType(_ type: FavoriteType) -> String {
        switch type {
        case .satellite: return "antenna.radiowaves.left.and.right"
        case .star: return "star.fill"
        case .anomaly: return "sparkles"
        case .constellation: return "star.circle"
        case .screenshot: return "camera.fill"
        case .video: return "video.fill"
        case .observation: return "note.text"
        case .location: return "location.fill"
        case .event: return "calendar"
        case .livestream: return "livephoto"
        }
    }
}

// MARK: - Helper Extensions

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
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
            (a, r, g, b) = (255, 0, 0, 0)
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
    AdvancedFavoritesView()
}
