//
//  SocialFeaturesView.swift
//  GalacticalMap
//
//  Social features, achievements, leaderboard
//  Share your sky observations with the community!
//

import SwiftUI
import Combine
import Social
import MessageUI

class SocialManager: ObservableObject {
    static let shared = SocialManager()
    
    @Published var achievements: [Achievement] = []
    @Published var userStats: UserStatistics
    @Published var leaderboard: [LeaderboardEntry] = []
    @Published var sharedObservations: [SharedObservation] = []
    
    init() {
        self.userStats = UserStatistics()
        loadAchievements()
        loadLeaderboard()
    }
    
    // MARK: - Achievements System
    
    func loadAchievements() {
        achievements = [
            Achievement(
                id: "first_star",
                title: "First Star",
                description: "Discover your first star",
                icon: "star.fill",
                requirement: 1,
                progress: userStats.starsViewed,
                unlocked: userStats.starsViewed >= 1,
                points: 10
            ),
            Achievement(
                id: "star_collector",
                title: "Star Collector",
                description: "Observe 50 different stars",
                icon: "star.circle.fill",
                requirement: 50,
                progress: userStats.starsViewed,
                unlocked: userStats.starsViewed >= 50,
                points: 50
            ),
            Achievement(
                id: "constellation_master",
                title: "Constellation Master",
                description: "Identify 10 constellations",
                icon: "star.leadinghalf.filled",
                requirement: 10,
                progress: userStats.constellationsIdentified,
                unlocked: userStats.constellationsIdentified >= 10,
                points: 100
            ),
            Achievement(
                id: "satellite_tracker",
                title: "Satellite Tracker",
                description: "Track 25 satellites live",
                icon: "antenna.radiowaves.left.and.right",
                requirement: 25,
                progress: userStats.satellitesTracked,
                unlocked: userStats.satellitesTracked >= 25,
                points: 75
            ),
            Achievement(
                id: "night_owl",
                title: "Night Owl",
                description: "Observe the sky 7 nights in a row",
                icon: "moon.stars.fill",
                requirement: 7,
                progress: userStats.consecutiveNights,
                unlocked: userStats.consecutiveNights >= 7,
                points: 150
            ),
            Achievement(
                id: "photographer",
                title: "Astro Photographer",
                description: "Take 100 sky photos",
                icon: "camera.fill",
                requirement: 100,
                progress: userStats.photosTaken,
                unlocked: userStats.photosTaken >= 100,
                points: 200
            ),
            Achievement(
                id: "ar_explorer",
                title: "AR Explorer",
                description: "Spend 1 hour in AR mode",
                icon: "arkit",
                requirement: 60,
                progress: Int(userStats.arModeMinutes),
                unlocked: userStats.arModeMinutes >= 60,
                points: 125
            ),
            Achievement(
                id: "anomaly_hunter",
                title: "Anomaly Hunter",
                description: "Discover 20 sky anomalies",
                icon: "sparkles",
                requirement: 20,
                progress: userStats.anomaliesViewed,
                unlocked: userStats.anomaliesViewed >= 20,
                points: 175
            )
        ]
    }
    
    func checkAndUnlockAchievements() {
        for i in 0..<achievements.count {
            if achievements[i].progress >= achievements[i].requirement && !achievements[i].unlocked {
                achievements[i].unlocked = true
                showAchievementUnlocked(achievements[i])
            }
        }
    }
    
    func showAchievementUnlocked(_ achievement: Achievement) {
        // Show notification/toast
        let notification = UINotificationFeedbackGenerator()
        notification.notificationOccurred(.success)
        
        // Could show a banner or modal
    }
    
    // MARK: - Statistics Tracking
    
    func recordStarView() {
        userStats.starsViewed += 1
        checkAndUnlockAchievements()
    }
    
    func recordSatelliteTracking() {
        userStats.satellitesTracked += 1
        checkAndUnlockAchievements()
    }
    
    func recordPhotoTaken() {
        userStats.photosTaken += 1
        checkAndUnlockAchievements()
    }
    
    func recordAnomalyView() {
        userStats.anomaliesViewed += 1
        checkAndUnlockAchievements()
    }
    
    func recordARTime(minutes: Double) {
        userStats.arModeMinutes += minutes
        checkAndUnlockAchievements()
    }
    
    // MARK: - Leaderboard
    
    func loadLeaderboard() {
        // In production, fetch from server
        leaderboard = [
            LeaderboardEntry(rank: 1, username: "StarGazer123", points: 2500, avatar: "🌟"),
            LeaderboardEntry(rank: 2, username: "AstronomyPro", points: 2200, avatar: "🔭"),
            LeaderboardEntry(rank: 3, username: "SkyWatcher", points: 1950, avatar: "🌌"),
            LeaderboardEntry(rank: 4, username: "CosmicExplorer", points: 1800, avatar: "🚀"),
            LeaderboardEntry(rank: 5, username: "You", points: userStats.totalPoints, avatar: "👤", isCurrentUser: true)
        ]
    }
    
    // MARK: - Sharing
    
    func shareObservation(title: String, description: String, image: UIImage?) {
        let observation = SharedObservation(
            id: UUID().uuidString,
            title: title,
            description: description,
            username: "User",
            date: Date(),
            likes: 0,
            comments: 0,
            imageData: image?.pngData()
        )
        
        sharedObservations.insert(observation, at: 0)
        
        // Share to social media
        shareToSocialMedia(observation: observation, image: image)
    }
    
    func shareToSocialMedia(observation: SharedObservation, image: UIImage?) {
        let text = """
        🌟 \(observation.title)
        
        \(observation.description)
        
        #GalacticalMap #Astronomy #Stargazing
        """
        
        let activityItems: [Any] = image != nil ? [text, image!] : [text]
        
        let activityController = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true)
        }
    }
}

// MARK: - Models

struct Achievement: Identifiable {
    let id: String
    let title: String
    let description: String
    let icon: String
    let requirement: Int
    var progress: Int
    var unlocked: Bool
    let points: Int
    
    var progressPercentage: Double {
        min(Double(progress) / Double(requirement), 1.0)
    }
}

struct UserStatistics {
    var starsViewed: Int = 0
    var satellitesTracked: Int = 0
    var anomaliesViewed: Int = 0
    var constellationsIdentified: Int = 0
    var photosTaken: Int = 0
    var arModeMinutes: Double = 0
    var consecutiveNights: Int = 0
    var totalPoints: Int = 0
    
    var level: Int {
        totalPoints / 100
    }
}

struct LeaderboardEntry: Identifiable {
    let id = UUID()
    let rank: Int
    let username: String
    let points: Int
    let avatar: String
    var isCurrentUser: Bool = false
}

struct SharedObservation: Identifiable {
    let id: String
    let title: String
    let description: String
    let username: String
    let date: Date
    var likes: Int
    var comments: Int
    let imageData: Data?
}

// MARK: - Social Features View

struct SocialFeaturesView: View {
    @StateObject private var socialManager = SocialManager.shared
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Tab Picker
                    Picker("", selection: $selectedTab) {
                        Text("Başarılar").tag(0)
                        Text("Liderlik").tag(1)
                        Text("Topluluk").tag(2)
                        Text("İstatistikler").tag(3)
                    }
                    .pickerStyle(.segmented)
                    .padding()
                    
                    // Content
                    TabView(selection: $selectedTab) {
                        AchievementsTab(manager: socialManager)
                            .tag(0)
                        
                        LeaderboardTab(manager: socialManager)
                            .tag(1)
                        
                        CommunityTab(manager: socialManager)
                            .tag(2)
                        
                        StatisticsTab(manager: socialManager)
                            .tag(3)
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                }
            }
            .navigationTitle("Sosyal")
        }
    }
}

struct AchievementsTab: View {
    @ObservedObject var manager: SocialManager
    
    var unlockedAchievements: [Achievement] {
        manager.achievements.filter { $0.unlocked }
    }
    
    var lockedAchievements: [Achievement] {
        manager.achievements.filter { !$0.unlocked }
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Progress Overview
                VStack(spacing: 12) {
                    Text("Başarı İlerlemesi")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack(spacing: 20) {
                        StatCircle(
                            value: unlockedAchievements.count,
                            total: manager.achievements.count,
                            label: "Kilitsiz",
                            color: .green
                        )
                        
                        StatCircle(
                            value: manager.userStats.totalPoints,
                            total: nil,
                            label: "Puan",
                            color: .cyan
                        )
                        
                        StatCircle(
                            value: manager.userStats.level,
                            total: nil,
                            label: "Seviye",
                            color: .purple
                        )
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                
                // Unlocked Achievements
                if !unlockedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🏆 Kazanılan Başarılar")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal)
                        
                        ForEach(unlockedAchievements) { achievement in
                            AchievementCard(achievement: achievement, unlocked: true)
                                .padding(.horizontal)
                        }
                    }
                }
                
                // Locked Achievements
                if !lockedAchievements.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("🔒 Kilitli Başarılar")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                            .padding(.horizontal)
                        
                        ForEach(lockedAchievements) { achievement in
                            AchievementCard(achievement: achievement, unlocked: false)
                                .padding(.horizontal)
                        }
                    }
                }
            }
            .padding(.vertical)
        }
    }
}

struct AchievementCard: View {
    let achievement: Achievement
    let unlocked: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(unlocked ? Color.yellow.opacity(0.3) : Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Image(systemName: achievement.icon)
                    .font(.title2)
                    .foregroundColor(unlocked ? .yellow : .white.opacity(0.5))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(achievement.title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(achievement.description)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
                
                // Progress bar
                if !unlocked {
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 6)
                            
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.cyan)
                                .frame(width: geo.size.width * achievement.progressPercentage, height: 6)
                        }
                    }
                    .frame(height: 6)
                    
                    Text("\(achievement.progress)/\(achievement.requirement)")
                        .font(.caption2)
                        .foregroundColor(.cyan)
                }
            }
            
            Spacer()
            
            // Points
            VStack(spacing: 4) {
                Text("\(achievement.points)")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.cyan)
                
                Text("puan")
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .opacity(unlocked ? 1.0 : 0.6)
    }
}

struct LeaderboardTab: View {
    @ObservedObject var manager: SocialManager
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                Text("🏆 Liderlik Tablosu")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .padding()
                
                // Top 3
                HStack(alignment: .bottom, spacing: 12) {
                    // 2nd place
                    if manager.leaderboard.count > 1 {
                        PodiumPosition(entry: manager.leaderboard[1], position: 2)
                    }
                    
                    // 1st place
                    if manager.leaderboard.count > 0 {
                        PodiumPosition(entry: manager.leaderboard[0], position: 1)
                    }
                    
                    // 3rd place
                    if manager.leaderboard.count > 2 {
                        PodiumPosition(entry: manager.leaderboard[2], position: 3)
                    }
                }
                .padding()
                
                // Rest of leaderboard
                VStack(spacing: 12) {
                    ForEach(manager.leaderboard.dropFirst(3)) { entry in
                        LeaderboardRow(entry: entry)
                    }
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct PodiumPosition: View {
    let entry: LeaderboardEntry
    let position: Int
    
    var height: CGFloat {
        position == 1 ? 150 : position == 2 ? 120 : 100
    }
    
    var color: Color {
        position == 1 ? .yellow : position == 2 ? .gray : Color(red: 0.8, green: 0.5, blue: 0.2)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            Text(entry.avatar)
                .font(.largeTitle)
            
            Text(entry.username)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            Text("\(entry.points)")
                .font(.headline)
                .foregroundColor(.cyan)
            
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.3))
                .frame(width: 80, height: height)
                .overlay(
                    Text("#\(position)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                )
        }
    }
}

struct LeaderboardRow: View {
    let entry: LeaderboardEntry
    
    var body: some View {
        HStack(spacing: 16) {
            // Rank
            Text("#\(entry.rank)")
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.cyan)
                .frame(width: 40)
            
            // Avatar
            Text(entry.avatar)
                .font(.title2)
            
            // Username
            Text(entry.username)
                .font(.subheadline)
                .foregroundColor(.white)
                .fontWeight(entry.isCurrentUser ? .bold : .regular)
            
            Spacer()
            
            // Points
            Text("\(entry.points)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.cyan)
        }
        .padding()
        .background(entry.isCurrentUser ? Color.cyan.opacity(0.2) : Color.white.opacity(0.1))
        .cornerRadius(12)
    }
}

struct CommunityTab: View {
    @ObservedObject var manager: SocialManager
    @State private var showingShareSheet = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Share button
                Button {
                    showingShareSheet = true
                } label: {
                    HStack {
                        Image(systemName: "square.and.arrow.up.fill")
                        Text("Gözleminizi Paylaşın")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.cyan)
                    .foregroundColor(.black)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                // Community observations
                ForEach(manager.sharedObservations) { observation in
                    ObservationCard(observation: observation)
                        .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
    }
}

struct ObservationCard: View {
    let observation: SharedObservation
    @State private var liked = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                Text(observation.username)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(observation.date, style: .relative)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // Image
            if let imageData = observation.imageData,
               let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .cornerRadius(12)
            }
            
            // Title & description
            Text(observation.title)
                .font(.headline)
                .foregroundColor(.white)
            
            Text(observation.description)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.8))
            
            // Actions
            HStack(spacing: 20) {
                Button {
                    liked.toggle()
                } label: {
                    Label("\(observation.likes + (liked ? 1 : 0))", systemImage: liked ? "heart.fill" : "heart")
                        .foregroundColor(liked ? .red : .white)
                }
                
                Label("\(observation.comments)", systemImage: "bubble.right")
                    .foregroundColor(.white)
                
                Spacer()
                
                Button {
                    // Share
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.white)
                }
            }
            .font(.subheadline)
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct StatisticsTab: View {
    @ObservedObject var manager: SocialManager
    
    var stats: UserStatistics {
        manager.userStats
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Level card
                VStack(spacing: 12) {
                    Text("Seviye \(stats.level)")
                        .font(.system(size: 60, weight: .bold))
                        .foregroundColor(.cyan)
                    
                    Text("\(stats.totalPoints) Toplam Puan")
                        .font(.title3)
                        .foregroundColor(.white)
                    
                    // Progress to next level
                    let nextLevelPoints = (stats.level + 1) * 100
                    let currentProgress = stats.totalPoints % 100
                    
                    VStack(spacing: 8) {
                        GeometryReader { geo in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.white.opacity(0.2))
                                    .frame(height: 12)
                                
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.cyan)
                                    .frame(width: geo.size.width * CGFloat(currentProgress) / 100.0, height: 12)
                            }
                        }
                        .frame(height: 12)
                        
                        Text("Sonraki seviyeye \(100 - currentProgress) puan")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(20)
                .padding(.horizontal)
                
                // Detailed stats
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                    SocialStatCard(
                        title: "Yıldızlar",
                        value: "\(stats.starsViewed)",
                        icon: "star.fill",
                        color: .yellow
                    )
                    
                    SocialStatCard(
                        title: "Uydular",
                        value: "\(stats.satellitesTracked)",
                        icon: "antenna.radiowaves.left.and.right",
                        color: .blue
                    )
                    
                    SocialStatCard(
                        title: "Anomaliler",
                        value: "\(stats.anomaliesViewed)",
                        icon: "sparkles",
                        color: .purple
                    )
                    
                    SocialStatCard(
                        title: "Takımyıldızlar",
                        value: "\(stats.constellationsIdentified)",
                        icon: "star.circle",
                        color: .cyan
                    )
                    
                    SocialStatCard(
                        title: "Fotoğraflar",
                        value: "\(stats.photosTaken)",
                        icon: "camera.fill",
                        color: .orange
                    )
                    
                    SocialStatCard(
                        title: "AR Süresi",
                        value: "\(Int(stats.arModeMinutes))dk",
                        icon: "arkit",
                        color: .green
                    )
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
    }
}

struct SocialStatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(color)
            
            Text(value)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(16)
    }
}

struct StatCircle: View {
    let value: Int
    let total: Int?
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .stroke(color.opacity(0.3), lineWidth: 4)
                    .frame(width: 60, height: 60)
                
                if let total = total {
                    Circle()
                        .trim(from: 0, to: CGFloat(value) / CGFloat(total))
                        .stroke(color, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .frame(width: 60, height: 60)
                        .rotationEffect(.degrees(-90))
                }
                
                Text("\(value)")
                    .font(.headline)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
            }
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

#Preview {
    SocialFeaturesView()
}
