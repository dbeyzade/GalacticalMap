//
//  MoonPhasesView.swift
//  GalacticalMap
//
//  Ay fazları ve tutulma takvimi
//

import SwiftUI

struct MoonPhasesView: View {
    @State private var selectedDate = Date()
    @State private var moonPhases: [MoonPhase] = MoonPhase.generatePhases()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Current Moon Phase
                    CurrentMoonPhaseCard(phase: getCurrentPhase())
                    
                    // Upcoming Eclipses
                    UpcomingEclipsesSection()
                    
                    // Month Calendar
                    MoonCalendarView(phases: moonPhases)
                    
                    // Detailed Moon Data
                    MoonDataSection()
                }
                .padding()
            }
            .navigationTitle("🌙 Moon Phases")
            .background(Color.black.ignoresSafeArea())
        }
    }
    
    func getCurrentPhase() -> MoonPhase {
        moonPhases.first(where: { Calendar.current.isDateInToday($0.date) }) ?? moonPhases[0]
    }
}

struct CurrentMoonPhaseCard: View {
    let phase: MoonPhase
    
    var body: some View {
        VStack(spacing: 15) {
            Text(phase.emoji)
                .font(.system(size: 100))
            
            Text(phase.name)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text("Işık Oranı: \(Int(phase.illumination * 100))%")
                .foregroundColor(.gray)
            
            Text(phase.date, style: .date)
                .foregroundColor(.cyan)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(15)
    }
}

struct UpcomingEclipsesSection: View {
    let eclipses = [
        Eclipse(date: Date().addingTimeInterval(86400 * 45), type: .lunar, visibility: "Visible from Turkey"),
        Eclipse(date: Date().addingTimeInterval(86400 * 180), type: .solar, visibility: "Partially visible"),
        Eclipse(date: Date().addingTimeInterval(86400 * 365), type: .lunar, visibility: "Fully visible")
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("🌑 Upcoming Eclipses")
                .font(.headline)
                .foregroundColor(.white)
            
            ForEach(eclipses) { eclipse in
                HStack {
                    Text(eclipse.type == .solar ? "☀️" : "🌙")
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text(eclipse.type == .solar ? "Solar Eclipse" : "Lunar Eclipse")
                            .foregroundColor(.white)
                        Text(eclipse.date, style: .date)
                            .font(.caption)
                            .foregroundColor(.gray)
                        Text(eclipse.visibility)
                            .font(.caption2)
                            .foregroundColor(.cyan)
                    }
                    Spacer()
                }
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(10)
            }
        }
    }
}

struct MoonCalendarView: View {
    let phases: [MoonPhase]
    
    var body: some View {
        VStack(alignment: .leading) {
                    Text("📅 This Month")
                .font(.headline)
                .foregroundColor(.white)
            
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 7), spacing: 10) {
                ForEach(phases.prefix(28)) { phase in
                    VStack {
                        Text(phase.emoji)
                            .font(.title3)
                        Text("\(Calendar.current.component(.day, from: phase.date))")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    .frame(width: 40, height: 40)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(10)
        }
    }
}

struct MoonDataSection: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("📊 Moon Data")
                .font(.headline)
                .foregroundColor(.white)
            
            DataRow(label: "Distance", value: "384,400 km")
            DataRow(label: "Diameter", value: "3,474 km")
            DataRow(label: "Orbital Period", value: "27.3 days")
            DataRow(label: "Rise", value: "18:45")
            DataRow(label: "Set", value: "06:30")
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(10)
    }
}

struct DataRow: View {
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

// MARK: - Models

struct MoonPhase: Identifiable {
    let id = UUID()
    let date: Date
    let name: String
    let emoji: String
    let illumination: Double
    
    static func generatePhases() -> [MoonPhase] {
        let phases = [
            ("New Moon", "🌑", 0.0),
            ("Waxing Crescent", "🌒", 0.1),
            ("First Quarter", "🌓", 0.25),
            ("Waxing Gibbous", "🌔", 0.4),
            ("Full Moon", "🌕", 1.0),
            ("Waning Gibbous", "🌖", 0.6),
            ("Last Quarter", "🌗", 0.5),
            ("Waning Crescent", "🌘", 0.2)
        ]
        
        return (0..<30).map { day in
            let date = Calendar.current.date(byAdding: .day, value: day, to: Date())!
            let phaseIndex = (day % 8)
            return MoonPhase(
                date: date,
                name: phases[phaseIndex].0,
                emoji: phases[phaseIndex].1,
                illumination: phases[phaseIndex].2
            )
        }
    }
}

struct Eclipse: Identifiable {
    let id = UUID()
    let date: Date
    let type: EclipseType
    let visibility: String
    
    enum EclipseType {
        case solar, lunar
    }
}

#Preview {
    MoonPhasesView()
}
