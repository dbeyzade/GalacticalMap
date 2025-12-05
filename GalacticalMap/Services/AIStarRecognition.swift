//
//  AIStarRecognition.swift
//  GalacticalMap
//
//  CoreML + Vision ile AI Yıldız Tanıma
//  Kamerayı gökyüzüne çevir, hangi yıldız olduğunu öğren!
//

import SwiftUI
import Combine
import AVFoundation
import Vision
import CoreML
import CoreLocation
import ARKit

class AIStarRecognitionService: NSObject, ObservableObject {
    static let shared = AIStarRecognitionService()
    
    @Published var recognizedStars: [RecognizedStar] = []
    @Published var isProcessing = false
    @Published var confidence: Float = 0.0
    @Published var detectedObjects: [DetectedCelestialObject] = []
    @Published var recommendations: [String] = []
    
    private var captureSession: AVCaptureSession?
    
    var session: AVCaptureSession? {
        captureSession
    }
    private var videoOutput: AVCaptureVideoDataOutput?
    private let processQueue = DispatchQueue(label: "com.galacticalmap.aiprocessing")
    
    // Star pattern matching
    private var starPatternDatabase: [StarPattern] = []
    
    override init() {
        super.init()
        loadStarPatterns()
    }
    
    // MARK: - Camera Setup
    
    func setupCamera() {
        let session = AVCaptureSession()
        session.sessionPreset = .hd1920x1080
        
        guard let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
              let input = try? AVCaptureDeviceInput(device: device) else {
            return
        }
        
        if session.canAddInput(input) {
            session.addInput(input)
        }
        
        let output = AVCaptureVideoDataOutput()
        output.setSampleBufferDelegate(self, queue: processQueue)
        output.videoSettings = [kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA]
        
        if session.canAddOutput(output) {
            session.addOutput(output)
        }
        
        self.captureSession = session
        self.videoOutput = output
        
        // Configure camera for night sky
        if let device = device as? AVCaptureDevice {
            configureCameraForNightSky(device)
        }
    }
    
    private func configureCameraForNightSky(_ device: AVCaptureDevice) {
        do {
            try device.lockForConfiguration()
            
            // Maximum exposure for dark sky
            device.exposureMode = .custom
            let maxExposure = device.activeFormat.maxExposureDuration
            device.setExposureModeCustom(duration: maxExposure, iso: device.activeFormat.maxISO)
            
            // Manual focus to infinity
            device.focusMode = .locked
            device.setFocusModeLocked(lensPosition: 0.0) // 0 = infinity
            
            // Disable auto white balance for accurate star colors
            device.whiteBalanceMode = .locked
            
            device.unlockForConfiguration()
        } catch {
            print("Error configuring camera: \(error)")
        }
    }
    
    func startRecognition() {
        captureSession?.startRunning()
        DispatchQueue.main.async {
            self.isProcessing = true
        }
    }
    
    func stopRecognition() {
        captureSession?.stopRunning()
        DispatchQueue.main.async {
            self.isProcessing = false
        }
    }
    
    // MARK: - Star Pattern Database
    
    private func loadStarPatterns() {
        // Prominent constellations with star patterns
        starPatternDatabase = [
            StarPattern(
                name: "Orion's Belt",
                stars: ["Alnitak", "Alnilam", "Mintaka"],
                geometry: .linear(spacing: 1.5),
                constellation: "Orion"
            ),
            StarPattern(
                name: "Big Dipper",
                stars: ["Dubhe", "Merak", "Phecda", "Megrez", "Alioth", "Mizar", "Alkaid"],
                geometry: .dipper,
                constellation: "Ursa Major"
            ),
            StarPattern(
                name: "Southern Cross",
                stars: ["Acrux", "Mimosa", "Gacrux", "Imai"],
                geometry: .cross,
                constellation: "Crux"
            ),
            StarPattern(
                name: "Summer Triangle",
                stars: ["Vega", "Deneb", "Altair"],
                geometry: .triangle,
                constellation: "Multiple"
            ),
            StarPattern(
                name: "Cassiopeia W",
                stars: ["Schedar", "Caph", "Navi", "Ruchbah", "Segin"],
                geometry: .w_shape,
                constellation: "Cassiopeia"
            )
        ]
    }
    
    // MARK: - AI Processing
    
    private func processFrame(_ pixelBuffer: CVPixelBuffer) {
        // Step 1: Detect bright points (stars)
        detectBrightPoints(in: pixelBuffer) { [weak self] points in
            guard let self = self else { return }
            
            // Step 2: Analyze star patterns
            let patterns = self.analyzeStarPatterns(points)
            
            // Step 3: Match with database
            let matches = self.matchPatterns(patterns)
            
            // Step 4: Use current location and time for verification
            self.verifyWithEphemeris(matches) { verified in
                DispatchQueue.main.async {
                    self.recognizedStars = verified
                    self.updateRecommendations()
                }
            }
        }
    }
    
    private func detectBrightPoints(in pixelBuffer: CVPixelBuffer, completion: @escaping ([ImagePoint]) -> Void) {
        let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        
        // Create brightness detector
        guard let detector = CIDetector(
            ofType: CIDetectorTypeFace, // Using face detector API for point detection
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        ) else {
            completion([])
            return
        }
        
        // Alternative: Manual bright point detection
        var brightPoints: [ImagePoint] = []
        
        // Convert to grayscale and find bright pixels
        if let filter = CIFilter(name: "CIColorControls") {
            filter.setValue(ciImage, forKey: kCIInputImageKey)
            filter.setValue(1.5, forKey: kCIInputBrightnessKey) // Enhance brightness
            filter.setValue(2.0, forKey: kCIInputContrastKey) // Increase contrast
            
            if let outputImage = filter.outputImage {
                // Threshold to find bright points
                let extent = outputImage.extent
                
                // Sample grid and find bright spots
                let gridSize = 20
                let stepX = extent.width / CGFloat(gridSize)
                let stepY = extent.height / CGFloat(gridSize)
                
                for x in 0..<gridSize {
                    for y in 0..<gridSize {
                        let point = CGPoint(
                            x: CGFloat(x) * stepX + stepX/2,
                            y: CGFloat(y) * stepY + stepY/2
                        )
                        
                        // Check brightness at this point
                        let brightness = measureBrightness(in: outputImage, at: point)
                        
                        if brightness > 0.7 { // Threshold for stars
                            brightPoints.append(ImagePoint(
                                location: point,
                                brightness: brightness,
                                color: measureColor(in: ciImage, at: point)
                            ))
                        }
                    }
                }
            }
        }
        
        completion(brightPoints)
    }
    
    private func measureBrightness(in image: CIImage, at point: CGPoint) -> Float {
        // Simplified brightness measurement
        // In production, use CIContext to render small region and analyze
        return Float.random(in: 0...1) // Placeholder
    }
    
    private func measureColor(in image: CIImage, at point: CGPoint) -> StarColor {
        // Analyze RGB to determine star color/temperature
        // Blue stars = hot, red stars = cool
        return .white // Placeholder
    }
    
    private func analyzeStarPatterns(_ points: [ImagePoint]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []
        
        // Look for geometric patterns
        // Linear patterns (like Orion's Belt)
        patterns.append(contentsOf: findLinearPatterns(in: points))
        
        // Triangular patterns (like Summer Triangle)
        patterns.append(contentsOf: findTriangularPatterns(in: points))
        
        // Cross patterns (like Southern Cross)
        patterns.append(contentsOf: findCrossPatterns(in: points))
        
        return patterns
    }
    
    private func findLinearPatterns(in points: [ImagePoint]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []
        
        // Find sets of 3+ collinear points
        for i in 0..<points.count {
            for j in (i+1)..<points.count {
                for k in (j+1)..<points.count {
                    let p1 = points[i].location
                    let p2 = points[j].location
                    let p3 = points[k].location
                    
                    // Check if nearly collinear
                    if areCollinear(p1, p2, p3, tolerance: 0.1) {
                        patterns.append(DetectedPattern(
                            points: [points[i], points[j], points[k]],
                            type: .linear
                        ))
                    }
                }
            }
        }
        
        return patterns
    }
    
    private func findTriangularPatterns(in points: [ImagePoint]) -> [DetectedPattern] {
        var patterns: [DetectedPattern] = []
        
        // Find sets of 3 points forming prominent triangles
        for i in 0..<points.count {
            for j in (i+1)..<points.count {
                for k in (j+1)..<points.count {
                    let p1 = points[i]
                    let p2 = points[j]
                    let p3 = points[k]
                    
                    // Check if they're all bright (prominent stars)
                    if p1.brightness > 0.8 && p2.brightness > 0.8 && p3.brightness > 0.8 {
                        patterns.append(DetectedPattern(
                            points: [p1, p2, p3],
                            type: .triangle
                        ))
                    }
                }
            }
        }
        
        return patterns
    }
    
    private func findCrossPatterns(in points: [ImagePoint]) -> [DetectedPattern] {
        // Find cross-shaped patterns (4 points)
        var patterns: [DetectedPattern] = []
        
        // Implementation similar to above but checking for cross geometry
        
        return patterns
    }
    
    private func areCollinear(_ p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, tolerance: CGFloat) -> Bool {
        // Calculate cross product
        let cross = (p2.y - p1.y) * (p3.x - p2.x) - (p2.x - p1.x) * (p3.y - p2.y)
        return abs(cross) < tolerance
    }
    
    private func matchPatterns(_ detectedPatterns: [DetectedPattern]) -> [PatternMatch] {
        var matches: [PatternMatch] = []
        
        for detected in detectedPatterns {
            for known in starPatternDatabase {
                let similarity = calculateSimilarity(detected: detected, known: known)
                
                if similarity > 0.7 {
                    matches.append(PatternMatch(
                        pattern: known,
                        confidence: similarity,
                        detectedPoints: detected.points
                    ))
                }
            }
        }
        
        return matches.sorted { $0.confidence > $1.confidence }
    }
    
    private func calculateSimilarity(detected: DetectedPattern, known: StarPattern) -> Float {
        // Compare geometry, brightness patterns, etc.
        // This is simplified - real implementation would use shape descriptors
        
        switch (detected.type, known.geometry) {
        case (.linear, .linear):
            return 0.9
        case (.triangle, .triangle):
            return 0.85
        case (.cross, .cross):
            return 0.88
        default:
            return 0.0
        }
    }
    
    private func verifyWithEphemeris(_ matches: [PatternMatch], completion: @escaping ([RecognizedStar]) -> Void) {
        // Use current location and time to verify stars are actually visible
        guard let location = RTKLocationManager.shared.currentLocation else {
            completion([])
            return
        }
        
        let currentTime = Date()
        var verified: [RecognizedStar] = []
        
        for match in matches {
            // For each star in the pattern, check if it should be visible
            for starName in match.pattern.stars {
                if let star = Star.database.first(where: { $0.name == starName }) {
                    // Calculate if star is above horizon
                    let coordinates = calculateAltAz(
                        ra: star.rightAscension,
                        dec: star.declination,
                        latitude: location.coordinate.latitude,
                        longitude: location.coordinate.longitude,
                        time: currentTime
                    )
                    
                    if coordinates.altitude > 0 { // Above horizon
                        verified.append(RecognizedStar(
                            star: star,
                            confidence: match.confidence,
                            altitude: coordinates.altitude,
                            azimuth: coordinates.azimuth,
                            constellation: match.pattern.constellation
                        ))
                    }
                }
            }
        }
        
        completion(verified)
    }
    
    private func calculateAltAz(ra: Double, dec: Double, latitude: Double, longitude: Double, time: Date) -> (altitude: Double, azimuth: Double) {
        // Simplified astronomical calculation
        // Real implementation would use proper ephemeris calculations
        
        // Local Sidereal Time
        let lst = calculateLocalSiderealTime(longitude: longitude, time: time)
        
        // Hour Angle
        let ha = lst - ra
        
        // Convert to Alt/Az
        let latRad = latitude * .pi / 180
        let decRad = dec * .pi / 180
        let haRad = ha * .pi / 180
        
        let sinAlt = sin(decRad) * sin(latRad) + cos(decRad) * cos(latRad) * cos(haRad)
        let altitude = asin(sinAlt) * 180 / .pi
        
        let cosAz = (sin(decRad) - sin(latRad) * sinAlt) / (cos(latRad) * cos(asin(sinAlt)))
        let azimuth = acos(cosAz) * 180 / .pi
        
        return (altitude: altitude, azimuth: azimuth)
    }
    
    private func calculateLocalSiderealTime(longitude: Double, time: Date) -> Double {
        // Simplified LST calculation
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: time)
        
        // Julian Date calculation (simplified)
        let jd = 2451545.0 // Placeholder - would use proper JD calculation
        
        // GMST
        let gmst = 280.46061837 + 360.98564736629 * (jd - 2451545.0)
        
        // LST = GMST + longitude
        let lst = gmst + longitude
        
        return lst.truncatingRemainder(dividingBy: 360.0)
    }
    
    private func updateRecommendations() {
        var recs: [String] = []
        
        if recognizedStars.isEmpty {
            recs.append("Kamerayı gökyüzüne çevirin")
            recs.append("Parlak yıldızları hedefleyin")
            recs.append("Telefonu sabit tutun")
        } else {
            if let brightest = recognizedStars.first {
                recs.append("✨ \(brightest.star.name) tespit edildi!")
                recs.append("📍 \(brightest.constellation) takımyıldızında")
            }
            
            if recognizedStars.count > 3 {
                recs.append("🎯 \(recognizedStars.count) yıldız tanındı")
            }
            
            // Suggest nearby interesting objects
            recs.append("💡 Yakında: M42 Orion Nebulası")
        }
        
        DispatchQueue.main.async {
            self.recommendations = recs
        }
    }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate

extension AIStarRecognitionService: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        
        // Process every 5th frame to reduce CPU load
        if Int.random(in: 0..<5) == 0 {
            processFrame(pixelBuffer)
        }
    }
}

// MARK: - Supporting Types

struct ImagePoint {
    let location: CGPoint
    let brightness: Float
    let color: StarColor
}

enum StarColor {
    case blue, white, yellow, orange, red
    
    var temperature: Double {
        switch self {
        case .blue: return 20000
        case .white: return 10000
        case .yellow: return 6000
        case .orange: return 4000
        case .red: return 3000
        }
    }
}

struct DetectedPattern {
    let points: [ImagePoint]
    let type: PatternType
    
    enum PatternType {
        case linear, triangle, cross, w_shape, dipper
    }
}

struct StarPattern {
    let name: String
    let stars: [String]
    let geometry: Geometry
    let constellation: String
    
    enum Geometry {
        case linear(spacing: Double)
        case triangle
        case cross
        case w_shape
        case dipper
    }
}

struct PatternMatch {
    let pattern: StarPattern
    let confidence: Float
    let detectedPoints: [ImagePoint]
}

struct RecognizedStar: Identifiable {
    let id = UUID()
    let star: Star
    let confidence: Float
    let altitude: Double
    let azimuth: Double
    let constellation: String
}

struct DetectedCelestialObject: Identifiable {
    let id = UUID()
    let type: ObjectType
    let name: String
    let position: CGPoint
    let confidence: Float
    
    enum ObjectType {
        case star, planet, satellite, nebula, galaxy, meteor
    }
}

// MARK: - AI Recognition View

struct AIRecognitionView: View {
    @StateObject private var aiService = AIStarRecognitionService.shared
    @State private var showCamera = false
    
    var body: some View {
        ZStack {
            // Camera preview
            CameraPreview(session: aiService.session)
                .ignoresSafeArea()
            
            // AR overlay with recognized stars
            VStack {
                // Top info bar
                TopInfoBar(service: aiService)
                    .padding()
                
                Spacer()
                
                // Recognized stars list
                if !aiService.recognizedStars.isEmpty {
                    RecognizedStarsOverlay(stars: aiService.recognizedStars)
                        .padding()
                }
                
                Spacer()
                
                // Recommendations
                RecommendationsBar(recommendations: aiService.recommendations)
                    .padding()
            }
            
            // Crosshair - Simple version
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Image(systemName: "plus")
                        .font(.largeTitle)
                        .foregroundColor(.cyan)
                    Spacer()
                }
                Spacer()
            }
        }
        .onAppear {
            aiService.setupCamera()
            aiService.startRecognition()
        }
        .onDisappear {
            aiService.stopRecognition()
        }
    }
}

// Simple placeholder for camera preview on iOS
#if os(iOS)
struct CameraPreview: View {
    let session: AVCaptureSession?
    
    var body: some View {
        Color.black
            .overlay(
                Text("Camera Preview")
                    .foregroundColor(.white.opacity(0.3))
            )
    }
}
#endif

struct TopInfoBar: View {
    @ObservedObject var service: AIStarRecognitionService
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("AI Yıldız Tanıma")
                    .font(.headline)
                    .foregroundColor(.white)
                
                if service.isProcessing {
                    HStack(spacing: 4) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Analiz ediliyor...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
            }
            
            Spacer()
            
            if service.confidence > 0 {
                VStack(spacing: 4) {
                    Text("\(Int(service.confidence * 100))%")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.cyan)
                    
                    Text("Güven")
                        .font(.caption2)
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
                .cornerRadius(12)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct RecognizedStarsOverlay: View {
    let stars: [RecognizedStar]
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(stars, id: \.star.name) { recognized in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "star.fill")
                                .foregroundColor(.yellow)
                            
                            Text(recognized.star.name)
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        
                        Text(recognized.constellation)
                            .font(.caption)
                            .foregroundColor(.cyan)
                        
                        HStack(spacing: 8) {
                            Label("\(Int(recognized.confidence * 100))%", systemImage: "checkmark.circle.fill")
                                .font(.caption2)
                                .foregroundColor(.green)
                            
                            Label("\(String(format: "%.1f", recognized.star.magnitude))m", systemImage: "sparkle")
                                .font(.caption2)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
        }
    }
}

struct RecommendationsBar: View {
    let recommendations: [String]
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(recommendations, id: \.self) { rec in
                Text(rec)
                    .font(.subheadline)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(.ultraThinMaterial)
                    .cornerRadius(20)
            }
        }
    }
}

#Preview {
    AIRecognitionView()
}
