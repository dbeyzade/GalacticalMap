//
//  MeteorShowerView.swift
//  GalacticalMap
//
//  Meteor yağmuru takibi ve uyarıları
//

import SwiftUI

struct MeteorShowerView: View {
    @State private var upcomingShowers: [MeteorShower] = MeteorShower.database
    @State private var selectedShower: MeteorShower?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Next Active Shower
                    if let nextShower = upcomingShowers.first {
                        ActiveShowerCard(shower: nextShower)
                    }
                    
                    // All Showers Timeline
                    VStack(alignment: .leading, spacing: 15) {
                        Text("📅 Upcoming Meteor Showers")
                            .font(.headline)
                            .foregroundColor(.white)
                        
                        ForEach(upcomingShowers) { shower in
                            MeteorShowerRow(shower: shower)
                                .onTapGesture {
                                    selectedShower = shower
                                }
                        }
                    }
                    
                    // Tips Section
                    ViewingTipsSection()
                }
                .padding()
            }
            .navigationTitle("☄️ Meteor Showers")
            .background(Color.black.ignoresSafeArea())
            .sheet(item: $selectedShower) { shower in
                MeteorShowerDetailView(shower: shower)
            }
        }
    }
}

struct ActiveShowerCard: View {
    let shower: MeteorShower
    
    var body: some View {
        VStack(spacing: 15) {
            Text("☄️")
                .font(.system(size: 80))
            
            Text(shower.name)
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("~\(shower.zhr) meteors per hour")
                .font(.title3)
                .foregroundColor(.cyan)
            
            HStack(spacing: 20) {
                VStack {
                    Text("Start")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(shower.startDate, style: .date)
                        .foregroundColor(.white)
                }
                
                VStack {
                    Text("Peak")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(shower.peakDate, style: .date)
                        .foregroundColor(.orange)
                        .fontWeight(.bold)
                }
                
                VStack {
                    Text("End")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Text(shower.endDate, style: .date)
                        .foregroundColor(.white)
                }
            }
            
            if shower.isActive {
                Text("🔴 ACTIVE NOW!")
                    .font(.headline)
                    .foregroundColor(.red)
                    .padding(8)
                    .background(Color.red.opacity(0.2))
                    .cornerRadius(8)
            }
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(
            LinearGradient(
                colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(15)
    }
}

struct MeteorShowerRow: View {
    let shower: MeteorShower
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 5) {
                Text(shower.name)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(shower.radiant)
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack {
                    Text("\(shower.zhr) ZHR")
                        .font(.caption)
                        .foregroundColor(.cyan)
                    Text("•")
                        .foregroundColor(.gray)
                    Text(shower.peakDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.orange)
                }
            }
            
            Spacer()
            
            VStack {
                Text(shower.visibility)
                    .font(.caption2)
                    .foregroundColor(.green)
                Text(shower.moonInterference)
                    .font(.caption2)
                    .foregroundColor(shower.moonInterference == "Low" ? .green : .orange)
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

struct ViewingTipsSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("💡 Viewing Tips")
                .font(.headline)
                .foregroundColor(.white)
            
            TipRow(icon: "🌃", text: "Go to dark-sky areas away from light pollution")
            TipRow(icon: "🕐", text: "Peak activity is after midnight")
            TipRow(icon: "👁️", text: "Let your eyes adapt to darkness for 20 minutes")
            TipRow(icon: "🧥", text: "Dress warm; you will observe for a while")
            TipRow(icon: "🪑", text: "Sit or lie down comfortably")
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

struct TipRow: View {
    let icon: String
    let text: String
    
    var body: some View {
        HStack {
            Text(icon)
            Text(text)
                .font(.caption)
                .foregroundColor(.white)
        }
    }
}

struct MeteorShowerDetailView: View {
    let shower: MeteorShower
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text(shower.name)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text(shower.description)
                        .foregroundColor(.gray)
                    
                    Divider()
                    
                    DetailRow(label: "Radiant", value: shower.radiant)
                    DetailRow(label: "ZHR", value: "\(shower.zhr)")
                    DetailRow(label: "Velocity", value: "\(shower.velocity) km/s")
                    DetailRow(label: "Parent Body", value: shower.parentBody)
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Close") { dismiss() }
                }
            }
        }
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .foregroundColor(.cyan)
        }
    }
}

// MARK: - Model

struct MeteorShower: Identifiable {
    let id = UUID()
    let name: String
    let radiant: String
    let startDate: Date
    let peakDate: Date
    let endDate: Date
    let zhr: Int
    let velocity: Int
    let parentBody: String
    let description: String
    let visibility: String
    let moonInterference: String
    let isActive: Bool
    
    static var database: [MeteorShower] {
        let calendar = Calendar.current
        let today = Date()
        
        return [
            MeteorShower(
                name: "Geminids",
                radiant: "Gemini (İkizler)",
                startDate: calendar.date(byAdding: .day, value: 20, to: today)!,
                peakDate: calendar.date(byAdding: .day, value: 25, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 30, to: today)!,
                zhr: 120,
                velocity: 35,
                parentBody: "3200 Phaethon",
                description: "Yılın en güçlü meteor yağmurlarından biri. Parlak ve renkli meteorlar.",
                visibility: "Mükemmel",
                moonInterference: "Düşük",
                isActive: false
            ),
            MeteorShower(
                name: "Perseids",
                radiant: "Perseus",
                startDate: calendar.date(byAdding: .day, value: 180, to: today)!,
                peakDate: calendar.date(byAdding: .day, value: 190, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 200, to: today)!,
                zhr: 100,
                velocity: 59,
                parentBody: "Swift-Tuttle",
                description: "En popüler meteor yağmuru. Yaz aylarında izlenir.",
                visibility: "Çok İyi",
                moonInterference: "Orta",
                isActive: false
            ),
            MeteorShower(
                name: "Quadrantids",
                radiant: "Boötes",
                startDate: calendar.date(byAdding: .day, value: 30, to: today)!,
                peakDate: calendar.date(byAdding: .day, value: 35, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 40, to: today)!,
                zhr: 110,
                velocity: 41,
                parentBody: "2003 EH1",
                description: "Yıl başında görülen güçlü meteor yağmuru.",
                visibility: "İyi",
                moonInterference: "Yüksek",
                isActive: true
            ),
            MeteorShower(
                name: "Leonids",
                radiant: "Leo (Aslan)",
                startDate: calendar.date(byAdding: .day, value: 60, to: today)!,
                peakDate: calendar.date(byAdding: .day, value: 70, to: today)!,
                endDate: calendar.date(byAdding: .day, value: 80, to: today)!,
                zhr: 15,
                velocity: 71,
                parentBody: "Tempel-Tuttle",
                description: "Hızlı meteorlar. Bazı yıllarda meteor fırtınası oluşturabilir.",
                visibility: "Orta",
                moonInterference: "Düşük",
                isActive: false
            )
        ]
    }
}

#Preview {
    MeteorShowerView()
}
