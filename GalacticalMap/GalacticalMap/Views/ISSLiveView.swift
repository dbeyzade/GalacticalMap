import SwiftUI
import WebKit
import CoreLocation

struct ISSLiveView: View {
    @EnvironmentObject var locationManager: LocationManager
    @State private var showPermissionAlert = false
    @State private var permissionAlertMessage = ""
    @State private var hasRequestedPermissions = false
    @State private var shouldLoadWebView = false
    
    var body: some View {
        NavigationStack {
            StreetWebViewFix(url: URL(string: "https://isslivenow.com/")!, shouldLoad: $shouldLoadWebView)
                .ignoresSafeArea()
                .navigationBarHidden(true)
                .onAppear {
                    checkAndRequestPermissions()
                }
        }
        .alert("Permissions Required", isPresented: $showPermissionAlert) {
            Button("Open Settings", role: .none) {
                openAppSettings()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text(permissionAlertMessage)
        }
    }
    
    private func checkAndRequestPermissions() {
        guard !hasRequestedPermissions else { return }
        hasRequestedPermissions = true
        
        // Check location permission
        let locationStatus = locationManager.authorizationStatus
        
        if locationStatus == .notDetermined {
            locationManager.requestPermission()
            permissionAlertMessage = "ISS Live requires location access to provide accurate tracking information. Please grant location permissions in Settings."
            showPermissionAlert = true
        } else if locationStatus == .denied || locationStatus == .restricted {
            permissionAlertMessage = "Location access is required for ISS tracking features. Please enable location permissions in Settings to continue."
            showPermissionAlert = true
        }
        shouldLoadWebView = true
        
        // Network permissions are handled automatically by iOS for web views
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

#Preview { ISSLiveView() }
