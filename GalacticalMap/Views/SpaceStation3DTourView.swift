//
//  SpaceStation3DTourView.swift
//  GalacticalMap
//
//  ISS/Tiangong 3D iç gezinti
//

import SwiftUI
import WebKit

struct SpaceStation3DTourView: View {
    @State private var selectedStation: SpaceStation = .iss
    @State private var selectedModule: String = "Harmony"
    @State private var showZaryaVideo = false
    @State private var zaryaErrorMessage: String? = nil
    @State private var zaryaIsLoading: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Station Selector
                Picker("Station", selection: $selectedStation) {
                    ForEach(SpaceStation.allCases, id: \.self) { station in
                        Text(station.rawValue).tag(station)
                    }
                }
                .pickerStyle(.segmented)
                .padding()
                .background(.ultraThinMaterial)
                
                // 3D View - Sketchfab Embeds
                if selectedStation == .iss {
                    // ISS 3D Model - Dark Background
                    WebView(url: URL(string: "https://sketchfab.com/models/b7d40d89fcbd4c998462380545f391b6/embed?autostart=1&ui_theme=dark&dnt=1")!, isLoading: .constant(false), errorMessage: .constant(nil))
                        .frame(height: 450)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .shadow(color: .cyan.opacity(0.3), radius: 10)
                } else {
                    // Tiangong 3D Model
                    WebView(url: URL(string: "https://sketchfab.com/models/205e0d24d4994eb9a232abe728e10a0f/embed?autostart=1&ui_theme=dark&dnt=1")!, isLoading: .constant(false), errorMessage: .constant(nil))
                        .frame(height: 450)
                        .cornerRadius(12)
                        .padding(.horizontal)
                        .shadow(color: .orange.opacity(0.3), radius: 10)
                }
                
                // Module List
                ScrollView {
                    VStack(spacing: 15) {
                        ForEach(selectedStation.modules, id: \.self) { module in
                            ModuleCard(module: module, isSelected: module == selectedModule)
                                .onTapGesture {
                                    selectedModule = module
                                    if selectedStation == .iss && module == "Zarya" {
                                        showZaryaVideo = true
                                    }
                                }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("🛰️ Space Station 3D Tour")
            .background(Color.black.ignoresSafeArea())
            .sheet(isPresented: $showZaryaVideo) {
                ZStack {
                    Color.black.ignoresSafeArea()
                    
                    VStack {
                        HStack {
                            Text("🔴 Canlı Yayın: ISS Zarya Modülü")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button {
                                showZaryaVideo = false
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
                        // NASA Live Stream & Sen 4K
                        TabView {
                            ZStack {
                                if zaryaIsLoading {
                                    ProgressView()
                                        .controlSize(.large)
                                        .tint(.white)
                                }
                                
                                WebView(url: URL(string: "https://www.youtube.com/embed/xRPjKQtRXR8?autoplay=1&mute=1&controls=0&modestbranding=1&rel=0&playsinline=1")!, isLoading: $zaryaIsLoading, errorMessage: $zaryaErrorMessage)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                    .opacity(zaryaIsLoading ? 0 : 1)
                                
                                if let errorMessage = zaryaErrorMessage {
                                    Text(errorMessage)
                                        .foregroundColor(.red)
                                        .padding()
                                        .background(Color.black.opacity(0.7))
                                        .cornerRadius(8)
                                }
                            }
                            .tabItem {
                                Label("NASA Live", systemImage: "globe.europe.africa")
                            }
                            
                            ZStack {
                                WebView(url: URL(string: "https://www.youtube.com/embed/fO9e9jnhYK8?autoplay=1&mute=1&controls=0&modestbranding=1&rel=0&playsinline=1")!, isLoading: .constant(false), errorMessage: .constant(nil))
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                            }
                            .tabItem {
                                Label("Sen 4K", systemImage: "camera.aperture")
                            }
                        }
                        .tabViewStyle(.page)
                        .indexViewStyle(.page(backgroundDisplayMode: .always))
                        .frame(height: 300)
                        .cornerRadius(12)
                    }
                }
                .presentationDetents([.medium, .large])
            }
        }
    }
}

// WebView Helper
struct WebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    @Binding var errorMessage: String?

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true
        config.mediaTypesRequiringUserActionForPlayback = []
        
        let webView = WKWebView(frame: .zero, configuration: config)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.scrollView.isScrollEnabled = false
        webView.scrollView.bounces = false
        webView.navigationDelegate = context.coordinator
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if webView.url?.absoluteString != url.absoluteString {
            let request = URLRequest(url: url)
            webView.load(request)
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: WebView

        init(_ parent: WebView) {
            self.parent = parent
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            parent.isLoading = true
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.errorMessage = "Video yüklenemedi: \(error.localizedDescription)"
            print("WebView navigation failed: \(error.localizedDescription)")
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
            parent.errorMessage = "Video yüklenemedi: \(error.localizedDescription)"
            print("WebView loading failed: \(error.localizedDescription)")
        }
    }
}

// Removed Placeholder struct as it's no longer needed

struct ModuleCard: View {
    let module: String
    let isSelected: Bool
    
    var body: some View {
        HStack {
            Image(systemName: "cube.fill")
                .foregroundColor(.cyan)
            
            VStack(alignment: .leading) {
                Text(module)
                    .foregroundColor(.white)
                    .fontWeight(isSelected ? .bold : .regular)
                Text("Module")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            
            Spacer()
            
            if isSelected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.green)
            }
        }
        .padding()
        .background(Color.white.opacity(0.1))
        .cornerRadius(10)
    }
}

enum SpaceStation: String, CaseIterable {
    case iss = "ISS"
    case tiangong = "Tiangong"
    
    var icon: String {
        switch self {
        case .iss: return "🛰️"
        case .tiangong: return "🚀"
        }
    }
    
    var modules: [String] {
        switch self {
        case .iss:
            return ["Harmony", "Destiny", "Columbus", "Kibo", "Zarya", "Zvezda", "Tranquility", "Unity"]
        case .tiangong:
            return ["Tianhe", "Wentian", "Mengtian"]
        }
    }
}

#Preview {
    SpaceStation3DTourView()
}
