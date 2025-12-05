//
//  RealTime3DSkyView.swift
//  GalacticalMap
//

import SwiftUI
import SceneKit
import CoreMotion

struct RealTime3DSkyView: View {
    @State private var isVRMode = false
    @State private var showInfo = true
    
    var body: some View {
        NavigationStack {
            ZStack {
                if isVRMode {
                    HStack(spacing: 0) {
                        SkySceneView()
                        SkySceneView()
                    }
                    .ignoresSafeArea()
                } else {
                    SkySceneView()
                        .ignoresSafeArea()
                }
                VStack {
                    HStack {
                        Text("3D Sky")
                            .foregroundColor(.white)
                        Spacer()
                        Toggle("VR Mode", isOn: $isVRMode)
                            .labelsHidden()
                    }
                    .padding(.horizontal, 12)
                    .padding(.top, 10)
                    Spacer()
                }
                if showInfo {
                    ZStack(alignment: .topTrailing) {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("How to use 3D Sky")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("• View with a 3D headset (cardboard).\n• Toggle \"VR Mode\" for split view.\n• Drag to look around, pinch to zoom.\n• Hold your phone steady and landscape.")
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
                        Button {
                            showInfo = false
                        } label: {
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
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("3D Sky")
            .onAppear { isVRMode = true }
        }
    }
}

struct SkySceneView: UIViewRepresentable {
    func makeUIView(context: Context) -> SCNView {
        let v = SCNView()
        let scene = SCNScene()
        v.scene = scene
        v.backgroundColor = .black
        v.pointOfView = SCNNode()
        let camera = SCNCamera()
        camera.fieldOfView = 90
        v.pointOfView?.camera = camera
        let sphere = SCNSphere(radius: 10)
        sphere.isGeodesic = true
        let mat = SCNMaterial()
        mat.isDoubleSided = true
        mat.diffuse.contents = starTexture()
        sphere.firstMaterial = mat
        let dome = SCNNode(geometry: sphere)
        dome.scale = SCNVector3(-1, 1, 1)
        scene.rootNode.addChildNode(dome)
        context.coordinator.view = v
        context.coordinator.dome = dome
        context.coordinator.cameraNode = v.pointOfView
        context.coordinator.startMotion()
        v.isUserInteractionEnabled = true
        let pan = UIPanGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
        let pinch = UIPinchGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handlePinch(_:)))
        v.addGestureRecognizer(pan)
        v.addGestureRecognizer(pinch)
        return v
    }
    func updateUIView(_ uiView: SCNView, context: Context) {}
    func makeCoordinator() -> Coordinator { Coordinator() }
    class Coordinator: NSObject {
        let motion = CMMotionManager()
        weak var view: SCNView?
        weak var cameraNode: SCNNode?
        weak var dome: SCNNode?
        private var baseYaw: Float = 0
        private var basePitch: Float = 0
        func startMotion() {
            motion.deviceMotionUpdateInterval = 1.0 / 60.0
            motion.startDeviceMotionUpdates(using: .xMagneticNorthZVertical, to: .main) { [weak self] m, _ in
                guard let self = self, let m = m, let cam = self.view?.pointOfView else { return }
                let q = m.attitude.quaternion
                cam.orientation = SCNQuaternion(q.x, q.y, q.z, q.w)
            }
        }
        deinit { motion.stopDeviceMotionUpdates() }
        @objc func handlePan(_ gr: UIPanGestureRecognizer) {
            let t = gr.translation(in: gr.view)
            if gr.state == .began {
                baseYaw = dome?.eulerAngles.y ?? 0
                basePitch = dome?.eulerAngles.x ?? 0
            }
            let yawDelta = Float(t.x) / 200.0
            let pitchDelta = Float(t.y) / 200.0
            dome?.eulerAngles.y = baseYaw - yawDelta
            dome?.eulerAngles.x = max(min(basePitch - pitchDelta, Float.pi/2 - 0.1), -Float.pi/2 + 0.1)
        }
        @objc func handlePinch(_ gr: UIPinchGestureRecognizer) {
            guard let cam = cameraNode?.camera else { return }
            var fov = cam.fieldOfView
            if gr.state == .changed {
                fov = Double(max(40, min(110, fov / Double(gr.scale))))
                cam.fieldOfView = fov
                gr.scale = 1.0
            }
        }
    }
    private func starTexture() -> UIImage {
        let size = CGSize(width: 1024, height: 512)
        UIGraphicsBeginImageContext(size)
        UIColor.black.setFill()
        UIBezierPath(rect: CGRect(origin: .zero, size: size)).fill()
        for _ in 0..<800 {
            let x = CGFloat.random(in: 0...size.width)
            let y = CGFloat.random(in: 0...size.height)
            let r = CGFloat.random(in: 0.5...1.8)
            UIColor(white: 1.0, alpha: 0.9).setFill()
            UIBezierPath(ovalIn: CGRect(x: x, y: y, width: r, height: r)).fill()
        }
        let img = UIGraphicsGetImageFromCurrentImageContext() ?? UIImage()
        UIGraphicsEndImageContext()
        return img
    }
}

#Preview { RealTime3DSkyView() }
