import SwiftUI

enum Tab: String, CaseIterable {
    case mars = "Mars"
    case asteroids = "Asteroids"
    case home = "Home"
    case passes = "Passes"
    case more = "More"
    
    var icon: String {
        switch self {
        case .mars: return "🪐"
        case .asteroids: return "👁️"
        case .home: return "🚀"
        case .passes: return "🛰️"
        case .more: return "🌌"
        }
    }
}

struct CustomTabBar: View {
    @Binding var selectedTab: Tab
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = tab
                    }
                } label: {
                    VStack(spacing: 4) {
                        Text(tab.icon)
                            .font(.system(size: 24))
                            .scaleEffect(selectedTab == tab ? 1.25 : 1.0)
                        
                        Text(tab.rawValue)
                            .font(.caption2)
                            .fontWeight(selectedTab == tab ? .bold : .regular)
                            .foregroundColor(selectedTab == tab ? .cyan : .gray)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(Color.clear)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.bottom, 34) // For Home Indicator
        .padding(.top, 10)
        // Background removed
    }
}

extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
