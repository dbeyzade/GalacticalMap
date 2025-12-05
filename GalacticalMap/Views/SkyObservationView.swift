import SwiftUI
import AVFoundation
import Combine
import Photos

struct SkyObservationView: View {
    enum Source: String, CaseIterable { case device, external }
    @StateObject private var controller = SkyObservationController()
    @State private var source: Source = .device
    @State private var externalURL: String = ""
    @State private var showingRecordings = false
    @State private var showStartWarning = false
    @State private var showIntro = true
    @State private var showCountdown = false
    @State private var countdown = 5
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                VStack(spacing: 12) {
                    Picker("Source", selection: $source) {
                        Text("Device Camera").tag(Source.device)
                        Text("External Camera").tag(Source.external)
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    if source == .device {
                        GeometryReader { geo in
                            ZStack {
                                if let s = controller.session {
                                    AVCameraPreview(session: s)
                                        .ignoresSafeArea()
                                } else {
                                    Color.black
                                }
                                if let point = controller.motionPoint {
                                    let x = point.x * geo.size.width
                                    let y = point.y * geo.size.height
                                    Image(systemName: "plus")
                                        .foregroundColor(.red)
                                        .font(.system(size: 28, weight: .bold))
                                        .position(x: x, y: y)
                                }
                                VStack {
                                    HStack {
                                        Text(controller.isRecording ? "Recording" : "Ready")
                                            .foregroundColor(.white)
                                            .padding(8)
                                            .background(Color.white.opacity(0.15))
                                            .clipShape(Capsule())
                                        Spacer()
                                        Button(controller.isRecording ? "Stop" : "Start") {
                                            if controller.isRecording {
                                                controller.stopRecording()
                                            } else {
                                                showStartWarning = true
                                            }
                                        }
                                        .padding(8)
                                        .background(Color.white.opacity(0.15))
                                        .foregroundColor(.white)
                                        .clipShape(Capsule())
                                    }
                                    .padding()
                                    Spacer()
                                }
                            }
                        }
                    } else {
                        VStack(spacing: 10) {
                            TextField("RTSP/HLS URL", text: $externalURL)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .padding(12)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                .padding(.horizontal)
                            if externalURL.isEmpty {
                                Text("Enter a camera stream URL")
                                    .foregroundColor(.white.opacity(0.6))
                                    .padding(.top, 8)
                            } else {
                                LiveStreamView(streamURL: externalURL)
                                    .ignoresSafeArea()
                            }
                        }
                    }
                }
                if showIntro {
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Observation Guide")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Position your phone so it sees the sky and keep it completely still. Tap the Record button. The app will count down from 5 seconds and activate Sibersonic tracking. When motion is detected, recording will start automatically.")
                                .foregroundColor(.white)
                                .font(.caption)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.85))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.25), lineWidth: 1)
                        )
                        .cornerRadius(10)
                        .padding(.top, 16)
                        .padding(.horizontal, 16)
                        Button { showIntro = false } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                                .padding(8)
                                .background(Color.black.opacity(0.5))
                                .clipShape(Circle())
                        }
                        .padding(.top, 6)
                        .padding(.trailing, 6)
                    }
                    .transition(.opacity)
                }
                if showCountdown {
                    VStack(spacing: 8) {
                        Text("Starting in")
                            .foregroundColor(.white.opacity(0.9))
                        Text("\(countdown)")
                            .font(.system(size: 44, weight: .bold))
                            .foregroundColor(.cyan)
                    }
                    .padding(16)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .navigationTitle("Sky Observation")
            .onAppear { controller.start(); controller.isArmed = false }
            .onDisappear { controller.stop(); controller.isArmed = false }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingRecordings = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "film")
                            Text("Recordings")
                        }
                        .foregroundColor(.white)
                    }
                }
            }
            .sheet(isPresented: $showingRecordings) {
                RecordedVideosView()
            }
            .alert("Observation Setup", isPresented: $showStartWarning) {
                Button("Start Countdown") { startCountdown() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Position your phone so it sees the sky and keep it completely still. Tap the Record button. The app will count down from 5 seconds and activate Sibersonic tracking. When motion is detected, recording will start automatically.")
            }
        }
    }
    private func startCountdown() {
        countdown = 5
        showCountdown = true
        runCountdownStep()
    }
    private func runCountdownStep() {
        if countdown > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                countdown -= 1
                runCountdownStep()
            }
        } else {
            showCountdown = false
            controller.isArmed = true
        }
    }
}

final class SkyObservationController: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    @Published var session: AVCaptureSession?
    @Published var motionPoint: CGPoint?
    @Published var isRecording = false
    @Published var isArmed = false
    private let captureSession = AVCaptureSession()
    private let videoOutput = AVCaptureVideoDataOutput()
    private let movieOutput = AVCaptureMovieFileOutput()
    private var lastMotionTime: TimeInterval = 0
    private var previousLuma: Data?
    private let queue = DispatchQueue(label: "sky.observation.queue")
    private var device: AVCaptureDevice?
    func start() {
        if session != nil { return }
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .high
        if let d = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            device = d
            if let input = try? AVCaptureDeviceInput(device: d), captureSession.canAddInput(input) { captureSession.addInput(input) }
            try? d.lockForConfiguration()
            if d.isFocusModeSupported(.continuousAutoFocus) { d.focusMode = .continuousAutoFocus }
            d.unlockForConfiguration()
        }
        videoOutput.alwaysDiscardsLateVideoFrames = true
        videoOutput.setSampleBufferDelegate(self, queue: queue)
        if captureSession.canAddOutput(videoOutput) { captureSession.addOutput(videoOutput) }
        if captureSession.canAddOutput(movieOutput) { captureSession.addOutput(movieOutput) }
        captureSession.commitConfiguration()
        captureSession.startRunning()
        session = captureSession
    }
    func stop() {
        stopRecording()
        captureSession.stopRunning()
        session = nil
    }
    func stopRecording() {
        if movieOutput.isRecording { movieOutput.stopRecording() }
        isRecording = false
    }
    func forceStartRecording() {
        if !movieOutput.isRecording { startRecording() }
    }
    private func startRecording() {
        let url = Self.outputURL()
        movieOutput.startRecording(to: url, recordingDelegate: self)
        isRecording = true
    }
    static func outputURL() -> URL {
        let fm = FileManager.default
        let base = try? fm.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
        let name = "sky_" + String(Int(Date().timeIntervalSince1970)) + ".mov"
        return (base ?? URL(fileURLWithPath: NSTemporaryDirectory())).appendingPathComponent(name)
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        isRecording = false
        saveToPhotos(outputFileURL)
    }
    private func saveToPhotos(_ url: URL) {
        PHPhotoLibrary.requestAuthorization { status in
            if status == .authorized || status == .limited {
                PHPhotoLibrary.shared().performChanges({
                    PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                }, completionHandler: { _, _ in })
            }
        }
    }
}

extension SkyObservationController: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pb = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        CVPixelBufferLockBaseAddress(pb, .readOnly)
        let w = CVPixelBufferGetWidthOfPlane(pb, 0)
        let h = CVPixelBufferGetHeightOfPlane(pb, 0)
        let rowStride = CVPixelBufferGetBytesPerRowOfPlane(pb, 0)
        guard let base = CVPixelBufferGetBaseAddressOfPlane(pb, 0) else { CVPixelBufferUnlockBaseAddress(pb, .readOnly); return }
        let step = 8
        var minX = Int.max
        var minY = Int.max
        var maxX = Int.min
        var maxY = Int.min
        var changed = 0
        var buf = [UInt8](repeating: 0, count: ((w/step)+1)*((h/step)+1))
        for y in Swift.stride(from: 0, to: h, by: step) {
            for x in Swift.stride(from: 0, to: w, by: step) {
                let p = base.advanced(by: y*rowStride + x)
                buf[(y/step)*((w/step)+1) + (x/step)] = p.load(as: UInt8.self)
            }
        }
        if let prev = previousLuma, prev.count == buf.count {
            for y in 0..<(h/step) {
                for x in 0..<(w/step) {
                    let i = y*((w/step)+1)+x
                    let dv = abs(Int(buf[i]) - Int(prev[i]))
                    if dv > 14 {
                        changed += 1
                        if x < minX { minX = x }
                        if y < minY { minY = y }
                        if x > maxX { maxX = x }
                        if y > maxY { maxY = y }
                    }
                }
            }
        }
        previousLuma = Data(buf)
        CVPixelBufferUnlockBaseAddress(pb, .readOnly)
        if changed > 30 {
            let cx = CGFloat(minX + maxX) / 2.0
            let cy = CGFloat(minY + maxY) / 2.0
            let nx = (cx * CGFloat(step)) / CGFloat(w)
            let ny = (cy * CGFloat(step)) / CGFloat(h)
            DispatchQueue.main.async { self.motionPoint = CGPoint(x: nx, y: ny) }
            if let d = device, d.isFocusPointOfInterestSupported {
                try? d.lockForConfiguration()
                d.focusPointOfInterest = CGPoint(x: nx, y: ny)
                if d.isFocusModeSupported(.continuousAutoFocus) { d.focusMode = .continuousAutoFocus }
                d.unlockForConfiguration()
            }
            lastMotionTime = CACurrentMediaTime()
            if isArmed, !movieOutput.isRecording { startRecording() }
        } else {
            let now = CACurrentMediaTime()
            if movieOutput.isRecording, now - lastMotionTime > 5.0 { stopRecording() }
        }
    }
}

struct AVCameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    func makeUIView(context: Context) -> UIView {
        let v = PreviewUIView()
        (v.layer as? AVCaptureVideoPreviewLayer)?.session = session
        (v.layer as? AVCaptureVideoPreviewLayer)?.videoGravity = .resizeAspectFill
        return v
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}

final class PreviewUIView: UIView {
    override static var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
}
