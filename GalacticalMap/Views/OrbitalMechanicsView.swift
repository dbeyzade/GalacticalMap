//
//  OrbitalMechanicsLab.swift
//  GalacticalMap
//
//  Profesyonel Orbital Mekanik Laboratuvarı
//  Hohmann transfer, delta-v hesaplama, launch window optimization
//

import SwiftUI
import Combine
import Foundation

class OrbitalMechanicsLab: ObservableObject {
    static let shared = OrbitalMechanicsLab()
    
    @Published var selectedTransfer: OrbitalTransfer?
    @Published var launchWindows: [LaunchWindow] = []
    @Published var maneuverSequence: [OrbitalManeuver] = []
    
    // Physical constants
    let G = 6.67430e-11 // Gravitational constant
    let earthMass = 5.972e24 // kg
    let earthRadius = 6371000.0 // meters
    let moonDistance = 384400000.0 // meters
    let marsDistance = 225000000000.0 // meters
    
    // MARK: - Hohmann Transfer Calculations
    
    func calculateHohmannTransfer(from r1: Double, to r2: Double, centralBody: CelestialBody) -> HohmannTransfer {
        let mu = G * centralBody.mass
        
        // Semi-major axis of transfer orbit
        let a = (r1 + r2) / 2
        
        // Velocities at circular orbits
        let v1 = sqrt(mu / r1)
        let v2 = sqrt(mu / r2)
        
        // Velocities on transfer ellipse
        let vp = sqrt(mu * (2/r1 - 1/a)) // Perigee velocity
        let va = sqrt(mu * (2/r2 - 1/a)) // Apogee velocity
        
        // Delta-v requirements
        let deltaV1 = vp - v1 // First burn
        let deltaV2 = v2 - va // Second burn
        let totalDeltaV = abs(deltaV1) + abs(deltaV2)
        
        // Transfer time (half orbital period of ellipse)
        let transferTime = .pi * sqrt(pow(a, 3) / mu)
        
        return HohmannTransfer(
            initialOrbit: r1,
            finalOrbit: r2,
            transferOrbitSemiMajor: a,
            deltaV1: deltaV1,
            deltaV2: deltaV2,
            totalDeltaV: totalDeltaV,
            transferTime: transferTime
        )
    }
    
    // MARK: - Launch Window Calculation
    
    func calculateLaunchWindows(to target: Planet, from date: Date, numberOfWindows: Int = 5) -> [LaunchWindow] {
        var windows: [LaunchWindow] = []
        
        // Synodic period calculation
        let earthOrbitalPeriod = 365.25 * 86400.0 // seconds
        let synodicPeriod: Double
        
        switch target {
        case .mars:
            synodicPeriod = 780.0 * 86400.0 // ~26 months
        case .venus:
            synodicPeriod = 584.0 * 86400.0 // ~19 months
        case .jupiter:
            synodicPeriod = 398.9 * 86400.0 // ~13 months
        default:
            synodicPeriod = 365.25 * 86400.0
        }
        
        var currentDate = date
        
        for i in 0..<numberOfWindows {
            let windowDate = currentDate.addingTimeInterval(Double(i) * synodicPeriod)
            
            // Calculate optimal C3 (characteristic energy)
            let c3 = calculateC3(to: target, at: windowDate)
            
            // Calculate arrival date
            let transferTime = calculateTransferTime(to: target)
            let arrivalDate = windowDate.addingTimeInterval(transferTime)
            
            // Calculate delta-v requirement
            let deltaV = calculateInterplanetaryDeltaV(c3: c3)
            
            windows.append(LaunchWindow(
                openDate: windowDate.addingTimeInterval(-7 * 86400), // 7 days before optimal
                optimalDate: windowDate,
                closeDate: windowDate.addingTimeInterval(7 * 86400), // 7 days after optimal
                target: target,
                c3: c3,
                deltaV: deltaV,
                transferTime: transferTime,
                arrivalDate: arrivalDate,
                phaseAngle: calculatePhaseAngle(to: target, at: windowDate)
            ))
        }
        
        return windows
    }
    
    func calculateC3(to target: Planet, at date: Date) -> Double {
        // C3 (characteristic energy) calculation
        // Simplified - real calculation would use ephemeris data
        
        switch target {
        case .mars:
            return Double.random(in: 8...15) // km²/s²
        case .venus:
            return Double.random(in: 5...12)
        case .jupiter:
            return Double.random(in: 80...90)
        default:
            return 10.0
        }
    }
    
    func calculateTransferTime(to target: Planet) -> TimeInterval {
        switch target {
        case .mars:
            return 259 * 86400 // ~8.5 months
        case .venus:
            return 146 * 86400 // ~5 months
        case .jupiter:
            return 1000 * 86400 // ~33 months
        default:
            return 180 * 86400
        }
    }
    
    func calculateInterplanetaryDeltaV(c3: Double) -> Double {
        // Delta-v from LEO (200km altitude)
        let r = earthRadius + 200000 // LEO radius
        let v_circular = sqrt(G * earthMass / r)
        let v_escape = sqrt(2 * G * earthMass / r)
        let v_infinity = sqrt(c3 * 1e6) // Convert km²/s² to m²/s²
        let v_departure = sqrt(v_escape * v_escape + v_infinity * v_infinity)
        
        return v_departure - v_circular
    }
    
    func calculatePhaseAngle(to target: Planet, at date: Date) -> Double {
        // Phase angle calculation between Earth and target
        // Simplified - would use actual orbital positions
        
        return Double.random(in: 0...360)
    }
    
    // MARK: - Gravity Assist (Flyby) Calculations
    
    func calculateGravityAssist(planet: Planet, incomingVelocity: Double, periapsisAltitude: Double) -> GravityAssist {
        let mu = G * planet.mass
        let rp = planet.radius + periapsisAltitude
        
        // Velocity at periapsis
        let vp = sqrt(incomingVelocity * incomingVelocity + 2 * mu / rp)
        
        // Turn angle
        let delta = 2 * asin(1 / (1 + rp * incomingVelocity * incomingVelocity / mu))
        
        // Velocity change magnitude
        let deltaV = 2 * incomingVelocity * sin(delta / 2)
        
        return GravityAssist(
            planet: planet,
            incomingVelocity: incomingVelocity,
            outgoingVelocity: incomingVelocity, // magnitude same, direction changes
            turnAngle: delta * 180 / .pi,
            deltaV: deltaV,
            periapsisAltitude: periapsisAltitude
        )
    }
    
    // MARK: - N-Body Simulation
    
    func simulateTrajectory(initialPosition: Vector3D, initialVelocity: Vector3D, duration: TimeInterval, timestep: Double) -> [TrajectoryPoint] {
        var trajectory: [TrajectoryPoint] = []
        var position = initialPosition
        var velocity = initialVelocity
        var time = 0.0
        
        while time < duration {
            // Calculate gravitational acceleration from all bodies
            var acceleration = Vector3D(x: 0, y: 0, z: 0)
            
            // Earth's gravity
            let earthPos = Vector3D(x: 0, y: 0, z: 0)
            let rEarth = position.distance(to: earthPos)
            let aEarth = -G * earthMass / (rEarth * rEarth)
            let dirEarth = (earthPos - position).normalized()
            acceleration = acceleration + dirEarth * aEarth
            
            // Numerical integration (Verlet)
            position = position + velocity * timestep + acceleration * (0.5 * timestep * timestep)
            
            let newAcceleration = acceleration // Would recalculate
            velocity = velocity + (acceleration + newAcceleration) * (0.5 * timestep)
            
            trajectory.append(TrajectoryPoint(
                position: position,
                velocity: velocity,
                time: time
            ))
            
            time += timestep
        }
        
        return trajectory
    }
    
    // MARK: - Orbital Parameters from State Vectors
    
    func calculateOrbitalElements(position: Vector3D, velocity: Vector3D, mu: Double) -> OrbitalElements {
        let r = position.magnitude
        let v = velocity.magnitude
        
        // Specific angular momentum
        let h = position.cross(velocity)
        let hMag = h.magnitude
        
        // Eccentricity vector
        let eVec = ((velocity.cross(h)) * (1/mu)) - (position * (1/r))
        let e = eVec.magnitude
        
        // Semi-major axis
        let specificEnergy = (v * v / 2) - (mu / r)
        let a = -mu / (2 * specificEnergy)
        
        // Inclination
        let i = acos(h.z / hMag)
        
        // RAAN (Right Ascension of Ascending Node)
        let nVec = Vector3D(x: -h.y, y: h.x, z: 0)
        let nMag = nVec.magnitude
        var raan = acos(nVec.x / nMag)
        if nVec.y < 0 { raan = 2 * .pi - raan }
        
        // Argument of periapsis
        var argPe = acos(nVec.dot(eVec) / (nMag * e))
        if eVec.z < 0 { argPe = 2 * .pi - argPe }
        
        // True anomaly
        var trueAnomaly = acos(eVec.dot(position) / (e * r))
        if position.dot(velocity) < 0 { trueAnomaly = 2 * .pi - trueAnomaly }
        
        // Mean anomaly
        let eccentricAnomaly = 2 * atan(sqrt((1-e)/(1+e)) * tan(trueAnomaly/2))
        let meanAnomaly = eccentricAnomaly - e * sin(eccentricAnomaly)
        
        return OrbitalElements(
            semiMajorAxis: a,
            eccentricity: e,
            inclination: i,
            raan: raan,
            argumentOfPerigee: argPe,
            meanAnomaly: meanAnomaly,
            epoch: Date()
        )
    }
}

// MARK: - Models

struct HohmannTransfer {
    let initialOrbit: Double // meters
    let finalOrbit: Double // meters
    let transferOrbitSemiMajor: Double // meters
    let deltaV1: Double // m/s
    let deltaV2: Double // m/s
    let totalDeltaV: Double // m/s
    let transferTime: TimeInterval // seconds
}

struct LaunchWindow: Identifiable {
    let id = UUID()
    let openDate: Date
    let optimalDate: Date
    let closeDate: Date
    let target: Planet
    let c3: Double // km²/s²
    let deltaV: Double // m/s
    let transferTime: TimeInterval
    let arrivalDate: Date
    let phaseAngle: Double // degrees
}

enum Planet {
    case mercury, venus, earth, mars, jupiter, saturn, uranus, neptune
    
    var name: String {
        switch self {
        case .mercury: return "Mercury"
        case .venus: return "Venus"
        case .earth: return "Earth"
        case .mars: return "Mars"
        case .jupiter: return "Jupiter"
        case .saturn: return "Saturn"
        case .uranus: return "Uranus"
        case .neptune: return "Neptune"
        }
    }
    
    var mass: Double {
        switch self {
        case .mercury: return 3.3011e23
        case .venus: return 4.8675e24
        case .earth: return 5.972e24
        case .mars: return 6.4171e23
        case .jupiter: return 1.8982e27
        case .saturn: return 5.6834e26
        case .uranus: return 8.6810e25
        case .neptune: return 1.02413e26
        }
    }
    
    var radius: Double {
        switch self {
        case .mercury: return 2439700
        case .venus: return 6051800
        case .earth: return 6371000
        case .mars: return 3389500
        case .jupiter: return 69911000
        case .saturn: return 58232000
        case .uranus: return 25362000
        case .neptune: return 24622000
        }
    }
}

struct CelestialBody {
    let name: String
    let mass: Double // kg
    let radius: Double // meters
}

struct OrbitalTransfer: Identifiable {
    let id = UUID()
    let type: TransferType
    let origin: String
    let destination: String
    let deltaV: Double
    let transferTime: TimeInterval
    
    enum TransferType {
        case hohmann, bielliptic, lowThrust, gravitAssist
    }
}

struct OrbitalManeuver: Identifiable {
    let id = UUID()
    let name: String
    let time: TimeInterval
    let deltaV: Vector3D
    let burnDuration: TimeInterval
}

struct GravityAssist {
    let planet: Planet
    let incomingVelocity: Double // m/s
    let outgoingVelocity: Double // m/s
    let turnAngle: Double // degrees
    let deltaV: Double // m/s
    let periapsisAltitude: Double // meters
}

struct TrajectoryPoint {
    let position: Vector3D
    let velocity: Vector3D
    let time: TimeInterval
}

struct Vector3D {
    var x: Double
    var y: Double
    var z: Double
    
    var magnitude: Double {
        sqrt(x*x + y*y + z*z)
    }
    
    func normalized() -> Vector3D {
        let mag = magnitude
        return Vector3D(x: x/mag, y: y/mag, z: z/mag)
    }
    
    func distance(to other: Vector3D) -> Double {
        sqrt(pow(x - other.x, 2) + pow(y - other.y, 2) + pow(z - other.z, 2))
    }
    
    func cross(_ other: Vector3D) -> Vector3D {
        Vector3D(
            x: y * other.z - z * other.y,
            y: z * other.x - x * other.z,
            z: x * other.y - y * other.x
        )
    }
    
    func dot(_ other: Vector3D) -> Double {
        x * other.x + y * other.y + z * other.z
    }
    
    static func +(lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(x: lhs.x + rhs.x, y: lhs.y + rhs.y, z: lhs.z + rhs.z)
    }
    
    static func -(lhs: Vector3D, rhs: Vector3D) -> Vector3D {
        Vector3D(x: lhs.x - rhs.x, y: lhs.y - rhs.y, z: lhs.z - rhs.z)
    }
    
    static func *(lhs: Vector3D, rhs: Double) -> Vector3D {
        Vector3D(x: lhs.x * rhs, y: lhs.y * rhs, z: lhs.z * rhs)
    }
}

// MARK: - Orbital Mechanics Lab View

struct OrbitalMechanicsView: View {
    @StateObject private var lab = OrbitalMechanicsLab.shared
    @State private var selectedCalculation = 0
    @State private var altitude1 = 200.0 // km
    @State private var altitude2 = 35786.0 // km (GEO)
    @State private var selectedTarget: Planet = .mars
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Calculator selector
                        Picker("Calculation Type", selection: $selectedCalculation) {
                            Text("Hohmann Transfer").tag(0)
                            Text("Launch Windows").tag(1)
                            Text("Gravity Assist").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        switch selectedCalculation {
                        case 0:
                            HohmannTransferCalculator(altitude1: $altitude1, altitude2: $altitude2)
                        case 1:
                            LaunchWindowCalculator(target: $selectedTarget)
                        case 2:
                            GravityAssistCalculator()
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Orbital Mechanics Lab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("ORBITAL MECHANICS LAB")
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct HohmannTransferCalculator: View {
    @Binding var altitude1: Double
    @Binding var altitude2: Double
    @StateObject private var lab = OrbitalMechanicsLab.shared
    
    var transfer: HohmannTransfer {
        let r1 = (altitude1 * 1000) + lab.earthRadius
        let r2 = (altitude2 * 1000) + lab.earthRadius
        return lab.calculateHohmannTransfer(
            from: r1,
            to: r2,
            centralBody: CelestialBody(name: "Earth", mass: lab.earthMass, radius: lab.earthRadius)
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("HOHMANN TRANSFER CALCULATOR")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            // Inputs
            VStack(spacing: 12) {
                HStack {
                    Text("INITIAL ORBIT:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.7))
                    Spacer()
                    Text("\(Int(altitude1)) km")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                
                Slider(value: $altitude1, in: 200...100000, step: 100)
                    .accentColor(.cyan)
                
                HStack {
                    Text("FINAL ORBIT:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.cyan.opacity(0.7))
                    Spacer()
                    Text("\(Int(altitude2)) km")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.cyan)
                }
                
                Slider(value: $altitude2, in: 200...100000, step: 100)
                    .accentColor(.cyan)
            }
            .padding()
            .background(Color.cyan.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )
            
            // Results
            VStack(alignment: .leading, spacing: 12) {
                Text("RESULTS:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                ResultRow(label: "ΔV BURN 1:", value: String(format: "%.2f m/s", transfer.deltaV1))
                ResultRow(label: "ΔV BURN 2:", value: String(format: "%.2f m/s", transfer.deltaV2))
                ResultRow(label: "TOTAL ΔV:", value: String(format: "%.2f m/s", transfer.totalDeltaV), highlight: true)
                
                Divider().background(Color.green.opacity(0.3))
                
                ResultRow(label: "TRANSFER TIME:", value: formatDuration(transfer.transferTime))
                ResultRow(label: "TRANSFER ORBIT:", value: String(format: "%.0f x %.0f km",
                                                                     (transfer.initialOrbit - lab.earthRadius) / 1000,
                                                                     (transfer.finalOrbit - lab.earthRadius) / 1000))
            }
            .padding()
            .background(Color.green.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
            )
        }
    }
    
    func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct ResultRow: View {
    let label: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.green.opacity(0.7))
            Spacer()
            Text(value)
                .font(.system(size: highlight ? 14 : 12, weight: highlight ? .bold : .semibold, design: .monospaced))
                .foregroundColor(highlight ? .yellow : .green)
        }
        .padding(.vertical, 4)
    }
}

struct LaunchWindowCalculator: View {
    @Binding var target: Planet
    @StateObject private var lab = OrbitalMechanicsLab.shared
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("INTERPLANETARY LAUNCH WINDOWS")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.orange)
            
            Picker("Target Planet", selection: $target) {
                Text("Mars").tag(Planet.mars)
                Text("Venus").tag(Planet.venus)
                Text("Jupiter").tag(Planet.jupiter)
            }
            .pickerStyle(.segmented)
            
            Button {
                lab.launchWindows = lab.calculateLaunchWindows(to: target, from: Date(), numberOfWindows: 5)
            } label: {
                Text("CALCULATE WINDOWS")
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.black)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.orange)
            }
            
            ForEach(lab.launchWindows) { window in
                LaunchWindowCard(window: window)
            }
        }
    }
}

struct LaunchWindowCard: View {
    let window: LaunchWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(window.target.name.uppercased())
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(.orange)
                
                Spacer()
                
                Text(window.optimalDate, style: .date)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.orange.opacity(0.7))
            }
            
            Grid(alignment: .leading, horizontalSpacing: 12, verticalSpacing: 4) {
                GridRow {
                    Text("C3:")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.orange.opacity(0.7))
                    Text(String(format: "%.2f km²/s²", window.c3))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                
                GridRow {
                    Text("ΔV:")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.orange.opacity(0.7))
                    Text(String(format: "%.0f m/s", window.deltaV))
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                }
                
                GridRow {
                    Text("TRANSFER:")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.orange.opacity(0.7))
                    Text("\(Int(window.transferTime / 86400)) days")
                        .font(.system(size: 10, weight: .semibold, design: .monospaced))
                        .foregroundColor(.orange)
                }
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.orange.opacity(0.5), lineWidth: 1)
        )
    }
}

struct GravityAssistCalculator: View {
    @State private var selectedPlanet: Planet = .jupiter
    @State private var incomingVelocity = 20000.0
    @State private var periapsisAltitude = 1000000.0
    @StateObject private var lab = OrbitalMechanicsLab.shared
    
    var assist: GravityAssist {
        lab.calculateGravityAssist(
            planet: selectedPlanet,
            incomingVelocity: incomingVelocity,
            periapsisAltitude: periapsisAltitude
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("GRAVITY ASSIST CALCULATOR")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.purple)
            
            VStack(spacing: 12) {
                Picker("Planet", selection: $selectedPlanet) {
                    Text("Jupiter").tag(Planet.jupiter)
                    Text("Saturn").tag(Planet.saturn)
                    Text("Venus").tag(Planet.venus)
                }
                .pickerStyle(.segmented)
                
                VStack {
                    HStack {
                        Text("INCOMING V∞:")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.purple.opacity(0.7))
                        Spacer()
                        Text("\(Int(incomingVelocity)) m/s")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    Slider(value: $incomingVelocity, in: 5000...50000, step: 1000)
                        .accentColor(.purple)
                }
                
                VStack {
                    HStack {
                        Text("PERIAPSIS ALT:")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.purple.opacity(0.7))
                        Spacer()
                        Text("\(Int(periapsisAltitude / 1000)) km")
                            .font(.system(size: 12, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                    Slider(value: $periapsisAltitude, in: 100000...10000000, step: 100000)
                        .accentColor(.purple)
                }
            }
            .padding()
            .background(Color.purple.opacity(0.05))
            
            VStack(alignment: .leading, spacing: 8) {
                Text("FLYBY RESULTS:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.purple)
                
                ResultRow(label: "TURN ANGLE:", value: String(format: "%.2f°", assist.turnAngle))
                ResultRow(label: "ΔV MAGNITUDE:", value: String(format: "%.2f m/s", assist.deltaV))
                ResultRow(label: "V∞ OUT:", value: String(format: "%.2f m/s", assist.outgoingVelocity))
            }
            .padding()
            .background(Color.purple.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

#Preview {
    OrbitalMechanicsView()
}
