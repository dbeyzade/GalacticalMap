import SwiftUI

enum SkyWatcherMode: String, CaseIterable, Identifiable {
    case rgb = "RGB"
    case cmyk = "CMYK"
    case nightVision = "Night Vision"
    case autoFocus = "Auto Focus"
    case infrared = "Infrared"
    case ultraViolet = "Ultra Violet"
    case sepia = "Sepia"
    case blackAndWhite = "Black & White"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .rgb: return .red
        case .cmyk: return .cyan
        case .nightVision: return .green
        case .autoFocus: return .blue
        case .infrared: return .orange
        case .ultraViolet: return .purple
        case .sepia: return .brown
        case .blackAndWhite: return .gray
        }
    }
}

struct SkyWatcherModeSelectionView: View {
    let columns = [
        GridItem(.flexible(), spacing: 16),
        GridItem(.flexible(), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            SpaceBackgroundView().ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    Text("Select Camera Mode")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.top, 20)
                    
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(SkyWatcherMode.allCases) { mode in
                            NavigationLink(destination: SkyWatcherCameraView(mode: mode)) {
                                ModeCard(mode: mode)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct ModeCard: View {
    let mode: SkyWatcherMode
    
    var body: some View {
        VStack(spacing: 12) {
            Text(emojiForMode(mode))
                .font(.system(size: 50))
                .frame(height: 60)
                .shadow(color: mode.color.opacity(0.5), radius: 10, x: 0, y: 0)
            
            Text(mode.rawValue)
                .font(.headline)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 140)
        .background(Color.black.opacity(0.6))
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(mode.color, lineWidth: 2)
        )
    }
    
    func emojiForMode(_ mode: SkyWatcherMode) -> String {
        switch mode {
        case .rgb: return "📸"
        case .cmyk: return "🎨"
        case .nightVision: return "🦉"
        case .autoFocus: return "🎯"
        case .infrared: return "🌡️"
        case .ultraViolet: return "🦂"
        case .sepia: return "📜"
        case .blackAndWhite: return "🦓"
        }
    }
}
