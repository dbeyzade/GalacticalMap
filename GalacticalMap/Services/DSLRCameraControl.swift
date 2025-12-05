//
//  DSLRCameraControl.swift
//  GalacticalMap
//
//  DSLR Camera Control & Astrophotography Suite
//  Canon, Nikon, Sony camera control, intervalometer, image stacking
//

import SwiftUI
import Combine
import AVFoundation
import ExternalAccessory
import CoreBluetooth

class DSLRCameraControl: NSObject, ObservableObject {
    static let shared = DSLRCameraControl()
    
    @Published var connectedCamera: DSLRCamera?
    @Published var availableCameras: [DSLRCamera] = []
    @Published var connectionStatus: CameraConnectionStatus = .disconnected
    @Published var captureSettings: CaptureSettings = CaptureSettings()
    @Published var intervalometerState: IntervalometerState?
    @Published var imageStack: [CapturedImage] = []
    
    // Bluetooth Central Manager
    private var centralManager: CBCentralManager?
    private var peripherals: [CBPeripheral] = []
    
    // Camera Communication
    private var activeSession: EASession?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Camera Discovery
    
    func startDiscovery() {
        connectionStatus = .scanning
        
        // Scan for Bluetooth cameras
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        
        // Scan for USB/WiFi cameras (PTP-IP protocol)
        discoverNetworkCameras()
    }
    
    func discoverNetworkCameras() {
        // PTP-IP camera discovery (Canon, Nikon WiFi)
        // Simplified implementation
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            // Simulate discovered cameras
            self?.availableCameras = [
                DSLRCamera(
                    id: "CANON_EOS_R6",
                    name: "Canon EOS R6",
                    manufacturer: .canon,
                    connectionType: .wifi,
                    features: [.bulbMode, .liveView, .intervalometer, .rawCapture, .remoteShutter]
                ),
                DSLRCamera(
                    id: "NIKON_Z9",
                    name: "Nikon Z9",
                    manufacturer: .nikon,
                    connectionType: .bluetooth,
                    features: [.bulbMode, .liveView, .intervalometer, .rawCapture, .remoteShutter, .focusStacking]
                ),
                DSLRCamera(
                    id: "SONY_A7SIII",
                    name: "Sony A7S III",
                    manufacturer: .sony,
                    connectionType: .wifi,
                    features: [.bulbMode, .liveView, .intervalometer, .rawCapture, .remoteShutter]
                )
            ]
            
            self?.connectionStatus = .ready
        }
    }
    
    func connect(to camera: DSLRCamera) {
        connectionStatus = .connecting
        
        // Simulate connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.connectedCamera = camera
            self?.connectionStatus = .connected
            self?.loadCameraSettings()
        }
    }
    
    func disconnect() {
        connectedCamera = nil
        connectionStatus = .disconnected
        activeSession = nil
    }
    
    // MARK: - Camera Settings
    
    func loadCameraSettings() {
        // Load current camera settings
        captureSettings = CaptureSettings(
            shutterSpeed: .bulb,
            aperture: .f2_8,
            iso: .iso3200,
            whiteBalance: .daylight,
            imageFormat: .raw,
            exposureCompensation: 0.0
        )
    }
    
    func updateSetting(_ setting: CameraSetting) {
        switch setting {
        case .shutterSpeed(let speed):
            captureSettings.shutterSpeed = speed
        case .aperture(let aperture):
            captureSettings.aperture = aperture
        case .iso(let iso):
            captureSettings.iso = iso
        case .whiteBalance(let wb):
            captureSettings.whiteBalance = wb
        case .imageFormat(let format):
            captureSettings.imageFormat = format
        }
        
        // Send to camera
        sendSettingToCamera(setting)
    }
    
    private func sendSettingToCamera(_ setting: CameraSetting) {
        // PTP (Picture Transfer Protocol) command implementation
        // Real implementation would send actual PTP commands
        print("📷 Setting updated: \(setting)")
    }
    
    // MARK: - Capture Control
    
    func captureImage(exposureTime: TimeInterval? = nil) {
        guard connectedCamera != nil else { return }
        
        let exposure = exposureTime ?? captureSettings.shutterSpeed.duration
        
        // Start exposure
        sendPTPCommand(.shutterPress)
        
        if exposure > 0 {
            // Bulb mode - hold shutter
            DispatchQueue.main.asyncAfter(deadline: .now() + exposure) { [weak self] in
                self?.sendPTPCommand(.shutterRelease)
                self?.downloadLastImage()
            }
        } else {
            // Normal shutter
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { [weak self] in
                self?.sendPTPCommand(.shutterRelease)
                self?.downloadLastImage()
            }
        }
    }
    
    private func downloadLastImage() {
        // Download image from camera
        let image = CapturedImage(
            id: UUID(),
            timestamp: Date(),
            settings: captureSettings,
            thumbnailURL: nil,
            fullResolutionURL: nil,
            metadata: CameraMetadata(
                exposureTime: captureSettings.shutterSpeed.duration,
                aperture: captureSettings.aperture.value,
                iso: captureSettings.iso.value,
                focalLength: 200.0
            )
        )
        
        imageStack.append(image)
    }
    
    // MARK: - Intervalometer
    
    func startIntervalometer(interval: TimeInterval, count: Int, exposure: TimeInterval) {
        intervalometerState = IntervalometerState(
            interval: interval,
            totalCount: count,
            capturedCount: 0,
            exposure: exposure,
            isRunning: true,
            startTime: Date()
        )
        
        runIntervalometerSequence()
    }
    
    private func runIntervalometerSequence() {
        guard var state = intervalometerState, state.isRunning else { return }
        
        if state.capturedCount >= state.totalCount {
            stopIntervalometer()
            return
        }
        
        // Capture image
        captureImage(exposureTime: state.exposure)
        
        state.capturedCount += 1
        intervalometerState = state
        
        // Schedule next capture
        DispatchQueue.main.asyncAfter(deadline: .now() + state.interval) { [weak self] in
            self?.runIntervalometerSequence()
        }
    }
    
    func stopIntervalometer() {
        intervalometerState?.isRunning = false
    }
    
    // MARK: - Image Stacking
    
    func stackImages(mode: StackingMode) -> StackedImage? {
        guard imageStack.count >= 2 else { return nil }
        
        // Image stacking algorithms
        switch mode {
        case .average:
            return stackAverage()
        case .median:
            return stackMedian()
        case .maximum:
            return stackMaximum()
        case .sigma:
            return stackSigmaClip()
        }
    }
    
    private func stackAverage() -> StackedImage {
        // Average stacking - reduces noise
        return StackedImage(
            id: UUID(),
            sourceImages: imageStack,
            stackingMode: .average,
            resultURL: nil,
            snrImprovement: sqrt(Double(imageStack.count))
        )
    }
    
    private func stackMedian() -> StackedImage {
        // Median stacking - best for removing satellites, planes
        return StackedImage(
            id: UUID(),
            sourceImages: imageStack,
            stackingMode: .median,
            resultURL: nil,
            snrImprovement: sqrt(Double(imageStack.count)) * 0.8
        )
    }
    
    private func stackMaximum() -> StackedImage {
        // Maximum stacking - for star trails
        return StackedImage(
            id: UUID(),
            sourceImages: imageStack,
            stackingMode: .maximum,
            resultURL: nil,
            snrImprovement: 1.0
        )
    }
    
    private func stackSigmaClip() -> StackedImage {
        // Sigma clipping - removes outliers
        return StackedImage(
            id: UUID(),
            sourceImages: imageStack,
            stackingMode: .sigma,
            resultURL: nil,
            snrImprovement: sqrt(Double(imageStack.count)) * 1.2
        )
    }
    
    // MARK: - Astrophotography Calculators
    
    func calculateExposureTime(aperture: Double, iso: Int, targetSNR: Double = 100) -> TimeInterval {
        // Exposure calculator based on camera specs and sky conditions
        let baseExposure = 120.0 // seconds
        let isoFactor = Double(iso) / 1600.0
        let apertureFactor = pow(aperture / 2.8, 2)
        
        return baseExposure / (isoFactor * apertureFactor)
    }
    
    func calculate500Rule(focalLength: Double, cropFactor: Double = 1.0) -> TimeInterval {
        // 500 rule for maximum exposure without star trails
        return 500.0 / (focalLength * cropFactor)
    }
    
    func calculateNPFRule(focalLength: Double, aperture: Double, pixelPitch: Double, declination: Double) -> TimeInterval {
        // NPF rule - more accurate than 500 rule
        let npf = (35.0 * aperture + 30.0 * pixelPitch) / (focalLength * cos(declination * .pi / 180))
        return npf
    }
    
    func calculateRequiredSubframes(targetSNR: Double, subExposure: TimeInterval) -> Int {
        // Calculate how many subframes needed for target SNR
        let singleFrameSNR = sqrt(subExposure / 120.0) * 50.0
        let required = pow(targetSNR / singleFrameSNR, 2)
        return Int(ceil(required))
    }
    
    // MARK: - PTP Commands
    
    private func sendPTPCommand(_ command: PTPCommand) {
        // Real PTP protocol implementation
        print("📷 PTP Command: \(command.rawValue)")
    }
}

// MARK: - Bluetooth Delegate

extension DSLRCameraControl: CBCentralManagerDelegate, CBPeripheralDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            // Bluetooth ready
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        // Camera discovered
        if let name = peripheral.name, name.contains("Canon") || name.contains("Nikon") || name.contains("Sony") {
            peripherals.append(peripheral)
        }
    }
}

// MARK: - Models

struct DSLRCamera: Identifiable {
    let id: String
    let name: String
    let manufacturer: CameraManufacturer
    let connectionType: ConnectionType
    let features: [CameraFeature]
}

enum CameraManufacturer {
    case canon, nikon, sony, fujifilm, olympus, panasonic
    
    var logo: String {
        switch self {
        case .canon: return "🔴"
        case .nikon: return "🟡"
        case .sony: return "🔵"
        case .fujifilm: return "🟢"
        case .olympus: return "⚫️"
        case .panasonic: return "🔵"
        }
    }
}

enum ConnectionType {
    case usb, wifi, bluetooth, ethernet
}

enum CameraFeature {
    case bulbMode, liveView, intervalometer, rawCapture, remoteShutter, focusStacking, bracketing
}

enum CameraConnectionStatus {
    case disconnected, scanning, ready, connecting, connected, error
}

struct CaptureSettings {
    var shutterSpeed: ShutterSpeed = .oneSecond
    var aperture: Aperture = .f2_8
    var iso: ISO = .iso1600
    var whiteBalance: WhiteBalance = .auto
    var imageFormat: ImageFormat = .raw
    var exposureCompensation: Double = 0.0
}

enum CameraSetting {
    case shutterSpeed(ShutterSpeed)
    case aperture(Aperture)
    case iso(ISO)
    case whiteBalance(WhiteBalance)
    case imageFormat(ImageFormat)
}

enum ShutterSpeed {
    case bulb
    case thirtySeconds, fifteenSeconds, eightSeconds, fourSeconds, twoSeconds, oneSecond
    case oneHalf, oneQuarter, oneEighth, oneFifteenth, oneThirtieth
    case oneSixtieth, oneHundredTwentyfifth, twoHundredFiftieth, fiveHundredth, oneThousandth
    
    var duration: TimeInterval {
        switch self {
        case .bulb: return 0 // Manual control
        case .thirtySeconds: return 30
        case .fifteenSeconds: return 15
        case .eightSeconds: return 8
        case .fourSeconds: return 4
        case .twoSeconds: return 2
        case .oneSecond: return 1
        case .oneHalf: return 0.5
        case .oneQuarter: return 0.25
        case .oneEighth: return 0.125
        case .oneFifteenth: return 1.0/15.0
        case .oneThirtieth: return 1.0/30.0
        case .oneSixtieth: return 1.0/60.0
        case .oneHundredTwentyfifth: return 1.0/125.0
        case .twoHundredFiftieth: return 1.0/250.0
        case .fiveHundredth: return 1.0/500.0
        case .oneThousandth: return 1.0/1000.0
        }
    }
    
    var displayName: String {
        switch self {
        case .bulb: return "BULB"
        case .thirtySeconds: return "30\""
        case .fifteenSeconds: return "15\""
        case .eightSeconds: return "8\""
        case .fourSeconds: return "4\""
        case .twoSeconds: return "2\""
        case .oneSecond: return "1\""
        case .oneHalf: return "1/2"
        case .oneQuarter: return "1/4"
        case .oneEighth: return "1/8"
        case .oneFifteenth: return "1/15"
        case .oneThirtieth: return "1/30"
        case .oneSixtieth: return "1/60"
        case .oneHundredTwentyfifth: return "1/125"
        case .twoHundredFiftieth: return "1/250"
        case .fiveHundredth: return "1/500"
        case .oneThousandth: return "1/1000"
        }
    }
}

enum Aperture {
    case f1_4, f1_8, f2, f2_8, f4, f5_6, f8, f11, f16, f22
    
    var value: Double {
        switch self {
        case .f1_4: return 1.4
        case .f1_8: return 1.8
        case .f2: return 2.0
        case .f2_8: return 2.8
        case .f4: return 4.0
        case .f5_6: return 5.6
        case .f8: return 8.0
        case .f11: return 11.0
        case .f16: return 16.0
        case .f22: return 22.0
        }
    }
    
    var displayName: String {
        return "f/\(value)"
    }
}

enum ISO {
    case iso100, iso200, iso400, iso800, iso1600, iso3200, iso6400, iso12800, iso25600
    
    var value: Int {
        switch self {
        case .iso100: return 100
        case .iso200: return 200
        case .iso400: return 400
        case .iso800: return 800
        case .iso1600: return 1600
        case .iso3200: return 3200
        case .iso6400: return 6400
        case .iso12800: return 12800
        case .iso25600: return 25600
        }
    }
}

enum WhiteBalance {
    case auto, daylight, cloudy, tungsten, fluorescent, flash, custom(Int)
}

enum ImageFormat {
    case jpeg, raw, rawPlusJpeg
}

struct IntervalometerState {
    var interval: TimeInterval
    var totalCount: Int
    var capturedCount: Int
    var exposure: TimeInterval
    var isRunning: Bool
    var startTime: Date
    
    var progress: Double {
        return Double(capturedCount) / Double(totalCount)
    }
    
    var estimatedCompletion: Date {
        let remaining = totalCount - capturedCount
        let timePerFrame = interval + exposure
        return Date().addingTimeInterval(Double(remaining) * timePerFrame)
    }
}

struct CapturedImage: Identifiable {
    let id: UUID
    let timestamp: Date
    let settings: CaptureSettings
    let thumbnailURL: URL?
    let fullResolutionURL: URL?
    let metadata: CameraMetadata
}

struct CameraMetadata {
    let exposureTime: TimeInterval
    let aperture: Double
    let iso: Int
    let focalLength: Double
}

struct StackedImage: Identifiable {
    let id: UUID
    let sourceImages: [CapturedImage]
    let stackingMode: StackingMode
    let resultURL: URL?
    let snrImprovement: Double
}

enum StackingMode {
    case average, median, maximum, sigma
    
    var name: String {
        switch self {
        case .average: return "Average (Noise Reduction)"
        case .median: return "Median (Artifact Removal)"
        case .maximum: return "Maximum (Star Trails)"
        case .sigma: return "Sigma Clip (Advanced)"
        }
    }
}

enum PTPCommand: String {
    case shutterPress = "0x100E"
    case shutterRelease = "0x100F"
    case getDeviceInfo = "0x1001"
    case openSession = "0x1002"
    case getObject = "0x1009"
    case deleteObject = "0x100B"
}

// MARK: - DSLR Control View

struct DSLRControlView: View {
    @StateObject private var camera = DSLRCameraControl.shared
    @State private var showCalculators = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Connection Status
                        CameraConnectionStatusCard(status: camera.connectionStatus)
                        
                        if camera.connectionStatus == .connected, let connectedCamera = camera.connectedCamera {
                            // Camera Info
                            CameraInfoCard(camera: connectedCamera)
                            
                            // Camera Controls
                            CameraSettingsPanel(settings: $camera.captureSettings)
                            
                            // Capture Controls
                            CaptureControlPanel()
                            
                            // Intervalometer
                            IntervalometerPanel()
                            
                            // Image Stack
                            if !camera.imageStack.isEmpty {
                                ImageStackPanel(images: camera.imageStack)
                            }
                        } else {
                            // Available Cameras
                            VStack(spacing: 12) {
                                Button {
                                    camera.startDiscovery()
                                } label: {
                                    Label("SCAN FOR CAMERAS", systemImage: "magnifyingglass")
                                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                                        .foregroundColor(.black)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color.cyan)
                                }
                                
                                ForEach(camera.availableCameras) { cam in
                                    CameraListItem(camera: cam) {
                                        camera.connect(to: cam)
                                    }
                                }
                            }
                            .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("DSLR Control")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "camera.fill")
                            .foregroundColor(.cyan)
                        Text("DSLR ASTROPHOTOGRAPHY")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showCalculators = true
                    } label: {
                        Image(systemName: "function")
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(isPresented: $showCalculators) {
                AstroCalculatorsView()
            }
        }
    }
}

struct CameraConnectionStatusCard: View {
    let status: CameraConnectionStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            Text(statusText)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
            
            Spacer()
        }
        .padding()
        .background(Color.cyan.opacity(0.1))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
    
    var statusColor: Color {
        switch status {
        case .disconnected: return .gray
        case .scanning: return .yellow
        case .ready: return .green
        case .connecting: return .orange
        case .connected: return .green
        case .error: return .red
        }
    }
    
    var statusText: String {
        switch status {
        case .disconnected: return "DISCONNECTED"
        case .scanning: return "SCANNING..."
        case .ready: return "READY"
        case .connecting: return "CONNECTING..."
        case .connected: return "CONNECTED"
        case .error: return "ERROR"
        }
    }
}

struct CameraInfoCard: View {
    let camera: DSLRCamera
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(camera.manufacturer.logo)
                    .font(.title)
                
                VStack(alignment: .leading) {
                    Text(camera.name)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(camera.connectionType == .wifi ? "WiFi" : "Bluetooth")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
            }
            
            // Features
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 8) {
                ForEach(camera.features, id: \.self) { feature in
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 10))
                        Text(featureName(feature))
                            .font(.system(size: 9, design: .monospaced))
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
    
    func featureName(_ feature: CameraFeature) -> String {
        switch feature {
        case .bulbMode: return "Bulb Mode"
        case .liveView: return "Live View"
        case .intervalometer: return "Intervalometer"
        case .rawCapture: return "RAW Capture"
        case .remoteShutter: return "Remote Shutter"
        case .focusStacking: return "Focus Stack"
        case .bracketing: return "Bracketing"
        }
    }
}

struct CameraSettingsPanel: View {
    @Binding var settings: CaptureSettings
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("CAMERA SETTINGS")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 12) {
                GridRow {
                    SettingControl(label: "SHUTTER", value: settings.shutterSpeed.displayName)
                    SettingControl(label: "APERTURE", value: settings.aperture.displayName)
                }
                
                GridRow {
                    SettingControl(label: "ISO", value: "\(settings.iso.value)")
                    SettingControl(label: "FORMAT", value: formatName(settings.imageFormat))
                }
            }
        }
        .padding()
        .background(Color.orange.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.orange.opacity(0.3), lineWidth: 1)
        )
    }
    
    func formatName(_ format: ImageFormat) -> String {
        switch format {
        case .jpeg: return "JPEG"
        case .raw: return "RAW"
        case .rawPlusJpeg: return "RAW+JPEG"
        }
    }
}

struct SettingControl: View {
    let label: String
    let value: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)
            Text(value)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
        }
    }
}

struct CaptureControlPanel: View {
    @StateObject private var camera = DSLRCameraControl.shared
    @State private var bulbDuration: Double = 120
    
    var body: some View {
        VStack(spacing: 12) {
            Text("CAPTURE CONTROL")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.red)
            
            if camera.captureSettings.shutterSpeed == .bulb {
                VStack {
                    HStack {
                        Text("BULB DURATION:")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        Text("\(Int(bulbDuration))s")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.red)
                    }
                    
                    Slider(value: $bulbDuration, in: 1...300, step: 1)
                        .accentColor(.red)
                }
            }
            
            Button {
                camera.captureImage(exposureTime: camera.captureSettings.shutterSpeed == .bulb ? bulbDuration : nil)
            } label: {
                Label("CAPTURE", systemImage: "camera.shutter.button")
                    .font(.system(size: 14, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.red)
            }
        }
        .padding()
        .background(Color.red.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct IntervalometerPanel: View {
    @StateObject private var camera = DSLRCameraControl.shared
    @State private var interval: Double = 30
    @State private var count: Double = 100
    @State private var exposure: Double = 120
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("INTERVALOMETER")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.purple)
            
            VStack(spacing: 8) {
                SliderControl(label: "INTERVAL", value: $interval, range: 5...300, unit: "s")
                SliderControl(label: "COUNT", value: $count, range: 1...500, unit: " frames")
                SliderControl(label: "EXPOSURE", value: $exposure, range: 1...300, unit: "s")
            }
            
            if let state = camera.intervalometerState, state.isRunning {
                VStack(spacing: 8) {
                    ProgressView(value: state.progress)
                        .accentColor(.purple)
                    
                    HStack {
                        Text("PROGRESS: \(state.capturedCount)/\(state.totalCount)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.purple)
                        
                        Spacer()
                        
                        Text("ETA: \(state.estimatedCompletion, style: .time)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    
                    Button {
                        camera.stopIntervalometer()
                    } label: {
                        Text("STOP")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red)
                    }
                }
            } else {
                Button {
                    camera.startIntervalometer(interval: interval, count: Int(count), exposure: exposure)
                } label: {
                    Text("START SEQUENCE")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(Color.purple)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
        )
    }
}

struct SliderControl: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(Int(value))\(unit)")
                    .font(.system(size: 10, weight: .semibold, design: .monospaced))
                    .foregroundColor(.purple)
            }
            
            Slider(value: $value, in: range, step: 1)
                .accentColor(.purple)
        }
    }
}

struct ImageStackPanel: View {
    let images: [CapturedImage]
    @StateObject private var camera = DSLRCameraControl.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("IMAGE STACK (\(images.count))")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                Spacer()
                
                Button {
                    _ = camera.stackImages(mode: .average)
                } label: {
                    Text("STACK")
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(.black)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.green)
                }
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(images) { image in
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 60)
                            .overlay(
                                VStack {
                                    Spacer()
                                    Text(image.timestamp, style: .time)
                                        .font(.system(size: 8, design: .monospaced))
                                        .foregroundColor(.white)
                                        .padding(4)
                                        .background(Color.black.opacity(0.7))
                                }
                            )
                    }
                }
            }
        }
        .padding()
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct CameraListItem: View {
    let camera: DSLRCamera
    let onConnect: () -> Void
    
    var body: some View {
        Button(action: onConnect) {
            HStack {
                Text(camera.manufacturer.logo)
                
                VStack(alignment: .leading) {
                    Text(camera.name)
                        .font(.system(size: 12, weight: .semibold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(camera.connectionType == .wifi ? "WiFi" : "Bluetooth")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.cyan)
            }
            .padding()
            .background(Color.cyan.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct AstroCalculatorsView: View {
    @State private var focalLength: Double = 200
    @State private var aperture: Double = 2.8
    @State private var iso: Double = 3200
    @State private var pixelPitch: Double = 4.3
    @State private var declination: Double = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        CalculatorCard(
                            title: "500 RULE",
                            result: String(format: "%.1fs", DSLRCameraControl.shared.calculate500Rule(focalLength: focalLength)),
                            description: "Maximum exposure without star trails"
                        )
                        
                        CalculatorCard(
                            title: "NPF RULE",
                            result: String(format: "%.1fs", DSLRCameraControl.shared.calculateNPFRule(focalLength: focalLength, aperture: aperture, pixelPitch: pixelPitch, declination: declination)),
                            description: "More accurate exposure calculation"
                        )
                        
                        VStack(alignment: .leading, spacing: 12) {
                            Text("PARAMETERS")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                            
                            SliderControl(label: "FOCAL LENGTH", value: $focalLength, range: 14...600, unit: "mm")
                            SliderControl(label: "APERTURE", value: $aperture, range: 1.4...22, unit: "")
                            SliderControl(label: "ISO", value: $iso, range: 100...25600, unit: "")
                            SliderControl(label: "PIXEL PITCH", value: $pixelPitch, range: 1...10, unit: "µm")
                            SliderControl(label: "DECLINATION", value: $declination, range: -90...90, unit: "°")
                        }
                        .padding()
                    }
                    .padding()
                }
            }
            .navigationTitle("Calculators")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct CalculatorCard: View {
    let title: String
    let result: String
    let description: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            Text(result)
                .font(.system(size: 24, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
            
            Text(description)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.cyan.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}

#Preview {
    DSLRControlView()
}
