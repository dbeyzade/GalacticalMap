import SwiftUI
import AVKit
import AVFoundation

struct StartupVideoView: View {
    var onFinish: () -> Void
    @State private var player: AVPlayer? = nil
    @State private var playerItem: AVPlayerItem? = nil
    @State private var statusObserver: NSKeyValueObservation? = nil
    @State private var fallbackScheduled = false
    @State private var attemptedDiscovery = false
    
    var body: some View {
        ZStack {
            if let player {
                PlayerContainer(player: player)
                    .ignoresSafeArea()
                    .onAppear {
                        player.isMuted = true
                        if player.timeControlStatus != .playing {
                            player.play()
                        }
                    }
            } else {
                Color.black.ignoresSafeArea()
            }
            VStack {
                HStack {
                    Spacer()
                    Button("Skip") { onFinish() }
                        .padding(10)
                        .background(Color.white.opacity(0.2))
                        .foregroundColor(.white)
                        .clipShape(Capsule())
                        .padding()
                }
                Spacer()
            }
        }
        .onAppear {
            let session = AVAudioSession.sharedInstance()
            try? session.setCategory(.playback, mode: .moviePlayback, options: [.mixWithOthers])
            try? session.setActive(true)
            if let url = resolveVideoURL() {
                let item = AVPlayerItem(url: url)
                playerItem = item
                let p = AVPlayer(playerItem: item)
                p.isMuted = true
                p.automaticallyWaitsToMinimizeStalling = false
                player = p
                statusObserver = item.observe(\.status, options: [.initial, .new]) { _, _ in
                    if item.status == .readyToPlay {
                        p.play()
                    }
                }
            } else {
                attemptedDiscovery = true
                if let hls = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8") {
                    let item = AVPlayerItem(url: hls)
                    playerItem = item
                    let p = AVPlayer(playerItem: item)
                    p.isMuted = true
                    p.automaticallyWaitsToMinimizeStalling = false
                    player = p
                    statusObserver = item.observe(\.status, options: [.initial, .new]) { _, _ in
                        if item.status == .readyToPlay { p.play() }
                    }
                }
            }
            if !fallbackScheduled {
                fallbackScheduled = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    ensurePlaybackOrFallback()
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                    if let p = player {
                        if p.timeControlStatus != .playing {
                            onFinish()
                        }
                    } else {
                        onFinish()
                    }
                }
            }
            NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: nil, queue: .main) { _ in
                onFinish()
            }
        }
    }
    
    private func resolveVideoURL() -> URL? {
        if let introMp4 = Bundle.main.url(forResource: "intro", withExtension: "mp4") { return introMp4 }
        if let introMov = Bundle.main.url(forResource: "intro", withExtension: "mov") { return introMov }
        if let bundleURL123 = Bundle.main.url(forResource: "123", withExtension: "mp4") { return bundleURL123 }
        if let docURL123 = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false).appendingPathComponent("123.mp4"), FileManager.default.fileExists(atPath: docURL123.path) { return docURL123 }
        if let hls = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8") { return hls }
        return nil
    }

    private func discoverRemoteVideo(completion: @escaping (URL?) -> Void) {}

    struct PlayerContainer: UIViewRepresentable {
        let player: AVPlayer
        func makeUIView(context: Context) -> UIView {
            let view = PlayerUIView()
            (view.layer as? AVPlayerLayer)?.player = player
            (view.layer as? AVPlayerLayer)?.videoGravity = .resizeAspectFill
            return view
        }
        func updateUIView(_ uiView: UIView, context: Context) {}
    }
    
    class PlayerUIView: UIView {
        override static var layerClass: AnyClass { AVPlayerLayer.self }
    }

    private func ensurePlaybackOrFallback() {
        guard let p = player else { return }
        if p.timeControlStatus != .playing {
            p.playImmediately(atRate: 1.0)
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if p.timeControlStatus != .playing {
                    if let hls = URL(string: "https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_4x3/gear1/prog_index.m3u8") {
                        let item = AVPlayerItem(url: hls)
                        playerItem = item
                        p.replaceCurrentItem(with: item)
                        p.play()
                    }
                }
            }
        }
    }
}