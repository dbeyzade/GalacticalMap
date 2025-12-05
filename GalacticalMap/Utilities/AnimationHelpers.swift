//
//  AnimationHelpers.swift
//  GalacticalMap
//
//  Sinematik geçişler ve animasyon yardımcıları
//

import SwiftUI

// MARK: - Sinematik Geçiş Modifierleri

struct CinematicAppearance: ViewModifier {
    @State private var isVisible = false
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .opacity(isVisible ? 1 : 0)
            .scaleEffect(isVisible ? 1 : 0.8)
            .blur(radius: isVisible ? 0 : 10)
            .animation(
                .spring(response: 0.8, dampingFraction: 0.7, blendDuration: 0)
                    .delay(delay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
}

struct SlideInTransition: ViewModifier {
    @State private var isVisible = false
    let edge: Edge
    let delay: Double
    
    func body(content: Content) -> some View {
        content
            .offset(x: offsetX, y: offsetY)
            .opacity(isVisible ? 1 : 0)
            .animation(
                .spring(response: 0.6, dampingFraction: 0.8)
                    .delay(delay),
                value: isVisible
            )
            .onAppear {
                isVisible = true
            }
    }
    
    private var offsetX: CGFloat {
        if !isVisible {
            switch edge {
            case .leading: return -100
            case .trailing: return 100
            default: return 0
            }
        }
        return 0
    }
    
    private var offsetY: CGFloat {
        if !isVisible {
            switch edge {
            case .top: return -100
            case .bottom: return 100
            default: return 0
            }
        }
        return 0
    }
}

struct ParticleEffect: ViewModifier {
    @State private var particles: [Particle] = []
    
    struct Particle: Identifiable {
        let id = UUID()
        var position: CGPoint
        var velocity: CGVector
        var opacity: Double
        var scale: Double
    }
    
    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    ZStack {
                        ForEach(particles) { particle in
                            Circle()
                                .fill(Color.white)
                                .frame(width: 3, height: 3)
                                .scaleEffect(particle.scale)
                                .opacity(particle.opacity)
                                .position(particle.position)
                        }
                    }
                }
            )
            .onAppear {
                generateParticles()
            }
    }
    
    private func generateParticles() {
        for _ in 0..<20 {
            let particle = Particle(
                position: CGPoint(x: CGFloat.random(in: 0...400), y: CGFloat.random(in: 0...800)),
                velocity: CGVector(dx: CGFloat.random(in: -2...2), dy: CGFloat.random(in: -2...2)),
                opacity: Double.random(in: 0.3...0.8),
                scale: Double.random(in: 0.5...1.5)
            )
            particles.append(particle)
        }
    }
}

struct GlowEffect: ViewModifier {
    let color: Color
    let radius: CGFloat
    
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius, x: 0, y: 0)
            .shadow(color: color.opacity(0.5), radius: radius * 2, x: 0, y: 0)
    }
}

struct PulseEffect: ViewModifier {
    @State private var isPulsing = false
    
    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .animation(
                .easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0
    
    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        .white.opacity(0.3),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

struct RotatingEffect: ViewModifier {
    @State private var rotation: Double = 0
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .rotationEffect(.degrees(rotation))
            .onAppear {
                withAnimation(.linear(duration: duration).repeatForever(autoreverses: false)) {
                    rotation = 360
                }
            }
    }
}

struct FloatingEffect: ViewModifier {
    @State private var offset: CGFloat = 0
    let range: CGFloat
    let duration: Double
    
    func body(content: Content) -> some View {
        content
            .offset(y: offset)
            .onAppear {
                withAnimation(
                    .easeInOut(duration: duration)
                        .repeatForever(autoreverses: true)
                ) {
                    offset = range
                }
            }
    }
}

// MARK: - View Extensions

extension View {
    func cinematicAppearance(delay: Double = 0) -> some View {
        modifier(CinematicAppearance(delay: delay))
    }
    
    func slideIn(from edge: Edge, delay: Double = 0) -> some View {
        modifier(SlideInTransition(edge: edge, delay: delay))
    }
    
    func particleEffect() -> some View {
        modifier(ParticleEffect())
    }
    
    func glow(color: Color = .white, radius: CGFloat = 10) -> some View {
        modifier(GlowEffect(color: color, radius: radius))
    }
    
    func pulse() -> some View {
        modifier(PulseEffect())
    }
    
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
    
    func rotating(duration: Double = 10) -> some View {
        modifier(RotatingEffect(duration: duration))
    }
    
    func floating(range: CGFloat = 10, duration: Double = 2) -> some View {
        modifier(FloatingEffect(range: range, duration: duration))
    }
}

// MARK: - Custom Transitions

extension AnyTransition {
    static var cinematic: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.8).combined(with: .opacity),
            removal: .scale(scale: 1.2).combined(with: .opacity)
        )
    }
    
    static func slide(from edge: Edge) -> AnyTransition {
        .move(edge: edge).combined(with: .opacity)
    }
    
    static var zoomIn: AnyTransition {
        .scale(scale: 0.1).combined(with: .opacity)
    }
    
    static var fadeAndSlide: AnyTransition {
        .opacity.combined(with: .move(edge: .bottom))
    }
}

// MARK: - Loading States

struct LoadingSpinner: View {
    @State private var isRotating = false
    let color: Color
    let size: CGFloat
    
    init(color: Color = .cyan, size: CGFloat = 50) {
        self.color = color
        self.size = size
    }
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(color.opacity(0.2), lineWidth: 4)
                .frame(width: size, height: size)
            
            Circle()
                .trim(from: 0, to: 0.7)
                .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .frame(width: size, height: size)
                .rotationEffect(.degrees(isRotating ? 360 : 0))
                .animation(
                    .linear(duration: 1)
                        .repeatForever(autoreverses: false),
                    value: isRotating
                )
        }
        .onAppear {
            isRotating = true
        }
    }
}

struct CosmicLoadingView: View {
    @State private var animationPhase = 0.0
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.8)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                ZStack {
                    ForEach(0..<3) { index in
                        Circle()
                            .stroke(Color.cyan.opacity(0.5), lineWidth: 2)
                            .frame(width: 80 + CGFloat(index) * 30, height: 80 + CGFloat(index) * 30)
                            .scaleEffect(1 + sin(animationPhase + Double(index) * 0.5) * 0.2)
                    }
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 40))
                        .foregroundColor(.cyan)
                        .rotationEffect(.degrees(animationPhase * 50))
                }
                
                Text("Yükleniyor...")
                    .font(.headline)
                    .foregroundColor(.white)
                
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                animationPhase = 2 * .pi
            }
        }
    }
}

// MARK: - Haptic Feedback

enum HapticStyle {
    case light
    case medium
    case heavy
    case success
    case warning
    case error
}

struct HapticManager {
    static func trigger(_ style: HapticStyle) {
        switch style {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .heavy:
            UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        case .warning:
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        case .error:
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }
}

// MARK: - Gesture Extensions

extension View {
    func onTapWithHaptic(style: HapticStyle = .light, perform action: @escaping () -> Void) -> some View {
        self.onTapGesture {
            HapticManager.trigger(style)
            action()
        }
    }
}
