import SwiftUI
import AVFoundation
import Photos
import CoreImage
import CoreImage.CIFilterBuiltins
import AudioToolbox
import Combine

struct SkyWatcherCameraView: View {
    let mode: SkyWatcherMode
    @StateObject private var controller = SkyWatcherCameraController()
    @State private var showWarning = true
    @State private var countdown = 5
    @State private var isCountingDown = false
    @State private var showSettings = false
    
    // Settings
    @AppStorage("skyWatcherSensitivity") private var sensitivity: Double = 0.5
    @AppStorage("skyWatcherCooldown") private var cooldown: Double = 3.0
    @AppStorage("skyWatcherAlarm") private var alarmEnabled: Bool = false
    @AppStorage("skyWatcherVibration") private var vibrationEnabled: Bool = true
    
    var body: some View {
        ZStack {
            // Camera Preview
            SkyWatcherPreview(session: controller.session)
                .ignoresSafeArea()
                .overlay(
                    // Filter Overlay
                    Color(mode.color).opacity(0.1).allowsHitTesting(false)
                        .blendMode(mode == .nightVision ? .screen : .overlay)
                )
            
            // Tracking Box
            if let rect = controller.detectedObjectRect {
                GeometryReader { geo in
                    Rectangle()
                        .stroke(Color.green, lineWidth: 2)
                        .frame(width: rect.width * geo.size.width, height: rect.height * geo.size.height)
                        .position(x: rect.midX * geo.size.width, y: rect.midY * geo.size.height)
                }
            }
            
            // UI Controls
            VStack {
                HStack {
                    Text(mode.rawValue)
                        .font(.headline)
                        .padding(8)
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                    
                    Spacer()
                    
                    if controller.isRecording {
                        Circle()
                            .fill(.red)
                            .frame(width: 12, height: 12)
                            .overlay(Circle().stroke(.white, lineWidth: 1))
                        Text("REC")
                            .font(.caption)
                            .fontWeight(.bold)
                            .foregroundColor(.red)
                    }
                    
                    Button(action: { showSettings.toggle() }) {
                        Image(systemName: "gear")
                            .font(.title2)
                            .padding(8)
                            .background(.ultraThinMaterial)
                            .clipShape(Circle())
                    }
                }
                .padding()
                
                Spacer()
                
                if !controller.isArmed && !isCountingDown {
                    Button(action: startSequence) {
                        Text("START")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .frame(width: 120, height: 120)
                            .background(Color.red)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white.opacity(0.5), lineWidth: 4)
                            )
                    }
                    .padding(.bottom, 40)
                } else if isCountingDown {
                    Text("\(countdown)")
                        .font(.system(size: 80, weight: .bold))
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                } else if controller.isArmed {
                    Text("ARMED - MONITORING")
                        .font(.headline)
                        .foregroundColor(.green)
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(8)
                        .padding(.bottom, 40)
                    
                    Button("STOP") {
                        controller.stopMonitoring()
                    }
                    .foregroundColor(.red)
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(8)
                }
            }
            
            // Warning Overlay
            if showWarning {
                Color.black.opacity(0.8).ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.yellow)
                        
                        Text("WARNING")
                            .font(.title)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Text("Human eye sees between 400-700 nanometers, GalacticalMap will capture and record what you cannot see. Position the camera in a fixed place facing the sky and never move it, the camera will automatically activate cyber sonic tracking mode on any object entering its angle, take video and capture the object, it will not record when nothing enters the camera's angle.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.white)
                            .padding()
                        
                        Button("I Understand") {
                            withAnimation {
                                showWarning = false
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.black)
                        .padding()
                        .background(Color.white)
                        .cornerRadius(10)
                    }
                    .padding()
                }
                .frame(maxWidth: 400, maxHeight: 500)
                .background(Color(UIColor.systemGray6).opacity(0.2))
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }
        }
        .onAppear {
            controller.setup()
            controller.updateSettings(sensitivity: sensitivity, cooldown: cooldown, alarm: alarmEnabled, vibration: vibrationEnabled)
        }
        .onDisappear {
            controller.stopMonitoring()
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(sensitivity: $sensitivity, cooldown: $cooldown, alarm: $alarmEnabled, vibration: $vibrationEnabled)
                .onChange(of: sensitivity) { _ in updateControllerSettings() }
                .onChange(of: cooldown) { _ in updateControllerSettings() }
                .onChange(of: alarmEnabled) { _ in updateControllerSettings() }
                .onChange(of: vibrationEnabled) { _ in updateControllerSettings() }
        }
    }
    
    func startSequence() {
        isCountingDown = true
        countdown = 5
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            if countdown > 1 {
                countdown -= 1
            } else {
                timer.invalidate()
                isCountingDown = false
                controller.startMonitoring()
            }
        }
    }
    
    func updateControllerSettings() {
        controller.updateSettings(sensitivity: sensitivity, cooldown: cooldown, alarm: alarmEnabled, vibration: vibrationEnabled)
    }
}

struct SettingsView: View {
    @Binding var sensitivity: Double
    @Binding var cooldown: Double
    @Binding var alarm: Bool
    @Binding var vibration: Bool
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Detection")) {
                    VStack(alignment: .leading) {
                        Text("Sensitivity: \(Int(sensitivity * 100))%")
                        Slider(value: $sensitivity, in: 0.1...1.0)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Cooldown: \(Int(cooldown))s")
                        Slider(value: $cooldown, in: 1...10, step: 1)
                    }
                }
                
                Section(header: Text("Alerts")) {
                    Toggle("Alarm Sound", isOn: $alarm)
                    Toggle("Vibration", isOn: $vibration)
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                Button("Done") { dismiss() }
            }
        }
    }
}

struct SkyWatcherPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    func makeUIView(context: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: PreviewView, context: Context) {
        uiView.videoPreviewLayer.session = session
    }
    
    class PreviewView: UIView {
        override class var layerClass: AnyClass {
            return AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
    }
}

class SkyWatcherCameraController: NSObject, ObservableObject, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureFileOutputRecordingDelegate {
    @Published var session = AVCaptureSession()
    @Published var detectedObjectRect: CGRect?
    @Published var isRecording = false
    @Published var isArmed = false
    
    private let videoOutput = AVCaptureVideoDataOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private let processQueue = DispatchQueue(label: "skywatcher.process.queue")
    
    private var device: AVCaptureDevice?
    private var previousPixelBuffer: CVPixelBuffer?
    
    // Settings
    private var sensitivity: Double = 0.5
    private var cooldown: Double = 3.0
    private var alarmEnabled: Bool = false
    private var vibrationEnabled: Bool = true
    
    private var lastRecordingTime: Date = Date.distantPast
    
    override init() {
        super.init()
    }
    
    func setup() {
        guard let d = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else { return }
        self.device = d
        
        do {
            let input = try AVCaptureDeviceInput(device: d)
            session.beginConfiguration()
            
            if session.canAddInput(input) { session.addInput(input) }
            
            videoOutput.setSampleBufferDelegate(self, queue: processQueue)
            if session.canAddOutput(videoOutput) { session.addOutput(videoOutput) }
            
            if session.canAddOutput(movieOutput) { session.addOutput(movieOutput) }
            
            session.commitConfiguration()
            
            DispatchQueue.global(qos: .background).async {
                self.session.startRunning()
            }
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func updateSettings(sensitivity: Double, cooldown: Double, alarm: Bool, vibration: Bool) {
        self.sensitivity = sensitivity
        self.cooldown = cooldown
        self.alarmEnabled = alarm
        self.vibrationEnabled = vibration
    }
    
    func startMonitoring() {
        isArmed = true
    }
    
    func stopMonitoring() {
        isArmed = false
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
    
    // Motion Detection Logic
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard isArmed, !isRecording, Date().timeIntervalSince(lastRecordingTime) > cooldown else { return }
        
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        if let previous = previousPixelBuffer {
            // Compare frames
            if detectMotion(current: pixelBuffer, previous: previous) {
                DispatchQueue.main.async {
                    self.triggerRecording()
                }
            }
        }
        
        // Keep reference to current buffer (needs copy to avoid buffer reuse issues)
        // Creating a deep copy of CVPixelBuffer is expensive, so we might just skip frames or use a lighter method.
        // For simplicity in this context, we'll assume we can process every Nth frame or just compare luminance.
        // Correct approach: Deep copy.
        
        // Optimization: Only update previous buffer occasionally or use a simpler check.
        // Actually, for simple motion detection, we can just keep the previous buffer if we retain it correctly?
        // CVPixelBuffers from the pool are reused. We MUST copy if we want to keep it.
        // Let's implement a simple luminance check instead of full pixel buffer copy if possible, or just copy.
        // Copying...
        self.previousPixelBuffer = pixelBuffer.copy()
    }
    
    private func detectMotion(current: CVPixelBuffer, previous: CVPixelBuffer) -> Bool {
        // Simplified motion detection: Compare average brightness or center pixel area.
        // For a "Cyber Sonic Tracking Mode", we need something that gives us a rect.
        // Let's simulate detection for now or implement a basic pixel diff.
        
        CVPixelBufferLockBaseAddress(current, .readOnly)
        CVPixelBufferLockBaseAddress(previous, .readOnly)
        
        defer {
            CVPixelBufferUnlockBaseAddress(current, .readOnly)
            CVPixelBufferUnlockBaseAddress(previous, .readOnly)
        }
        
        guard let currBase = CVPixelBufferGetBaseAddress(current),
              let prevBase = CVPixelBufferGetBaseAddress(previous) else { return false }
        
        let width = CVPixelBufferGetWidth(current)
        let height = CVPixelBufferGetHeight(current)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(current)
        
        // Check a grid of points
        var diffCount = 0
        let threshold = Int(255 * (1.0 - sensitivity) * 0.5) // Sensitivity adjusts threshold
        let step = 20 // Skip pixels for performance
        
        var minX = width, maxX = 0, minY = height, maxY = 0
        
        for y in stride(from: 0, to: height, by: step) {
            for x in stride(from: 0, to: width, by: step) {
                let offset = y * bytesPerRow + x * 4 // Assuming BGRA
                let currB = currBase.load(fromByteOffset: offset, as: UInt8.self)
                let prevB = prevBase.load(fromByteOffset: offset, as: UInt8.self)
                
                if abs(Int(currB) - Int(prevB)) > threshold {
                    diffCount += 1
                    
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
            }
        }
        
        let detected = diffCount > (10 * Int(sensitivity * 10)) // Minimum changed pixels
        
        if detected {
            DispatchQueue.main.async {
                // Normalize rect to 0-1 coordinates
                let rect = CGRect(x: CGFloat(minX)/CGFloat(width),
                                  y: CGFloat(minY)/CGFloat(height),
                                  width: CGFloat(maxX - minX)/CGFloat(width),
                                  height: CGFloat(maxY - minY)/CGFloat(height))
                // Expand a bit
                self.detectedObjectRect = rect.insetBy(dx: -0.05, dy: -0.05)
                
                // Auto Zoom
                self.zoomTo(rect: self.detectedObjectRect!)
            }
        } else {
            DispatchQueue.main.async {
                self.detectedObjectRect = nil
            }
        }
        
        return detected
    }
    
    private func zoomTo(rect: CGRect) {
        guard let device = device else { return }
        do {
            try device.lockForConfiguration()
            // Zoom logic: Center on rect, zoom in slightly.
            // Simple implementation: Just bump zoom factor if not already zoomed.
            let currentZoom = device.videoZoomFactor
            let targetZoom = min(currentZoom + 0.1, 3.0) // Max zoom 3x
            device.videoZoomFactor = targetZoom
            device.unlockForConfiguration()
        } catch {}
    }
    
    private func triggerRecording() {
        guard !isRecording else { return }
        
        // Feedback
        if vibrationEnabled {
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        }
        
        if alarmEnabled {
            AudioServicesPlaySystemSound(1005) // Alarm sound
        }
        
        // Start Recording
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent("skywatcher_\(Date().timeIntervalSince1970).mov")
        
        movieOutput.startRecording(to: fileURL, recordingDelegate: self)
        isRecording = true
    }
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        lastRecordingTime = Date()
        
        // Save to Custom Album
        saveToAlbum(url: outputFileURL)
        
        // Reset Zoom
        if let device = device {
            try? device.lockForConfiguration()
            device.videoZoomFactor = 1.0
            device.unlockForConfiguration()
        }
    }
    
    private func saveToAlbum(url: URL) {
        let albumName = "GalacticalMap"
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { return }
            
            // Find or create album
            let fetchOptions = PHFetchOptions()
            fetchOptions.predicate = NSPredicate(format: "title = %@", albumName)
            let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)
            
            if let album = collection.firstObject {
                // Album exists, save to it
                self.saveVideo(url: url, to: album)
            } else {
                // Create album
                var albumPlaceholder: PHObjectPlaceholder?
                PHPhotoLibrary.shared().performChanges({
                    let createAlbumRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: albumName)
                    albumPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                }, completionHandler: { success, error in
                    if success, let placeholder = albumPlaceholder {
                        let collection = PHAssetCollection.fetchAssetCollections(withLocalIdentifiers: [placeholder.localIdentifier], options: nil)
                        if let album = collection.firstObject {
                            self.saveVideo(url: url, to: album)
                        }
                    }
                })
            }
        }
    }
    
    private func saveVideo(url: URL, to album: PHAssetCollection) {
        PHPhotoLibrary.shared().performChanges({
            let createAssetRequest = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
            guard let albumChangeRequest = PHAssetCollectionChangeRequest(for: album),
                  let assetPlaceholder = createAssetRequest?.placeholderForCreatedAsset else { return }
            
            albumChangeRequest.addAssets([assetPlaceholder] as NSArray)
        }, completionHandler: { success, error in
            if success {
                print("Video saved to \(album.localizedTitle ?? "album")")
            } else {
                print("Error saving video: \(String(describing: error))")
            }
        })
    }
}

extension CVPixelBuffer {
    func copy() -> CVPixelBuffer? {
        var newPixelBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault,
                            CVPixelBufferGetWidth(self),
                            CVPixelBufferGetHeight(self),
                            CVPixelBufferGetPixelFormatType(self),
                            nil,
                            &newPixelBuffer)
        
        guard let destination = newPixelBuffer else { return nil }
        
        CVPixelBufferLockBaseAddress(self, .readOnly)
        CVPixelBufferLockBaseAddress(destination, [])
        
        let srcBase = CVPixelBufferGetBaseAddress(self)
        let destBase = CVPixelBufferGetBaseAddress(destination)
        let height = CVPixelBufferGetHeight(self)
        let bytesPerRow = CVPixelBufferGetBytesPerRow(self)
        
        if let src = srcBase, let dest = destBase {
            memcpy(dest, src, height * bytesPerRow)
        }
        
        CVPixelBufferUnlockBaseAddress(destination, [])
        CVPixelBufferUnlockBaseAddress(self, .readOnly)
        
        return destination
    }
}
