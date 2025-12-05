import SwiftUI
import MapKit
import CoreLocation
import WebKit
import SafariServices

struct EarthEyesView: View {
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var searchText: String = ""
    @State private var isSearching: Bool = false
    @State private var annotations: [POI] = []
    @State private var showLookAround: Bool = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var lookAroundUnavailableAlert: Bool = false
    @State private var searchResults: [MKMapItem] = []
    @State private var showResults: Bool = false
    @State private var showWebStreetView: Bool = false
    @State private var streetViewURL: URL?
    @State private var showSafariStreetView: Bool = false
    @State private var safariURL: URL?
    @State private var heading: Double = 0
    @State private var pitch: Double = 0
    @State private var fov: Double = 80
    @State private var showStreetSettings: Bool = false

    struct POI: Identifiable {
        let id = UUID()
        let coordinate: CLLocationCoordinate2D
        let title: String
        let color: Color
    }
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                Map(coordinateRegion: $region, annotationItems: annotations) { item in
                    MapAnnotation(coordinate: item.coordinate) {
                        VStack(spacing: 4) {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 22))
                                .foregroundColor(item.color)
                            Text(item.title)
                                .font(.caption2)
                                .foregroundColor(.white)
                        }
                    }
                }
                .ignoresSafeArea()
                .onTapGesture {
                    hideKeyboard()
                }
                
                VStack(spacing: 10) {
                    HStack {
                        TextField("Şehir/adres veya koordinat (lat,lon)", text: $searchText)
                            .textFieldStyle(.roundedBorder)
                            .disableAutocorrection(true)
                            .autocapitalization(.none)
                        Button(action: { performSearch() }) {
                            Label("Git", systemImage: "arrow.forward.circle.fill")
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                        .tint(.cyan)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)
                    .padding(.top)
                    .background(.ultraThinMaterial)
                    .clipShape(Capsule())
                    
                    if showResults && !searchResults.isEmpty {
                        ScrollView {
                            VStack(spacing: 6) {
                                ForEach(Array(searchResults.prefix(8)), id: \.self) { item in
                                    Button(action: {
                                        let coord = item.placemark.coordinate
                                        setRegion(to: coord, title: item.name ?? "Hedef")
                                        showResults = false
                                    }) {
                                        HStack {
                                            Image(systemName: "mappin.and.ellipse")
                                                .foregroundColor(.cyan)
                                            VStack(alignment: .leading) {
                                                Text(item.name ?? "Sonuç")
                                                    .foregroundColor(.white)
                                                if let locality = item.placemark.locality {
                                                    Text(locality)
                                                        .font(.caption2)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                            Spacer()
                                        }
                                        .padding(8)
                                    }
                                    .background(.ultraThinMaterial)
                                    .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                            }
                            .padding(.horizontal)
                        }
                        .frame(maxHeight: 220)
                    }

                    DisclosureGroup(isExpanded: $showStreetSettings) {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Başlık")
                                    .foregroundColor(.secondary)
                                Slider(value: $heading, in: 0...360)
                                Text(String(format: "%.0f°", heading))
                                    .frame(width: 50, alignment: .trailing)
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Text("Eğim")
                                    .foregroundColor(.secondary)
                                Slider(value: $pitch, in: -90...90)
                                Text(String(format: "%.0f°", pitch))
                                    .frame(width: 50, alignment: .trailing)
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Text("Görüş")
                                    .foregroundColor(.secondary)
                                Slider(value: $fov, in: 30...120)
                                Text(String(format: "%.0f°", fov))
                                    .frame(width: 50, alignment: .trailing)
                                    .foregroundColor(.white)
                            }
                        }
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.horizontal)
                    } label: {
                        HStack {
                            Image(systemName: "slider.horizontal.3")
                                .foregroundColor(.cyan)
                            Text("Sokak Görünümü Ayarları")
                                .foregroundColor(.white)
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    
                    Spacer()
                }
                
                Menu {
                    Button(action: moveToUser) {
                        Label("Konumuma Git", systemImage: "location.fill")
                    }
                    Button(action: addToFavorites) {
                        Label("Favorilere Ekle", systemImage: "heart.fill")
                    }
                    Button(action: openLookAround) {
                        Label("Sokak Görünümü", systemImage: "figure.walk.circle.fill")
                    }
                } label: {
                    RainbowFAB()
                }
                .padding(.trailing, 12)
                .padding(.bottom, 16)
            }
            .navigationTitle("earth Now")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { moveToUser() }
            .sheet(isPresented: $showLookAround) {
                if let scene = lookAroundScene {
                    LookAroundViewWrapper(scene: scene)
                        .ignoresSafeArea()
                }
            }
            .alert("Sokak Görünümü bu konum için mevcut değil", isPresented: $lookAroundUnavailableAlert) {
                Button("Tamam", role: .cancel) {}
            }
            .fullScreenCover(isPresented: $showWebStreetView) {
                if let url = streetViewURL {
                    StreetWebView(url: url)
                        .ignoresSafeArea()
                }
            }
            .sheet(isPresented: $showSafariStreetView) {
                if let sUrl = safariURL {
                    SafariView(url: sUrl)
                        .ignoresSafeArea()
                }
            }
        }
    }
    
    private func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    private func moveToUser() {
        let coord = locationManager.coordinate
        region.center = coord
        region.span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        annotations = [
            POI(coordinate: coord, title: "Benim Konumum", color: .cyan)
        ]
    }
    
    private func performSearch() {
        hideKeyboard()
        let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        if let coord = parseCoordinate(from: trimmed) {
            setRegion(to: coord, title: "Hedef")
            return
        }
        isSearching = true
        let req = MKLocalSearch.Request()
        req.naturalLanguageQuery = trimmed
        req.region = region
        let search = MKLocalSearch(request: req)
        search.start { resp, _ in
            isSearching = false
            let items = resp?.mapItems ?? []
            self.searchResults = items
            self.showResults = !items.isEmpty
            if let first = items.first {
                setRegion(to: first.placemark.coordinate, title: first.name ?? "Hedef")
            }
        }
    }
    
    private func setRegion(to coord: CLLocationCoordinate2D, title: String) {
        region.center = coord
        region.span = MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        annotations = [
            POI(coordinate: coord, title: title, color: .orange),
            POI(coordinate: locationManager.coordinate, title: "Benim Konumum", color: .cyan)
        ]
    }
    
    private func parseCoordinate(from text: String) -> CLLocationCoordinate2D? {
        let pattern = "^\\s*([+-]?\\d+(?:\\.\\d+)?)\\s*[,\\s]\\s*([+-]?\\d+(?:\\.\\d+)?)\\s*$"
        if let regex = try? NSRegularExpression(pattern: pattern),
           let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) {
            let latStr = (text as NSString).substring(with: match.range(at: 1))
            let lonStr = (text as NSString).substring(with: match.range(at: 2))
            if let lat = Double(latStr), let lon = Double(lonStr) {
                return CLLocationCoordinate2D(latitude: lat, longitude: lon)
            }
        }
        return nil
    }
    
    private func addToFavorites() {
        let coord = region.center
        let item = FavoriteItem(
            type: .location,
            title: "Earth Now",
            subtitle: String(format: "%.5f, %.5f", coord.latitude, coord.longitude),
            locationCoordinate: LocationCoordinate(latitude: coord.latitude, longitude: coord.longitude, altitude: nil),
            tags: ["earth", "map", "location"],
            collectionName: "My Favorites"
        )
        favoritesManager.addFavorite(item)
    }
    
    private func openLookAround() {
        let coord = region.center
        if #available(iOS 17.0, *) {
            Task {
                let request = MKLookAroundSceneRequest(coordinate: coord)
                if let directScene = try? await request.scene {
                    DispatchQueue.main.async {
                        lookAroundScene = directScene
                        showLookAround = true
                    }
                } else if let nearbyScene = await nearestLookAroundScene(from: coord) {
                    DispatchQueue.main.async {
                        lookAroundScene = nearbyScene
                        showLookAround = true
                    }
                } else {
                    DispatchQueue.main.async { lookAroundUnavailableAlert = true }
                }
            }
        } else {
            lookAroundUnavailableAlert = true
        }
    }

    @available(iOS 17.0, *)
    private func nearestLookAroundScene(from coord: CLLocationCoordinate2D) async -> MKLookAroundScene? {
        let kms: [Double] = [2, 5, 10, 25, 50]
        for km in kms {
            let reg = regionAround(coord, km: km)
            let req = MKLocalSearch.Request()
            req.naturalLanguageQuery = "landmark"
            req.region = reg
            if let res = try? await MKLocalSearch(request: req).start() {
                let sorted = res.mapItems.sorted { a, b in
                    distanceKm(a.placemark.coordinate, coord) < distanceKm(b.placemark.coordinate, coord)
                }
                for item in sorted {
                    if distanceKm(item.placemark.coordinate, coord) <= km,
                       let scene = try? await MKLookAroundSceneRequest(mapItem: item).scene {
                        return scene
                    }
                }
            }
        }
        return nil
    }

    private func regionAround(_ coord: CLLocationCoordinate2D, km: Double) -> MKCoordinateRegion {
        let latDelta = km / 111.0
        let lonDelta = km / (111.0 * max(0.1, cos(coord.latitude * .pi / 180)))
        return MKCoordinateRegion(
            center: coord,
            span: MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        )
    }

    private func distanceKm(_ a: CLLocationCoordinate2D, _ b: CLLocationCoordinate2D) -> Double {
        let R = 6371.0
        let dLat = (a.latitude - b.latitude) * .pi / 180
        let dLon = (a.longitude - b.longitude) * .pi / 180
        let la1 = b.latitude * .pi / 180
        let la2 = a.latitude * .pi / 180
        let h = sin(dLat/2)*sin(dLat/2) + sin(dLon/2)*sin(dLon/2) * cos(la1) * cos(la2)
        return 2 * R * asin(min(1, sqrt(h)))
    }
}

#Preview {
    EarthEyesView()
        .environmentObject(LocationManager())
}

@available(iOS 16.0, *)
struct LookAroundViewWrapper: UIViewControllerRepresentable {
    let scene: MKLookAroundScene
    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        MKLookAroundViewController(scene: scene)
    }
    func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {
        uiViewController.scene = scene
    }
}

struct StreetWebView: UIViewRepresentable {
    let url: URL
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.scrollView.decelerationRate = .normal
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        uiView.load(URLRequest(url: url))
    }
}

struct RainbowFAB: View {
    @State private var rotation: Double = 0
    var body: some View {
        ZStack {
            Circle()
                .fill(Color.black.opacity(0.35))
                .frame(width: 58, height: 58)
                .overlay(
                    Circle()
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [.red, .orange, .yellow, .green, .cyan, .blue, .purple, .red]),
                                center: .center
                            ),
                            lineWidth: 3
                        )
                        .blur(radius: 6)
                        .rotationEffect(.degrees(rotation))
                )
                .shadow(color: Color.white.opacity(0.15), radius: 8)
            Image(systemName: "plus")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.white)
                .shadow(color: Color.white.opacity(0.3), radius: 6)
        }
        .onAppear {
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL
    func makeUIViewController(context: Context) -> SFSafariViewController {
        let config = SFSafariViewController.Configuration()
        config.entersReaderIfAvailable = false
        let vc = SFSafariViewController(url: url, configuration: config)
        vc.dismissButtonStyle = .close
        return vc
    }
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
