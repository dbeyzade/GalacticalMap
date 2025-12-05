//
//  RadioAstronomyView.swift
//  GalacticalMap
//
//  Radyo astronomi - Pulsar sinyalleri
//

import SwiftUI
import Combine
import AVFoundation

struct RadioAstronomyView: View {
    @State private var selectedPulsar: Pulsar?
    @State private var isListening = false
    @State private var signalStrength: Double = 0.0
    @StateObject private var audioManager = PulsarAudioManager()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Signal Visualizer
                    SignalVisualizerView(isListening: $isListening, strength: $signalStrength)
                    
                    // Controls
                    HStack(spacing: 20) {
                        Button(action: {
                            isListening.toggle()
                            if isListening {
                                if let pulsar = selectedPulsar {
                                    audioManager.playPulsarSound(frequency: pulsar.hz)
                                } else {
                                    // Default noise if no pulsar selected
                                    audioManager.playStaticNoise()
                                }
                            } else {
                                audioManager.stop()
                            }
                        }) {
                            Label(isListening ? "Stop" : "Listen", systemImage: isListening ? "stop.fill" : "play.fill")
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(isListening ? Color.red : Color.green)
                                .foregroundColor(.white)
                                .cornerRadius(10)
                        }
                    }
                    
                    if selectedPulsar == nil {
                        Text("Select a pulsar to listen")
                            .foregroundColor(.yellow)
                            .font(.caption)
                    } else {
                        Text("Selected: \(selectedPulsar!.name)")
                            .foregroundColor(.cyan)
                            .font(.headline)
                    }
                    
                    // Famous Pulsars
                    VStack(alignment: .leading, spacing: 15) {
                        Text("📻 Famous Pulsars")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(Pulsar.famous) { pulsar in
                            PulsarCard(pulsar: pulsar)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 10)
                                        .stroke(selectedPulsar?.id == pulsar.id ? Color.green : Color.clear, lineWidth: 2)
                                )
                                .onTapGesture {
                                    selectedPulsar = pulsar
                                    if isListening {
                                        audioManager.playPulsarSound(frequency: pulsar.hz)
                                    }
                                }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("📻 Listening Signal")
            .background(Color.black.ignoresSafeArea())
            .onDisappear {
                audioManager.stop()
                isListening = false
            }
        }
    }
}

class PulsarAudioManager: ObservableObject {
    private var timer: Timer?
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    
    // Simple beep sound generation
    func playPulsarSound(frequency: Double) {
        stop()
        
        // Limit frequency for audio comfort (1Hz - 20Hz range for beats)
        // If frequency is high (e.g. 716Hz), we play a tone.
        // If frequency is low (e.g. 1.3Hz), we play rhythmic clicks.
        
        let interval = 1.0 / frequency
        
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { _ in
            AudioServicesPlaySystemSound(1103) // Tock sound
        }
    }
    
    func playStaticNoise() {
        stop()
        // Play static noise (simulation)
    }
    
    func stop() {
        timer?.invalidate()
        timer = nil
    }
}

struct SignalVisualizerView: View {
    @Binding var isListening: Bool
    @Binding var strength: Double
    @State private var waveOffset: CGFloat = 0
    
    var body: some View {
        VStack(spacing: 15) {
            Text("📡 Signal")
                .font(.headline)
                .foregroundColor(.white)
            
            ZStack {
                // Waveform
                WaveformShape(offset: waveOffset, amplitude: isListening ? 0.3 : 0.05)
                    .stroke(Color.green, lineWidth: 2)
                    .frame(height: 100)
                    .onAppear {
                        if isListening {
                            withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                                waveOffset = 360
                            }
                        }
                    }
            }
            .background(Color.black.opacity(0.5))
            .cornerRadius(10)
            
            Text(isListening ? "Listening..." : "Off")
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
        .onChange(of: isListening) { _, newValue in
            if newValue {
                withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                    waveOffset = 360
                }
            } else {
                waveOffset = 0
            }
        }
        .onReceive(Timer.publish(every: 0.2, on: .main, in: .common).autoconnect()) { _ in
            if isListening {
                strength = Double.random(in: 0...1)
                waveOffset = (waveOffset + 10).truncatingRemainder(dividingBy: 360)
            }
        }
    }
}

struct WaveformShape: Shape {
    var offset: CGFloat
    var amplitude: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let width = rect.width
        let height = rect.height
        let midHeight = height / 2
        
        path.move(to: CGPoint(x: 0, y: midHeight))
        
        for x in stride(from: 0, through: width, by: 1) {
            let relativeX = x / width
            let sine = sin((relativeX + offset / 360) * .pi * 4)
            let y = midHeight + sine * midHeight * amplitude
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        return path
    }
}

struct PulsarCard: View {
    let pulsar: Pulsar
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(pulsar.name)
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                Text(pulsar.frequency)
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
            
                Text(pulsar.distance)
                    .font(.caption)
                    .foregroundColor(.gray)
            
            Text(pulsar.description)
                .font(.caption2)
                .foregroundColor(.gray)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

struct Pulsar: Identifiable {
    let id = UUID()
    let name: String
    let frequency: String
    let distance: String
    let description: String
    
    var hz: Double {
        // Parse "1.337 Hz" -> 1.337
        let value = frequency.replacingOccurrences(of: " Hz", with: "")
            .replacingOccurrences(of: ",", with: "")
        return Double(value) ?? 1.0
    }
    
    static let famous: [Pulsar] = [
        Pulsar(name: "PSR B1919+21", frequency: "1.337 Hz", distance: "2,283 light-years", description: "First discovered pulsar (1967)"),
        Pulsar(name: "Vela Pulsar", frequency: "11.2 Hz", distance: "959 light-years", description: "Brightest pulsar"),
        Pulsar(name: "Crab Pulsar", frequency: "30 Hz", distance: "6,500 light-years", description: "At the center of the Crab Nebula"),
        Pulsar(name: "PSR J1748-2446ad", frequency: "716 Hz", distance: "18,000 light-years", description: "Fastest spinning pulsar")
    ]
}

#Preview {
    RadioAstronomyView()
}
