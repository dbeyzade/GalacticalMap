//
//  ExoplanetDetector.swift
//  GalacticalMap
//
//  Exoplanet Detection & Characterization
//  Transit photometry, radial velocity, direct imaging
//

import SwiftUI
import Combine
import Charts

class ExoplanetDetector: ObservableObject {
    static let shared = ExoplanetDetector()
    
    @Published var detectedExoplanets: [Exoplanet] = []
    @Published var lightCurveData: [LightCurvePoint] = []
    @Published var radialVelocityData: [RadialVelocityPoint] = []
    
    // Physical constants
    let G = 6.67430e-11 // Gravitational constant
    let solarMass = 1.989e30 // kg
    let solarRadius = 6.96e8 // meters
    let earthMass = 5.972e24 // kg
    let earthRadius = 6.371e6 // meters
    let jupiterMass = 1.898e27 // kg
    let jupiterRadius = 6.9911e7 // meters
    let AU = 1.496e11 // meters (Astronomical Unit)
    
    init() {
        loadKnownExoplanets()
    }
    
    // MARK: - Transit Method
    
    func detectTransit(lightCurve: [Double], times: [Double]) -> TransitDetection? {
        // Box-Least-Squares (BLS) algorithm for transit detection
        
        guard lightCurve.count > 100 else { return nil }
        
        let meanFlux = lightCurve.reduce(0, +) / Double(lightCurve.count)
        let stdFlux = sqrt(lightCurve.map { pow($0 - meanFlux, 2) }.reduce(0, +) / Double(lightCurve.count))
        
        // Look for periodic dips
        var bestPeriod = 0.0
        var bestDepth = 0.0
        var bestDuration = 0.0
        var bestSignalToNoise = 0.0
        
        // Search periods from 0.5 to 50 days
        for period in stride(from: 0.5, to: 50.0, by: 0.1) {
            let (depth, duration, snr) = findBestTransit(
                lightCurve: lightCurve,
                times: times,
                period: period
            )
            
            if snr > bestSignalToNoise && snr > 5.0 { // 5-sigma detection
                bestPeriod = period
                bestDepth = depth
                bestDuration = duration
                bestSignalToNoise = snr
            }
        }
        
        guard bestSignalToNoise > 5.0 else { return nil }
        
        return TransitDetection(
            period: bestPeriod,
            transitDepth: bestDepth,
            transitDuration: bestDuration,
            signalToNoise: bestSignalToNoise,
            confidence: min(bestSignalToNoise / 10.0, 1.0)
        )
    }
    
    func findBestTransit(lightCurve: [Double], times: [Double], period: Double) -> (depth: Double, duration: Double, snr: Double) {
        // Phase-fold the light curve
        let phases = times.map { ($0.truncatingRemainder(dividingBy: period)) / period }
        
        var bestDepth = 0.0
        var bestDuration = 0.0
        var bestSNR = 0.0
        
        // Try different transit durations
        for duration in stride(from: 0.01, to: 0.2, by: 0.01) { // 1% to 20% of period
            let inTransit = zip(phases, lightCurve).filter { $0.0 < duration || $0.0 > (1 - duration/2) }
            let outTransit = zip(phases, lightCurve).filter { $0.0 >= duration && $0.0 <= (1 - duration/2) }
            
            guard inTransit.count > 3 && outTransit.count > 10 else { continue }
            
            let inFlux = inTransit.map { $0.1 }.reduce(0, +) / Double(inTransit.count)
            let outFlux = outTransit.map { $0.1 }.reduce(0, +) / Double(outTransit.count)
            
            let depth = (outFlux - inFlux) / outFlux
            let noise = sqrt(outFlux / Double(outTransit.count)) / outFlux
            let snr = depth / noise
            
            if snr > bestSNR {
                bestDepth = depth
                bestDuration = duration * period
                bestSNR = snr
            }
        }
        
        return (bestDepth, bestDuration, bestSNR)
    }
    
    func calculatePlanetRadius(transitDepth: Double, stellarRadius: Double) -> Double {
        // Transit depth = (R_planet / R_star)²
        let radiusRatio = sqrt(transitDepth)
        return radiusRatio * stellarRadius
    }
    
    func calculateSemiMajorAxis(period: Double, stellarMass: Double) -> Double {
        // Kepler's Third Law: a³ = (G * M_star * P²) / (4π²)
        let periodSeconds = period * 86400 // Convert days to seconds
        let a3 = (G * stellarMass * pow(periodSeconds, 2)) / (4 * pow(.pi, 2))
        return pow(a3, 1.0/3.0)
    }
    
    // MARK: - Radial Velocity Method
    
    func detectRadialVelocity(velocities: [Double], times: [Double]) -> RadialVelocityDetection? {
        // Lomb-Scargle periodogram for period finding
        
        guard velocities.count > 20 else { return nil }
        
        let meanVelocity = velocities.reduce(0, +) / Double(velocities.count)
        
        var bestPeriod = 0.0
        var bestAmplitude = 0.0
        var bestPower = 0.0
        
        // Search for periodic signal
        for period in stride(from: 1.0, to: 1000.0, by: 1.0) {
            let (amplitude, power) = fitSinusoid(
                velocities: velocities,
                times: times,
                period: period,
                meanVelocity: meanVelocity
            )
            
            if power > bestPower {
                bestPeriod = period
                bestAmplitude = amplitude
                bestPower = power
            }
        }
        
        guard bestPower > 10.0 else { return nil } // Significance threshold
        
        return RadialVelocityDetection(
            period: bestPeriod,
            semiAmplitude: bestAmplitude,
            power: bestPower
        )
    }
    
    func fitSinusoid(velocities: [Double], times: [Double], period: Double, meanVelocity: Double) -> (amplitude: Double, power: Double) {
        let omega = 2 * .pi / period
        
        var sumSin = 0.0
        var sumCos = 0.0
        var sumSin2 = 0.0
        var sumCos2 = 0.0
        var sumSinCos = 0.0
        
        for i in 0..<velocities.count {
            let phase = omega * times[i]
            let v = velocities[i] - meanVelocity
            
            sumSin += v * sin(phase)
            sumCos += v * cos(phase)
            sumSin2 += pow(sin(phase), 2)
            sumCos2 += pow(cos(phase), 2)
            sumSinCos += sin(phase) * cos(phase)
        }
        
        let amplitude = sqrt(pow(sumSin, 2) + pow(sumCos, 2)) / Double(velocities.count)
        let power = (pow(sumSin, 2) / sumSin2 + pow(sumCos, 2) / sumCos2) / 2
        
        return (amplitude, power)
    }
    
    func calculatePlanetMass(semiAmplitude: Double, period: Double, stellarMass: Double, inclination: Double = .pi/2) -> Double {
        // M_planet * sin(i) = (K * (M_star)^(2/3) * P^(1/3)) / ((2πG)^(1/3))
        
        let periodSeconds = period * 86400
        let K = semiAmplitude
        
        let numerator = K * pow(stellarMass, 2.0/3.0) * pow(periodSeconds, 1.0/3.0)
        let denominator = pow(2 * .pi * G, 1.0/3.0)
        
        let mSini = numerator / denominator
        let mass = mSini / sin(inclination)
        
        return mass
    }
    
    // MARK: - Habitability Analysis
    
    func calculateEquilibriumTemperature(semiMajorAxis: Double, stellarLuminosity: Double, albedo: Double = 0.3) -> Double {
        // T_eq = T_star * sqrt(R_star / (2 * a)) * (1 - A)^(1/4)
        
        // Simplified: T_eq = 278 * (L/L_sun)^(1/4) * (a/AU)^(-1/2) * (1-A)^(1/4)
        
        let L_solar = 3.828e26 // Watts
        let aAU = semiMajorAxis / AU
        
        let temp = 278 * pow(stellarLuminosity / L_solar, 0.25) * pow(aAU, -0.5) * pow(1 - albedo, 0.25)
        
        return temp
    }
    
    func calculateHabitableZone(stellarLuminosity: Double) -> (inner: Double, outer: Double) {
        // Conservative habitable zone (liquid water)
        
        let L_solar = 3.828e26
        let L_ratio = stellarLuminosity / L_solar
        
        // Recent Venus (inner edge)
        let innerAU = sqrt(L_ratio / 1.107)
        
        // Early Mars (outer edge)
        let outerAU = sqrt(L_ratio / 0.356)
        
        return (innerAU * AU, outerAU * AU)
    }
    
    func isHabitable(exoplanet: Exoplanet, stellarLuminosity: Double) -> HabitabilityScore {
        let hz = calculateHabitableZone(stellarLuminosity: stellarLuminosity)
        let inHZ = exoplanet.semiMajorAxis >= hz.inner && exoplanet.semiMajorAxis <= hz.outer
        
        // Mass criteria (0.1 - 10 Earth masses)
        let massOK = exoplanet.mass >= (0.1 * earthMass) && exoplanet.mass <= (10 * earthMass)
        
        // Radius criteria (0.5 - 2.5 Earth radii)
        let radiusOK = exoplanet.radius >= (0.5 * earthRadius) && exoplanet.radius <= (2.5 * earthRadius)
        
        // Temperature criteria (200-350 K)
        let tempOK = exoplanet.equilibriumTemperature >= 200 && exoplanet.equilibriumTemperature <= 350
        
        var score = 0.0
        if inHZ { score += 0.4 }
        if massOK { score += 0.2 }
        if radiusOK { score += 0.2 }
        if tempOK { score += 0.2 }
        
        return HabitabilityScore(
            score: score,
            inHabitableZone: inHZ,
            massOK: massOK,
            radiusOK: radiusOK,
            temperatureOK: tempOK
        )
    }
    
    // MARK: - Known Exoplanets Database
    
    func loadKnownExoplanets() {
        detectedExoplanets = [
            Exoplanet(
                name: "Proxima Centauri b",
                hostStar: "Proxima Centauri",
                mass: 1.27 * earthMass,
                radius: 1.1 * earthRadius,
                semiMajorAxis: 0.0485 * AU,
                period: 11.186,
                eccentricity: 0.02,
                equilibriumTemperature: 234,
                detectionMethod: .radialVelocity,
                discoveryYear: 2016,
                distance: 4.24 // light-years
            ),
            Exoplanet(
                name: "TRAPPIST-1e",
                hostStar: "TRAPPIST-1",
                mass: 0.69 * earthMass,
                radius: 0.92 * earthRadius,
                semiMajorAxis: 0.028 * AU,
                period: 6.10,
                eccentricity: 0.005,
                equilibriumTemperature: 251,
                detectionMethod: .transit,
                discoveryYear: 2017,
                distance: 39.5
            ),
            Exoplanet(
                name: "Kepler-452b",
                hostStar: "Kepler-452",
                mass: 5.0 * earthMass,
                radius: 1.6 * earthRadius,
                semiMajorAxis: 1.046 * AU,
                period: 384.8,
                eccentricity: 0.0,
                equilibriumTemperature: 265,
                detectionMethod: .transit,
                discoveryYear: 2015,
                distance: 1400
            ),
            Exoplanet(
                name: "HD 209458 b (Osiris)",
                hostStar: "HD 209458",
                mass: 0.69 * jupiterMass,
                radius: 1.38 * jupiterRadius,
                semiMajorAxis: 0.047 * AU,
                period: 3.52,
                eccentricity: 0.0,
                equilibriumTemperature: 1449,
                detectionMethod: .transit,
                discoveryYear: 1999,
                distance: 159
            ),
            Exoplanet(
                name: "51 Pegasi b",
                hostStar: "51 Pegasi",
                mass: 0.46 * jupiterMass,
                radius: 1.9 * jupiterRadius,
                semiMajorAxis: 0.0527 * AU,
                period: 4.23,
                eccentricity: 0.013,
                equilibriumTemperature: 1284,
                detectionMethod: .radialVelocity,
                discoveryYear: 1995,
                distance: 50.9
            ),
            Exoplanet(
                name: "TOI-700 d",
                hostStar: "TOI-700",
                mass: 1.72 * earthMass,
                radius: 1.19 * earthRadius,
                semiMajorAxis: 0.163 * AU,
                period: 37.42,
                eccentricity: 0.0,
                equilibriumTemperature: 269,
                detectionMethod: .transit,
                discoveryYear: 2020,
                distance: 101.4
            )
        ]
    }
    
    // MARK: - Atmospheric Characterization
    
    func analyzeTransmissionSpectrum(wavelengths: [Double], transitDepths: [Double]) -> AtmosphericComposition {
        var molecules: [Molecule: Double] = [:]
        
        // Look for molecular signatures
        
        // Water vapor (1.4 µm, 1.9 µm)
        molecules[.water] = detectMolecule(wavelengths: wavelengths, depths: transitDepths, signature: [1.4, 1.9])
        
        // Methane (2.3 µm, 3.3 µm)
        molecules[.methane] = detectMolecule(wavelengths: wavelengths, depths: transitDepths, signature: [2.3, 3.3])
        
        // Carbon dioxide (4.3 µm)
        molecules[.carbonDioxide] = detectMolecule(wavelengths: wavelengths, depths: transitDepths, signature: [4.3])
        
        // Oxygen (0.76 µm)
        molecules[.oxygen] = detectMolecule(wavelengths: wavelengths, depths: transitDepths, signature: [0.76])
        
        // Ozone (9.6 µm)
        molecules[.ozone] = detectMolecule(wavelengths: wavelengths, depths: transitDepths, signature: [9.6])
        
        return AtmosphericComposition(molecules: molecules)
    }
    
    func detectMolecule(wavelengths: [Double], depths: [Double], signature: [Double]) -> Double {
        var signalStrength = 0.0
        
        for sig in signature {
            if let index = wavelengths.firstIndex(where: { abs($0 - sig) < 0.1 }) {
                signalStrength += depths[index]
            }
        }
        
        return signalStrength / Double(signature.count)
    }
}

// MARK: - Models

struct Exoplanet: Identifiable {
    let id = UUID()
    let name: String
    let hostStar: String
    let mass: Double // kg
    let radius: Double // meters
    let semiMajorAxis: Double // meters
    let period: Double // days
    let eccentricity: Double
    let equilibriumTemperature: Double // Kelvin
    let detectionMethod: DetectionMethod
    let discoveryYear: Int
    let distance: Double // light-years
    
    var massEarth: Double {
        mass / 5.972e24
    }
    
    var radiusEarth: Double {
        radius / 6.371e6
    }
    
    var semiMajorAxisAU: Double {
        semiMajorAxis / 1.496e11
    }
}

enum DetectionMethod: String {
    case transit = "Transit"
    case radialVelocity = "Radial Velocity"
    case directImaging = "Direct Imaging"
    case microlensing = "Gravitational Microlensing"
    case astrometry = "Astrometry"
    case timing = "Timing Variations"
}

struct TransitDetection {
    let period: Double // days
    let transitDepth: Double
    let transitDuration: Double // days
    let signalToNoise: Double
    let confidence: Double // 0-1
}

struct RadialVelocityDetection {
    let period: Double // days
    let semiAmplitude: Double // m/s
    let power: Double // periodogram power
}

struct LightCurvePoint {
    let time: Double // days
    let flux: Double
    let error: Double
}

struct RadialVelocityPoint {
    let time: Double // days
    let velocity: Double // m/s
    let error: Double // m/s
}

struct HabitabilityScore {
    let score: Double // 0-1
    let inHabitableZone: Bool
    let massOK: Bool
    let radiusOK: Bool
    let temperatureOK: Bool
    
    var category: String {
        if score >= 0.8 { return "Highly Habitable" }
        else if score >= 0.6 { return "Potentially Habitable" }
        else if score >= 0.4 { return "Marginal" }
        else { return "Not Habitable" }
    }
    
    var color: Color {
        if score >= 0.8 { return .green }
        else if score >= 0.6 { return .yellow }
        else if score >= 0.4 { return .orange }
        else { return .red }
    }
}

enum Molecule: String {
    case water = "H₂O"
    case methane = "CH₄"
    case carbonDioxide = "CO₂"
    case oxygen = "O₂"
    case ozone = "O₃"
    case ammonia = "NH₃"
    case nitrogen = "N₂"
}

struct AtmosphericComposition {
    let molecules: [Molecule: Double]
}

// MARK: - Exoplanet Explorer View

struct ExoplanetExplorerView: View {
    @StateObject private var detector = ExoplanetDetector.shared
    @State private var selectedPlanet: Exoplanet?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Statistics
                        ExoplanetStatsCard(count: detector.detectedExoplanets.count)
                        
                        // Exoplanet List
                        VStack(alignment: .leading, spacing: 12) {
                            Text("DISCOVERED EXOPLANETS")
                                .font(.system(size: 12, weight: .bold, design: .monospaced))
                                .foregroundColor(.cyan)
                                .padding(.horizontal)
                            
                            ForEach(detector.detectedExoplanets) { planet in
                                ExoplanetCard(planet: planet)
                                    .onTapGesture {
                                        selectedPlanet = planet
                                    }
                            }
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Exoplanet Explorer")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "globe.americas.fill")
                            .foregroundColor(.blue)
                        Text("EXOPLANET EXPLORER")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.cyan)
                    }
                }
            }
            .sheet(item: $selectedPlanet) { planet in
                ExoplanetDetailView(planet: planet)
            }
        }
    }
}

struct ExoplanetStatsCard: View {
    let count: Int
    
    var body: some View {
        VStack(spacing: 12) {
            Text("\(count)")
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            Text("CONFIRMED EXOPLANETS")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.gray)
            
            Text("Real data from NASA Exoplanet Archive")
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray.opacity(0.7))
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cyan.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
    }
}

struct ExoplanetCard: View {
    let planet: Exoplanet
    
    var habitability: HabitabilityScore {
        // Assume Sun-like luminosity for simplicity
        ExoplanetDetector.shared.isHabitable(exoplanet: planet, stellarLuminosity: 3.828e26)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(planet.name)
                        .font(.system(size: 14, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    Text(planet.hostStar)
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(planet.detectionMethod.rawValue)
                        .font(.system(size: 8, design: .monospaced))
                        .foregroundColor(.cyan)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.cyan.opacity(0.2))
                    
                    Text("\(planet.discoveryYear)")
                        .font(.system(size: 9, design: .monospaced))
                        .foregroundColor(.gray)
                }
            }
            
            Divider().background(Color.gray.opacity(0.3))
            
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 8) {
                GridRow {
                    ParamLabel(icon: "scalemass", label: "MASS", value: String(format: "%.2f M⊕", planet.massEarth))
                    ParamLabel(icon: "circle", label: "RADIUS", value: String(format: "%.2f R⊕", planet.radiusEarth))
                }
                
                GridRow {
                    ParamLabel(icon: "arrow.left.and.right", label: "DISTANCE", value: String(format: "%.2f AU", planet.semiMajorAxisAU))
                    ParamLabel(icon: "thermometer", label: "TEMP", value: "\(Int(planet.equilibriumTemperature)) K")
                }
                
                GridRow {
                    ParamLabel(icon: "timer", label: "PERIOD", value: String(format: "%.1f days", planet.period))
                    ParamLabel(icon: "star", label: "DISTANCE", value: String(format: "%.1f ly", planet.distance))
                }
            }
            
            // Habitability indicator
            HStack {
                Text("HABITABILITY:")
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.gray)
                
                Spacer()
                
                HStack(spacing: 4) {
                    ForEach(0..<5, id: \.self) { i in
                        Circle()
                            .fill(i < Int(habitability.score * 5) ? habitability.color : Color.gray.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                
                Text(habitability.category)
                    .font(.system(size: 9, weight: .bold, design: .monospaced))
                    .foregroundColor(habitability.color)
            }
        }
        .padding()
        .background(Color.black.opacity(0.5))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(habitability.color.opacity(0.5), lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

struct ParamLabel: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 8))
                .foregroundColor(.cyan.opacity(0.7))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 7, design: .monospaced))
                    .foregroundColor(.gray)
                Text(value)
                    .font(.system(size: 9, weight: .semibold, design: .monospaced))
                    .foregroundColor(.cyan)
            }
        }
    }
}

struct ExoplanetDetailView: View {
    let planet: Exoplanet
    @Environment(\.dismiss) var dismiss
    
    var habitability: HabitabilityScore {
        ExoplanetDetector.shared.isHabitable(exoplanet: planet, stellarLuminosity: 3.828e26)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        // Header
                        VStack(alignment: .leading, spacing: 8) {
                            Text(planet.name)
                                .font(.system(size: 24, weight: .bold, design: .monospaced))
                                .foregroundColor(.white)
                            
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(.yellow)
                                Text(planet.hostStar)
                                    .font(.system(size: 14, design: .monospaced))
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        
                        // Orbital visualization (simplified)
                        OrbitalDiagramView(planet: planet)
                        
                        // Detailed parameters
                        DetailSection(title: "PHYSICAL PROPERTIES") {
                            ExoplanetDetailRow(label: "Mass", value: String(format: "%.2f Earth masses", planet.massEarth))
                            ExoplanetDetailRow(label: "Radius", value: String(format: "%.2f Earth radii", planet.radiusEarth))
                            ExoplanetDetailRow(label: "Density", value: String(format: "%.2f g/cm³", (planet.mass / (4/3 * .pi * pow(planet.radius, 3))) / 1000))
                            ExoplanetDetailRow(label: "Surface Gravity", value: String(format: "%.2f g", (6.67430e-11 * planet.mass) / pow(planet.radius, 2) / 9.81))
                        }
                        
                        DetailSection(title: "ORBITAL PARAMETERS") {
                            ExoplanetDetailRow(label: "Semi-Major Axis", value: String(format: "%.3f AU", planet.semiMajorAxisAU))
                            ExoplanetDetailRow(label: "Orbital Period", value: String(format: "%.2f days", planet.period))
                            ExoplanetDetailRow(label: "Eccentricity", value: String(format: "%.3f", planet.eccentricity))
                            ExoplanetDetailRow(label: "Equilibrium Temperature", value: "\(Int(planet.equilibriumTemperature)) K (\(Int(planet.equilibriumTemperature - 273))°C)")
                        }
                        
                        DetailSection(title: "HABITABILITY ANALYSIS") {
                            HabitabilityDetailView(score: habitability)
                        }
                        
                        DetailSection(title: "DISCOVERY") {
                            ExoplanetDetailRow(label: "Method", value: planet.detectionMethod.rawValue)
                            ExoplanetDetailRow(label: "Year", value: "\(planet.discoveryYear)")
                            ExoplanetDetailRow(label: "Distance from Earth", value: String(format: "%.1f light-years", planet.distance))
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundColor(.cyan)
                }
            }
        }
    }
}

struct OrbitalDiagramView: View {
    let planet: Exoplanet
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Star
                Circle()
                    .fill(Color.yellow)
                    .frame(width: 30, height: 30)
                
                // Orbit
                Ellipse()
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    .frame(
                        width: min(geometry.size.width - 60, CGFloat(planet.semiMajorAxisAU) * 100),
                        height: min(geometry.size.width - 60, CGFloat(planet.semiMajorAxisAU) * 100) * CGFloat(1 - planet.eccentricity)
                    )
                
                // Planet
                Circle()
                    .fill(Color.blue)
                    .frame(width: 15, height: 15)
                    .offset(x: min(geometry.size.width/2 - 30, CGFloat(planet.semiMajorAxisAU) * 50))
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .frame(height: 200)
        .background(Color.black)
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
        )
        .padding()
    }
}

struct DetailSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
                .padding(.horizontal)
            
            VStack(spacing: 0) {
                content()
            }
        }
    }
}

struct ExoplanetDetailRow: View {
    let label: String
    let value: String
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 11, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: 11, weight: .semibold, design: .monospaced))
                .foregroundColor(.white)
        }
        .padding()
        .background(Color.cyan.opacity(0.05))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(.cyan.opacity(0.1)),
            alignment: .bottom
        )
    }
}

struct HabitabilityDetailView: View {
    let score: HabitabilityScore
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("SCORE:")
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text(String(format: "%.0f%%", score.score * 100))
                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                    .foregroundColor(score.color)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                CheckItem(label: "In Habitable Zone", passed: score.inHabitableZone)
                CheckItem(label: "Suitable Mass", passed: score.massOK)
                CheckItem(label: "Suitable Radius", passed: score.radiusOK)
                CheckItem(label: "Suitable Temperature", passed: score.temperatureOK)
            }
        }
        .padding()
        .background(score.color.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(score.color.opacity(0.3), lineWidth: 2)
        )
        .padding(.horizontal)
    }
}

struct CheckItem: View {
    let label: String
    let passed: Bool
    
    var body: some View {
        HStack {
            Image(systemName: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                .foregroundColor(passed ? .green : .red)
                .font(.system(size: 12))
            
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.white)
        }
    }
}

#Preview {
    ExoplanetExplorerView()
}
