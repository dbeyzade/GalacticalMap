import SwiftUI
import MapKit
import CoreLocation
import WebKit

struct EarthEyesFix: View {
    let initialCoordinate: CLLocationCoordinate2D?
    init(initialCoordinate: CLLocationCoordinate2D? = nil) {
        self.initialCoordinate = initialCoordinate
    }
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var locationManager: LocationManager
    @StateObject private var favoritesManager = FavoritesManager.shared
    @State private var region = MKCoordinateRegion(
        center: CLLocationCoordinate2D(latitude: 41.0082, longitude: 28.9784),
        span: MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
    )
    @State private var annotations: [POI] = []
    @State private var heading: Double = 0
    @State private var pitch: Double = 0
    @State private var fov: Double = 80
    @State private var showWebStreetView: Bool = false
    @State private var streetViewURL: URL?
    @State private var showLookAround: Bool = false
    @State private var lookAroundScene: MKLookAroundScene?
    @State private var showControls: Bool = false
    @State private var showFavoritesList: Bool = false
    @State private var streetLoading: Bool = false

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
                            if item.title != "My Location" {
                                Button(action: { openStreetView() }) {
                                    HStack(spacing: 4) {
                                        Image(systemName: "figure.walk.circle")
                                        Text("Street View")
                                    }
                                    .font(.caption2)
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.black.opacity(0.6))
                                    .clipShape(Capsule())
                                }
                            }
                        }
                    }
                }
                .ignoresSafeArea()

                Menu {
                    Button(action: moveToUser) {
                        Label("Go to My Location", systemImage: "location.fill")
                    }
                    Button(action: addToFavorites) {
                        Label("Add to Favorites", systemImage: "heart.fill")
                    }
                    Button(action: openStreetView) {
                        Label("Street View", systemImage: "figure.walk.circle.fill")
                    }
                } label: {
                    RainbowFABFix()
                }
                .padding(.trailing, 12)
                .padding(.bottom, 16)

                if showLookAround, let s = lookAroundScene {
                    ZStack(alignment: .topTrailing) {
                        LookAroundViewWrapperFix(scene: s)
                            .ignoresSafeArea()
                        Button {
                            showLookAround = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 16)
                    }
                    .transition(.opacity)
                }

                if showWebStreetView {
                    ZStack(alignment: .topTrailing) {
                        if StreetViewConfig.apiKey.isEmpty {
                            if let url = streetViewURL {
                                StreetWebViewFix(url: url, onLoaded: { streetLoading = false })
                                    .ignoresSafeArea()
                            }
                        } else {
                            StreetInlineView(
                                latitude: region.center.latitude,
                                longitude: region.center.longitude,
                                heading: heading,
                                pitch: pitch,
                                fov: fov,
                                onLoaded: { streetLoading = false }
                            )
                            .ignoresSafeArea()
                        }
                        if streetLoading {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .tint(.cyan)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                                .padding(.top, 20)
                                .padding(.trailing, 80)
                        }
                        Button {
                            showWebStreetView = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                                .padding(12)
                                .background(Color.black.opacity(0.4))
                                .clipShape(Circle())
                        }
                        .padding(.top, 20)
                        .padding(.trailing, 16)
                    }
                    .transition(.opacity)
                }
            }
            .navigationTitle("Earth Now")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if let coord = initialCoordinate {
                    setRegion(to: coord, title: "Favorite")
                } else {
                    moveToUser()
                }
            }
            .sheet(isPresented: $showFavoritesList) {
                FavoritesQuickListView(
                    items: favoritesManager.favoriteItems.filter { $0.type == .location },
                    onSelect: { item in
                        if let loc = item.locationCoordinate?.clCoordinate {
                            setRegion(to: loc, title: item.title)
                        }
                    }
                )
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button { showFavoritesList = true } label: {
                        Image(systemName: "heart")
                            .foregroundColor(.red)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        withAnimation { showControls.toggle() }
                    } label: {
                        Image(systemName: "slider.horizontal.3")
                            .foregroundColor(.cyan)
                    }
                }
            }
            .overlay(alignment: .topLeading) {
                VStack(alignment: .leading, spacing: 8) {
                    Button { dismiss() } label: {
                        Image(systemName: "chevron.left.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .shadow(color: Color.black.opacity(0.4), radius: 4, x: 0, y: 2)
                    }
                    .padding(.leading, 12)
                    .padding(.top, 10)

                    if showControls {
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text("Heading")
                                    .foregroundColor(.secondary)
                                Slider(value: $heading, in: 0...360)
                                Text(String(format: "%.0f°", heading))
                                    .frame(width: 50, alignment: .trailing)
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Text("Pitch")
                                    .foregroundColor(.secondary)
                                Slider(value: $pitch, in: -90...90)
                                Text(String(format: "%.0f°", pitch))
                                    .frame(width: 50, alignment: .trailing)
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Text("FOV")
                                    .foregroundColor(.secondary)
                                Slider(value: $fov, in: 30...120)
                                Text(String(format: "%.0f°", fov))
                                    .frame(width: 50, alignment: .trailing)
                                    .foregroundColor(.white)
                            }
                            HStack {
                                Button("Apply Street View") { openStreetView() }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.cyan)
                            }
                        }
                        .padding(10)
                        .background(.ultraThinMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .padding(.leading, 12)
                    }
                }
            }
        }
    }

    private func moveToUser() {
        let coord = locationManager.coordinate
        region.center = coord
        region.span = MKCoordinateSpan(latitudeDelta: 0.08, longitudeDelta: 0.08)
        annotations = [
            POI(coordinate: coord, title: "My Location", color: .cyan)
        ]
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

    private func openStreetView() {
        let coord = region.center
        streetLoading = true
        if #available(iOS 16.0, *) {
            Task {
                let req = MKLookAroundSceneRequest(coordinate: coord)
                if let scene = try? await req.scene {
                    lookAroundScene = scene
                    showLookAround = true
                    streetLoading = false
                    return
                }
                // fallback Google Web (English)
                let panoURLString = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=\(coord.latitude),\(coord.longitude)&heading=\(Int(heading))&pitch=\(Int(pitch))&fov=\(Int(fov))&hl=en"
                if let url = URL(string: panoURLString) {
                    streetViewURL = url
                    showWebStreetView = true
                } else {
                    streetLoading = false
                }
            }
        } else {
            let panoURLString = "https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=\(coord.latitude),\(coord.longitude)&heading=\(Int(heading))&pitch=\(Int(pitch))&fov=\(Int(fov))&hl=en"
            if let url = URL(string: panoURLString) {
                streetViewURL = url
                showWebStreetView = true
            } else {
                streetLoading = false
            }
        }
    }

    private func setRegion(to coord: CLLocationCoordinate2D, title: String) {
        region.center = coord
        region.span = MKCoordinateSpan(latitudeDelta: 0.06, longitudeDelta: 0.06)
        annotations = [
            POI(coordinate: coord, title: title, color: .orange),
            POI(coordinate: locationManager.coordinate, title: "My Location", color: .cyan)
        ]
    }
}

struct StreetWebViewFix: UIViewRepresentable {
    let url: URL
    @Binding var shouldLoad: Bool
    var onLoaded: (() -> Void)? = nil
    
    init(url: URL, shouldLoad: Binding<Bool> = .constant(true), onLoaded: (() -> Void)? = nil) {
        self.url = url
        self._shouldLoad = shouldLoad
        self.onLoaded = onLoaded
    }
    
    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.preferences.javaScriptEnabled = true
        config.preferences.javaScriptCanOpenWindowsAutomatically = false
        let hostLower = (url.host ?? "").lowercased()
        let isISSLive = hostLower.contains("isslivenow.com")
        let isGoogleMaps = hostLower.contains("google.") || hostLower.contains("maps.google.")
        config.websiteDataStore = (isISSLive || isGoogleMaps) ? WKWebsiteDataStore.default() : WKWebsiteDataStore.nonPersistent()
        config.allowsInlineMediaPlayback = true
        if #available(iOS 15.0, *) {
            config.mediaTypesRequiringUserActionForPlayback = []
            config.defaultWebpagePreferences.allowsContentJavaScript = true
        }
        let ucc = WKUserContentController()
        if isISSLive {
            let langScript = """
            (function(){
              try {
                Object.defineProperty(navigator,'language',{get:function(){return 'en-US';}});
                Object.defineProperty(navigator,'languages',{get:function(){return ['en-US','en'];}});
              } catch(e) {}
              try { document.documentElement.setAttribute('lang','en'); } catch(e) {}
            })();
            """
            ucc.addUserScript(WKUserScript(source: langScript, injectionTime: .atDocumentStart, forMainFrameOnly: true))
            let issTidyScript = """
            (function(){
              function clean(){
                try {
                  var els = document.querySelectorAll('.gm-style .gm-style-cc, .gm-style-cc, .gm-style .gmnoprint');
                  els.forEach(function(el){
                    el.style.display = 'none';
                    el.style.visibility = 'hidden';
                  });
                } catch(e) {}
              }
              clean();
              var obs = new MutationObserver(clean);
              obs.observe(document.documentElement, {childList:true, subtree:true});
            })();
            """
            ucc.addUserScript(WKUserScript(source: issTidyScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        let hideScript = """
        (function(){
          function hide(){
            var selectors = [
              '#vasquette',
              'div[class*="vasquette"]',
              '[aria-label*="Open in app"]',
              '[aria-label*="Uygulamasında aç"]',
              'button[aria-label*="Open"]',
              'div[class*="promo"]',
              'div[class*="app-launcher"]',
              'div[class*="header"]',
              'div[class*="minimap"]',
              '.scene-header', '.ml-header', '.widget-pane-header'
            ];
            try {
              selectors.forEach(function(sel){
                document.querySelectorAll(sel).forEach(function(el){
                  el.style.display = 'none';
                  el.style.visibility = 'hidden';
                });
              });
              var st = document.createElement('style');
              st.innerHTML = '#vasquette, .vasquette, .scene-header, .ml-header, .widget-pane-header, [aria-label*="Open in app"], [aria-label*="Uygulamasında aç"]{ display:none !important; visibility:hidden !important; }';
              document.head.appendChild(st);
            } catch(e) {}
          }
          hide();
          var obs = new MutationObserver(hide);
          obs.observe(document.documentElement, {childList:true, subtree:true});
        })();
        """
        if !(isISSLive || isGoogleMaps) {
            ucc.addUserScript(WKUserScript(source: hideScript, injectionTime: .atDocumentEnd, forMainFrameOnly: true))
        }
        config.userContentController = ucc
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.customUserAgent = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15"
        webView.scrollView.decelerationRate = .normal
        webView.scrollView.isScrollEnabled = true
        webView.scrollView.alwaysBounceVertical = true
        webView.scrollView.showsVerticalScrollIndicator = true
        if #available(iOS 11.0, *) { webView.scrollView.contentInsetAdjustmentBehavior = .automatic }
        webView.allowsBackForwardNavigationGestures = false
        webView.uiDelegate = context.coordinator
        webView.navigationDelegate = context.coordinator
        return webView
    }
    func updateUIView(_ uiView: WKWebView, context: Context) {
        guard shouldLoad else { return }
        let host = url.host?.lowercased() ?? ""
        if host.contains("isslivenow.com") {
            if uiView.url == nil {
                var req = URLRequest(url: url)
                req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
                uiView.load(req)
            }
        } else if host.contains("google.") || host.contains("maps.google.") {
            var req = URLRequest(url: url)
            req.setValue("en-US,en;q=0.9", forHTTPHeaderField: "Accept-Language")
            uiView.load(req)
        } else if uiView.url != url {
            uiView.load(URLRequest(url: url))
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(onLoaded: onLoaded) }
    class Coordinator: NSObject, WKUIDelegate, WKNavigationDelegate {
        let onLoaded: (() -> Void)?
        init(onLoaded: (() -> Void)?) { self.onLoaded = onLoaded }
        func webView(_ webView: WKWebView, createWebViewWith configuration: WKWebViewConfiguration, for navigationAction: WKNavigationAction, windowFeatures: WKWindowFeatures) -> WKWebView? {
            if let url = navigationAction.request.url { webView.load(URLRequest(url: url)) }
            return nil
        }
        func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
            if navigationAction.targetFrame == nil, let url = navigationAction.request.url {
                webView.load(URLRequest(url: url))
                decisionHandler(.cancel)
                return
            }
            decisionHandler(.allow)
        }
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            onLoaded?()
        }
        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            if webView.url != nil { webView.reload() }
        }
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            if webView.url != nil { webView.reload() }
        }
        func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
            webView.reload()
        }
    }
}

@available(iOS 16.0, *)
struct LookAroundViewWrapperFix: UIViewControllerRepresentable {
    let scene: MKLookAroundScene
    func makeUIViewController(context: Context) -> MKLookAroundViewController {
        MKLookAroundViewController(scene: scene)
    }
    func updateUIViewController(_ uiViewController: MKLookAroundViewController, context: Context) {
        uiViewController.scene = scene
    }
}

struct RainbowFABFix: View {
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
