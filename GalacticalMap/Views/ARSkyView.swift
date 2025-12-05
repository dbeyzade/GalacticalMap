//
//  ARSkyView.swift
//  GalacticalMap
//

import SwiftUI
import ARKit
import SceneKit
import AVFoundation

struct ARSkyView: View {
    @State private var isActive = true
    @State private var heading: Double = 0
    @State private var pitch: Double = 0
    @State private var showInfo = true
    @State private var showError = false
    @State private var errorText = ""
    var body: some View {
        NavigationStack {
            ZStack {
                ARCameraView(isActive: isActive, onOrientation: { h, p in
                    heading = h
                    pitch = p
                })
                .ignoresSafeArea()
                VStack {
                    HStack {
                        Text("AR Sky")
                            .font(.headline)
                            .foregroundColor(.white)
                        Spacer()
                        Button(action: { isActive.toggle() }) {
                            Text(isActive ? "Stop" : "Start")
                                .font(.subheadline)
                                .padding(8)
                                .background(isActive ? Color.red.opacity(0.8) : Color.green.opacity(0.8))
                                .foregroundColor(.white)
                                .clipShape(Capsule())
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    Spacer()
                    HStack {
                        Text(String(format: "Heading %.0f°", heading))
                            .foregroundColor(.white)
                        Spacer()
                        Text(String(format: "Pitch %.0f°", pitch))
                            .foregroundColor(.white)
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.35))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal, 12)
                    .padding(.bottom, 16)
                }
                if showInfo {
                    VStack(spacing: 8) {
                        HStack {
                            Text("How to use AR Sky")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button { showInfo = false } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        Text("Point your phone to the sky and move slowly to calibrate. Requires camera permission and an ARKit‑capable device.")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(Color.black.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
                if showError {
                    VStack(spacing: 8) {
                        HStack {
                            Text("AR Unavailable")
                                .font(.headline)
                                .foregroundColor(.white)
                            Spacer()
                            Button { showError = false } label: {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.white)
                            }
                        }
                        Text(errorText)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.9))
                            .multilineTextAlignment(.leading)
                    }
                    .padding(12)
                    .background(Color.red.opacity(0.6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal, 16)
                    .padding(.top, 74)
                    .frame(maxWidth: .infinity, alignment: .top)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("AR")
            .onAppear {
                if !ARConfiguration.isSupported {
                    isActive = false
                    errorText = "AR is not supported on this device (e.g., Simulator). Please use a real device with ARKit support."
                    showError = true
                    return
                }
                let status = AVCaptureDevice.authorizationStatus(for: .video)
                switch status {
                case .authorized:
                    isActive = true
                case .notDetermined:
                    AVCaptureDevice.requestAccess(for: .video) { granted in
                        DispatchQueue.main.async {
                            self.isActive = granted
                            if !granted {
                                self.errorText = "Camera permission is required for AR. Enable it in Settings > Privacy > Camera."
                                self.showError = true
                            }
                        }
                    }
                default:
                    isActive = false
                    errorText = "Camera permission is required for AR. Enable it in Settings > Privacy > Camera."
                    showError = true
                }
            }
        }
    }
}

struct ARCameraView: UIViewRepresentable {
    let isActive: Bool
    let onOrientation: (Double, Double) -> Void
    func makeUIView(context: Context) -> ARSCNView {
        let v = ARSCNView()
        v.automaticallyUpdatesLighting = true
        v.delegate = context.coordinator
        let tap = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        v.addGestureRecognizer(tap)
        return v
    }
    func updateUIView(_ uiView: ARSCNView, context: Context) {
        if isActive {
            let conf = ARWorldTrackingConfiguration()
            conf.worldAlignment = .gravityAndHeading
            conf.planeDetection = []
            uiView.session.run(conf, options: [.resetTracking, .removeExistingAnchors])
        } else {
            uiView.session.pause()
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(onOrientation: onOrientation) }
    class Coordinator: NSObject, ARSCNViewDelegate {
        let onOrientation: (Double, Double) -> Void
        init(onOrientation: @escaping (Double, Double) -> Void) { self.onOrientation = onOrientation }
        @objc func handleTap(_ g: UITapGestureRecognizer) {
            guard let v = g.view as? ARSCNView else { return }
            let p = g.location(in: v)
            let results = v.hitTest(p, types: [.featurePoint])
            if let r = results.first {
                let a = ARAnchor(transform: r.worldTransform)
                v.session.add(anchor: a)
            }
        }
        func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
            let n = SCNNode()
            let s = SCNSphere(radius: 0.03)
            s.firstMaterial?.diffuse.contents = UIColor.cyan
            let sn = SCNNode(geometry: s)
            n.addChildNode(sn)
            return n
        }
        func session(_ session: ARSession, didUpdate frame: ARFrame) {
            let ori = frame.camera.eulerAngles
            let yawDeg = Double(ori.y * 180.0 / .pi)
            let headingDeg = fmod((360.0 - yawDeg), 360.0)
            let pitchDeg = Double(ori.x * 180.0 / .pi)
            onOrientation(headingDeg, pitchDeg)
        }
    }
}

#Preview { ARSkyView() }
