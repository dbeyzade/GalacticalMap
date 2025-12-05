import SwiftUI

struct MainTabView: View {
    @StateObject private var satelliteViewModel = SatelliteViewModel()
    @StateObject private var starMapViewModel = StarMapViewModel()
    @StateObject private var anomalyViewModel = AnomalyViewModel()
    @State private var showIntro = true
    @State private var selectedTab: Tab = .home
    
    init() {
        UITabBar.appearance().isHidden = true
        UITabBar.appearance().barTintColor = .clear
        UITabBar.appearance().backgroundColor = .clear
        UITabBar.appearance().backgroundImage = UIImage()
        UITabBar.appearance().shadowImage = UIImage()
    }
    
    var body: some View {
        ZStack {
            SpaceBackgroundView()
                .ignoresSafeArea()
            
            TabView(selection: $selectedTab) {
                MarsEyesView()
                    .tag(Tab.mars)
                
                EyesOnAsteroidsView()
                    .tag(Tab.asteroids)
                
                HomeDashboardView()
                    .tag(Tab.home)
                
                SatellitePassView()
                    .tag(Tab.passes)
                
                AdvancedFavoritesView()
                    .tag(Tab.more)
            }
            
            VStack {
                Spacer()
                CustomTabBar(selectedTab: $selectedTab)
            }
            .ignoresSafeArea(.keyboard)
            .ignoresSafeArea(.container, edges: .bottom)
        }
        .fullScreenCover(isPresented: $showIntro) {
            StartupVideoView { showIntro = false }
        }
    }
}

struct SpaceBackgroundView: View {
    @State private var animateStars = false
    
    var body: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.05, blue: 0.15),
                    Color(red: 0.1, green: 0.05, blue: 0.2),
                    Color.black
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            GeometryReader { geometry in
                ForEach(0..<100, id: \.self) { _ in
                    Circle()
                        .fill(Color.white.opacity(Double.random(in: 0.3...0.9)))
                        .frame(width: CGFloat.random(in: 1...3))
                        .position(
                            x: CGFloat.random(in: 0...geometry.size.width),
                            y: CGFloat.random(in: 0...geometry.size.height)
                        )
                        .blur(radius: CGFloat.random(in: 0...1))
                        .scaleEffect(animateStars ? 1.2 : 0.8)
                        .animation(
                            Animation.easeInOut(duration: Double.random(in: 2...4))
                                .repeatForever(autoreverses: true)
                                .delay(Double.random(in: 0...2)),
                            value: animateStars
                        )
                }
            }
        }
        .onAppear { animateStars = true }
    }
}

#Preview {
    MainTabView()
        .environmentObject(LocationManager())
        .environmentObject(SatelliteViewModel())
        .environmentObject(StarMapViewModel())
        .environmentObject(AnomalyViewModel())
}
