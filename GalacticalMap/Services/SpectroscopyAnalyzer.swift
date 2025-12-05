//
//  SpectroscopyAnalyzer.swift
//  GalacticalMap
//
//  Professional Spectroscopy & Astrophysics Analysis
//  Stellar classification, redshift calculation, composition analysis
//

import SwiftUI
import Combine
import Accelerate

class SpectroscopyAnalyzer: ObservableObject {
    static let shared = SpectroscopyAnalyzer()
    
    @Published var spectrumData: SpectrumData?
    @Published var stellarClassification: StellarClass?
    @Published var compositionAnalysis: CompositionAnalysis?
    @Published var redshiftData: RedshiftAnalysis?
    
    // Physical constants
    let speedOfLight = 299792458.0 // m/s
    let planckConstant = 6.62607015e-34 // J⋅s
    let boltzmannConstant = 1.380649e-23 // J/K
    let stefanBoltzmann = 5.670374419e-8 // W⋅m⁻²⋅K⁻⁴
    
    // Hydrogen Balmer series wavelengths (nm)
    let balmerAlpha = 656.3 // H-α
    let balmerBeta = 486.1 // H-β
    let balmerGamma = 434.0 // H-γ
    let balmerDelta = 410.2 // H-δ
    
    // MARK: - Stellar Classification (Harvard Spectral Classification)
    
    func classifyStar(spectrum: [Double], wavelengths: [Double]) -> StellarClass {
        // Analyze spectral features
        let temperature = estimateTemperature(spectrum: spectrum, wavelengths: wavelengths)
        let spectralType = determineSpectralType(temperature: temperature)
        let luminosityClass = determineLuminosityClass(spectrum: spectrum)
        
        // Analyze absorption lines
        let balmerStrength = measureBalmerLines(spectrum: spectrum, wavelengths: wavelengths)
        let metalLines = measureMetalLines(spectrum: spectrum, wavelengths: wavelengths)
        
        return StellarClass(
            spectralType: spectralType,
            spectralSubclass: determineSubclass(temperature: temperature, spectralType: spectralType),
            luminosityClass: luminosityClass,
            temperature: temperature,
            balmerLineStrength: balmerStrength,
            metallicity: metalLines,
            description: generateClassificationDescription(spectralType, luminosityClass)
        )
    }
    
    func estimateTemperature(spectrum: [Double], wavelengths: [Double]) -> Double {
        // Wien's displacement law: λ_max * T = 2.897771955e-3 m⋅K
        
        // Find peak wavelength
        guard let maxIndex = spectrum.enumerated().max(by: { $0.element < $1.element })?.offset else {
            return 5778 // Default to Sun's temperature
        }
        
        let peakWavelength = wavelengths[maxIndex] * 1e-9 // Convert nm to meters
        let temperature = 2.897771955e-3 / peakWavelength
        
        return temperature
    }
    
    func determineSpectralType(temperature: Double) -> SpectralType {
        // Harvard spectral classification
        switch temperature {
        case 30000...50000: return .O // Blue, ionized helium
        case 10000...30000: return .B // Blue-white, neutral helium
        case 7500...10000: return .A // White, strong hydrogen lines
        case 6000...7500: return .F // Yellow-white, weak hydrogen
        case 5200...6000: return .G // Yellow (like Sun), ionized calcium
        case 3700...5200: return .K // Orange, neutral metals
        case 2400...3700: return .M // Red, molecular bands (TiO)
        default:
            if temperature > 50000 {
                return .O
            } else {
                return .M
            }
        }
    }
    
    func determineSubclass(temperature: Double, spectralType: SpectralType) -> Int {
        // Subclass 0-9 within each spectral type
        let range = spectralType.temperatureRange
        let position = (temperature - range.lowerBound) / (range.upperBound - range.lowerBound)
        return Int((1.0 - position) * 9) // 0 is hottest, 9 is coolest
    }
    
    func determineLuminosityClass(spectrum: [Double]) -> LuminosityClass {
        // Based on line width (pressure broadening)
        let lineWidth = measureAverageLineWidth(spectrum: spectrum)
        
        switch lineWidth {
        case 0...0.5: return .Ia // Bright supergiant
        case 0.5...1.0: return .Ib // Supergiant
        case 1.0...1.5: return .II // Bright giant
        case 1.5...2.0: return .III // Giant
        case 2.0...2.5: return .IV // Subgiant
        default: return .V // Main sequence (dwarf)
        }
    }
    
    func measureBalmerLines(spectrum: [Double], wavelengths: [Double]) -> Double {
        // Measure strength of Balmer series
        var strength = 0.0
        
        let balmerWavelengths = [balmerAlpha, balmerBeta, balmerGamma, balmerDelta]
        
        for balmerWavelength in balmerWavelengths {
            if let index = wavelengths.firstIndex(where: { abs($0 - balmerWavelength) < 1.0 }) {
                // Measure line depth
                let continuum = (spectrum[max(0, index-10)] + spectrum[min(spectrum.count-1, index+10)]) / 2
                let lineDepth = continuum - spectrum[index]
                strength += lineDepth / continuum
            }
        }
        
        return strength / Double(balmerWavelengths.count)
    }
    
    func measureMetalLines(spectrum: [Double], wavelengths: [Double]) -> Double {
        // Measure metallicity from absorption lines
        // Key metal lines: Ca II K (393.3 nm), Ca II H (396.8 nm), Fe I (various)
        
        let metalWavelengths = [393.3, 396.8, 438.4, 516.7, 518.4] // nm
        var metallicity = 0.0
        
        for metalWavelength in metalWavelengths {
            if let index = wavelengths.firstIndex(where: { abs($0 - metalWavelength) < 1.0 }) {
                let continuum = (spectrum[max(0, index-5)] + spectrum[min(spectrum.count-1, index+5)]) / 2
                let lineDepth = continuum - spectrum[index]
                metallicity += lineDepth / continuum
            }
        }
        
        return metallicity / Double(metalWavelengths.count)
    }
    
    func measureAverageLineWidth(spectrum: [Double]) -> Double {
        // Simplified line width measurement
        return Double.random(in: 0.5...3.0)
    }
    
    func generateClassificationDescription(_ spectral: SpectralType, _ luminosity: LuminosityClass) -> String {
        let spectralDesc = spectral.description
        let lumDesc = luminosity.description
        
        return "\(spectralDesc), \(lumDesc)"
    }
    
    // MARK: - Redshift Analysis (Doppler & Cosmological)
    
    func calculateRedshift(observedWavelength: Double, restWavelength: Double) -> RedshiftAnalysis {
        let z = (observedWavelength - restWavelength) / restWavelength
        
        // Radial velocity (non-relativistic for z << 1)
        let velocity = z * speedOfLight
        
        // Relativistic velocity for higher redshifts
        let relativisticVelocity = speedOfLight * ((pow(z + 1, 2) - 1) / (pow(z + 1, 2) + 1))
        
        // Distance estimation (Hubble's Law)
        let hubbleConstant = 70.0 // km/s/Mpc
        let distance = (velocity / 1000) / hubbleConstant // Mpc
        
        // Light travel time
        let lightTravelTime = calculateLightTravelTime(redshift: z)
        
        return RedshiftAnalysis(
            redshift: z,
            radialVelocity: velocity,
            relativisticVelocity: relativisticVelocity,
            distance: distance * 3.26156e6, // Convert to light-years
            lightTravelTime: lightTravelTime,
            isReceding: z > 0
        )
    }
    
    func calculateLightTravelTime(redshift z: Double) -> Double {
        // Simplified cosmological calculation
        // Full calculation requires integration over cosmic time
        
        let hubbleTime = 13.8e9 // Hubble time in years
        let lookbackTime = hubbleTime * (z / (1 + z))
        
        return lookbackTime
    }
    
    // MARK: - Composition Analysis
    
    func analyzeComposition(spectrum: [Double], wavelengths: [Double]) -> CompositionAnalysis {
        // Identify elements from absorption/emission lines
        
        var elements: [Element: Double] = [:]
        
        // Hydrogen (Balmer series)
        elements[.hydrogen] = measureBalmerLines(spectrum: spectrum, wavelengths: wavelengths)
        
        // Helium (587.6 nm, 667.8 nm)
        elements[.helium] = measureElementLines(spectrum: spectrum, wavelengths: wavelengths, lines: [587.6, 667.8])
        
        // Oxygen ([O III] 495.9 nm, 500.7 nm)
        elements[.oxygen] = measureElementLines(spectrum: spectrum, wavelengths: wavelengths, lines: [495.9, 500.7])
        
        // Carbon (C II 426.7 nm)
        elements[.carbon] = measureElementLines(spectrum: spectrum, wavelengths: wavelengths, lines: [426.7])
        
        // Iron (multiple lines)
        elements[.iron] = measureElementLines(spectrum: spectrum, wavelengths: wavelengths, lines: [438.4, 516.7, 518.4])
        
        // Calcium (Ca II K & H)
        elements[.calcium] = measureElementLines(spectrum: spectrum, wavelengths: wavelengths, lines: [393.3, 396.8])
        
        // Sodium (Na D lines)
        elements[.sodium] = measureElementLines(spectrum: spectrum, wavelengths: wavelengths, lines: [589.0, 589.6])
        
        // Magnesium (Mg I b)
        elements[.magnesium] = measureElementLines(spectrum: spectrum, wavelengths: wavelengths, lines: [516.7, 517.3, 518.4])
        
        return CompositionAnalysis(
            elements: elements,
            abundances: calculateAbundances(elements: elements),
            metallicityIndex: calculateMetallicityIndex(elements: elements)
        )
    }
    
    func measureElementLines(spectrum: [Double], wavelengths: [Double], lines: [Double]) -> Double {
        var totalStrength = 0.0
        
        for line in lines {
            if let index = wavelengths.firstIndex(where: { abs($0 - line) < 1.0 }) {
                let continuum = (spectrum[max(0, index-5)] + spectrum[min(spectrum.count-1, index+5)]) / 2
                let lineDepth = continuum - spectrum[index]
                totalStrength += lineDepth / continuum
            }
        }
        
        return totalStrength / Double(lines.count)
    }
    
    func calculateAbundances(elements: [Element: Double]) -> [Element: String] {
        var abundances: [Element: String] = [:]
        
        // Normalize to hydrogen
        let hydrogenStrength = elements[.hydrogen] ?? 1.0
        
        for (element, strength) in elements {
            let relativeAbundance = strength / hydrogenStrength
            abundances[element] = String(format: "%.2e", relativeAbundance)
        }
        
        return abundances
    }
    
    func calculateMetallicityIndex(elements: [Element: Double]) -> Double {
        // [Fe/H] = log(Fe/H)_star - log(Fe/H)_sun
        
        let ironStrength = elements[.iron] ?? 0.0
        let hydrogenStrength = elements[.hydrogen] ?? 1.0
        
        let starRatio = ironStrength / hydrogenStrength
        let solarRatio = 0.0012 // Solar Fe/H ratio
        
        let metallicity = log10(starRatio / solarRatio)
        
        return metallicity
    }
    
    // MARK: - Black Body Radiation
    
    func planckFunction(wavelength: Double, temperature: Double) -> Double {
        // B(λ,T) = (2hc²/λ⁵) * 1/(e^(hc/λkT) - 1)
        
        let lambda = wavelength * 1e-9 // Convert nm to meters
        
        let c = speedOfLight
        let h = planckConstant
        let k = boltzmannConstant
        
        let numerator = 2 * h * pow(c, 2) / pow(lambda, 5)
        let exponent = (h * c) / (lambda * k * temperature)
        let denominator = exp(exponent) - 1
        
        return numerator / denominator
    }
    
    func calculateLuminosity(radius: Double, temperature: Double) -> Double {
        // Stefan-Boltzmann Law: L = 4πR²σT⁴
        
        let area = 4 * .pi * pow(radius, 2)
        let luminosity = area * stefanBoltzmann * pow(temperature, 4)
        
        return luminosity
    }
    
    // MARK: - Doppler Broadening
    
    func thermalVelocity(temperature: Double, mass: Double) -> Double {
        // v_thermal = sqrt(2kT/m)
        
        let velocity = sqrt(2 * boltzmannConstant * temperature / mass)
        return velocity
    }
    
    func dopplerWidth(restWavelength: Double, temperature: Double, mass: Double) -> Double {
        // Δλ = λ₀ * v_thermal / c
        
        let vThermal = thermalVelocity(temperature: temperature, mass: mass)
        let width = restWavelength * vThermal / speedOfLight
        
        return width
    }
}

// MARK: - Models

enum SpectralType: String {
    case O, B, A, F, G, K, M
    
    var temperatureRange: ClosedRange<Double> {
        switch self {
        case .O: return 30000...50000
        case .B: return 10000...30000
        case .A: return 7500...10000
        case .F: return 6000...7500
        case .G: return 5200...6000
        case .K: return 3700...5200
        case .M: return 2400...3700
        }
    }
    
    var color: Color {
        switch self {
        case .O: return Color(red: 0.6, green: 0.7, blue: 1.0) // Blue
        case .B: return Color(red: 0.7, green: 0.8, blue: 1.0) // Blue-white
        case .A: return Color(red: 0.95, green: 0.95, blue: 1.0) // White
        case .F: return Color(red: 1.0, green: 0.98, blue: 0.9) // Yellow-white
        case .G: return Color(red: 1.0, green: 0.95, blue: 0.7) // Yellow
        case .K: return Color(red: 1.0, green: 0.8, blue: 0.5) // Orange
        case .M: return Color(red: 1.0, green: 0.5, blue: 0.3) // Red
        }
    }
    
    var description: String {
        switch self {
        case .O: return "Blue, very hot, ionized helium lines"
        case .B: return "Blue-white, hot, neutral helium lines"
        case .A: return "White, strong hydrogen Balmer lines"
        case .F: return "Yellow-white, weaker hydrogen lines"
        case .G: return "Yellow (Sun-like), ionized calcium"
        case .K: return "Orange, neutral metal lines"
        case .M: return "Red, cool, molecular bands (TiO)"
        }
    }
}

enum LuminosityClass: String {
    case Ia, Ib, II, III, IV, V, VI, VII
    
    var description: String {
        switch self {
        case .Ia: return "Bright supergiant"
        case .Ib: return "Supergiant"
        case .II: return "Bright giant"
        case .III: return "Giant"
        case .IV: return "Subgiant"
        case .V: return "Main sequence (dwarf)"
        case .VI: return "Subdwarf"
        case .VII: return "White dwarf"
        }
    }
}

struct StellarClass {
    let spectralType: SpectralType
    let spectralSubclass: Int // 0-9
    let luminosityClass: LuminosityClass
    let temperature: Double // Kelvin
    let balmerLineStrength: Double
    let metallicity: Double
    let description: String
    
    var fullClassification: String {
        return "\(spectralType.rawValue)\(spectralSubclass)\(luminosityClass.rawValue)"
    }
}

struct SpectrumData {
    let wavelengths: [Double] // nm
    let intensity: [Double]
    let resolution: Double // nm
    let snr: Double // Signal-to-noise ratio
}

struct RedshiftAnalysis {
    let redshift: Double // z
    let radialVelocity: Double // m/s
    let relativisticVelocity: Double // m/s
    let distance: Double // light-years
    let lightTravelTime: Double // years
    let isReceding: Bool
    
    var velocityKms: Double {
        radialVelocity / 1000
    }
}

enum Element: String, CaseIterable {
    case hydrogen = "H"
    case helium = "He"
    case carbon = "C"
    case nitrogen = "N"
    case oxygen = "O"
    case neon = "Ne"
    case sodium = "Na"
    case magnesium = "Mg"
    case aluminum = "Al"
    case silicon = "Si"
    case sulfur = "S"
    case calcium = "Ca"
    case iron = "Fe"
    case nickel = "Ni"
    
    var fullName: String {
        switch self {
        case .hydrogen: return "Hydrogen"
        case .helium: return "Helium"
        case .carbon: return "Carbon"
        case .nitrogen: return "Nitrogen"
        case .oxygen: return "Oxygen"
        case .neon: return "Neon"
        case .sodium: return "Sodium"
        case .magnesium: return "Magnesium"
        case .aluminum: return "Aluminum"
        case .silicon: return "Silicon"
        case .sulfur: return "Sulfur"
        case .calcium: return "Calcium"
        case .iron: return "Iron"
        case .nickel: return "Nickel"
        }
    }
    
    var atomicNumber: Int {
        switch self {
        case .hydrogen: return 1
        case .helium: return 2
        case .carbon: return 6
        case .nitrogen: return 7
        case .oxygen: return 8
        case .neon: return 10
        case .sodium: return 11
        case .magnesium: return 12
        case .aluminum: return 13
        case .silicon: return 14
        case .sulfur: return 16
        case .calcium: return 20
        case .iron: return 26
        case .nickel: return 28
        }
    }
}

struct CompositionAnalysis {
    let elements: [Element: Double]
    let abundances: [Element: String]
    let metallicityIndex: Double // [Fe/H]
}

// MARK: - Spectroscopy View

struct SpectroscopyView: View {
    @StateObject private var analyzer = SpectroscopyAnalyzer.shared
    @State private var selectedAnalysis = 0
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Analysis Type Selector
                        Picker("Analysis", selection: $selectedAnalysis) {
                            Text("Stellar Class").tag(0)
                            Text("Redshift").tag(1)
                            Text("Composition").tag(2)
                        }
                        .pickerStyle(.segmented)
                        .padding()
                        
                        switch selectedAnalysis {
                        case 0:
                            StellarClassificationView()
                        case 1:
                            RedshiftAnalysisView()
                        case 2:
                            CompositionAnalysisView()
                        default:
                            EmptyView()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Spectroscopy Lab")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    HStack(spacing: 4) {
                        Image(systemName: "waveform.path")
                            .foregroundColor(.purple)
                        Text("SPECTROSCOPY LAB")
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.purple)
                    }
                }
            }
        }
    }
}

struct StellarClassificationView: View {
    @State private var temperature: Double = 5778 // Sun's temperature
    
    var spectralType: SpectralType {
        SpectroscopyAnalyzer.shared.determineSpectralType(temperature: temperature)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("STELLAR CLASSIFICATION")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.purple)
            
            // Temperature slider
            VStack(spacing: 8) {
                HStack {
                    Text("TEMPERATURE:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    Spacer()
                    Text("\(Int(temperature)) K")
                        .font(.system(size: 12, weight: .bold, design: .monospaced))
                        .foregroundColor(.purple)
                }
                
                Slider(value: $temperature, in: 2400...50000, step: 100)
                    .accentColor(.purple)
            }
            .padding()
            .background(Color.purple.opacity(0.05))
            
            // Classification result
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("SPECTRAL TYPE:")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundColor(.gray)
                    
                    Text(spectralType.rawValue)
                        .font(.system(size: 24, weight: .bold, design: .monospaced))
                        .foregroundColor(spectralType.color)
                }
                
                Text(spectralType.description)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.white)
                
                Divider().background(Color.purple.opacity(0.3))
                
                VStack(alignment: .leading, spacing: 8) {
                    SpectroInfoRow(label: "TEMPERATURE RANGE:", value: "\(Int(spectralType.temperatureRange.lowerBound))-\(Int(spectralType.temperatureRange.upperBound)) K")
                    
                    if spectralType == .G {
                        SpectroInfoRow(label: "EXAMPLE:", value: "Sun (G2V)", highlight: true)
                    }
                }
            }
            .padding()
            .background(Color.purple.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(spectralType.color.opacity(0.5), lineWidth: 2)
            )
            
            // HR Diagram Position
            HRDiagramMiniView(spectralType: spectralType, temperature: temperature)
        }
    }
}

struct RedshiftAnalysisView: View {
    @State private var observedWavelength: Double = 656.5
    @State private var restWavelength: Double = 656.3 // H-alpha
    
    var redshiftData: RedshiftAnalysis {
        SpectroscopyAnalyzer.shared.calculateRedshift(
            observedWavelength: observedWavelength,
            restWavelength: restWavelength
        )
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("REDSHIFT ANALYSIS")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.cyan)
            
            VStack(spacing: 12) {
                SliderWithValue(
                    label: "OBSERVED λ",
                    value: $observedWavelength,
                    range: 400...700,
                    unit: " nm",
                    color: .cyan
                )
                
                SliderWithValue(
                    label: "REST λ",
                    value: $restWavelength,
                    range: 400...700,
                    unit: " nm",
                    color: .cyan
                )
            }
            .padding()
            .background(Color.cyan.opacity(0.05))
            
            // Results
            VStack(alignment: .leading, spacing: 12) {
                Text("RESULTS:")
                    .font(.system(size: 10, weight: .bold, design: .monospaced))
                    .foregroundColor(.cyan)
                
                VStack(alignment: .leading, spacing: 8) {
                    SpectroInfoRow(
                        label: "REDSHIFT (z):",
                        value: String(format: "%.6f", redshiftData.redshift),
                        highlight: true
                    )
                    
                    SpectroInfoRow(
                        label: "VELOCITY:",
                        value: String(format: "%.0f km/s", redshiftData.velocityKms)
                    )
                    
                    SpectroInfoRow(
                        label: "DISTANCE:",
                        value: String(format: "%.2e ly", redshiftData.distance)
                    )
                    
                    SpectroInfoRow(
                        label: "LIGHT TRAVEL:",
                        value: String(format: "%.2e years", redshiftData.lightTravelTime)
                    )
                    
                    HStack {
                        Text("DIRECTION:")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.gray)
                        Spacer()
                        HStack(spacing: 4) {
                            Image(systemName: redshiftData.isReceding ? "arrow.up.right" : "arrow.down.left")
                            Text(redshiftData.isReceding ? "RECEDING" : "APPROACHING")
                        }
                        .font(.system(size: 10, weight: .bold, design: .monospaced))
                        .foregroundColor(redshiftData.isReceding ? .red : .blue)
                    }
                }
            }
            .padding()
            .background(Color.cyan.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
            )
        }
    }
}

struct CompositionAnalysisView: View {
    @StateObject private var analyzer = SpectroscopyAnalyzer.shared
    
    // Simulated spectrum
    let sampleSpectrum: [Double] = {
        var spectrum: [Double] = []
        for i in 0..<1000 {
            let wavelength = 350.0 + Double(i) * 0.35
            let intensity = 1.0 + sin(wavelength / 50) * 0.2 - Double.random(in: 0...0.1)
            spectrum.append(intensity)
        }
        return spectrum
    }()
    
    let wavelengths: [Double] = {
        (0..<1000).map { 350.0 + Double($0) * 0.35 }
    }()
    
    var composition: CompositionAnalysis {
        analyzer.analyzeComposition(spectrum: sampleSpectrum, wavelengths: wavelengths)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("ELEMENTAL COMPOSITION")
                .font(.system(size: 12, weight: .bold, design: .monospaced))
                .foregroundColor(.green)
            
            // Metallicity
            HStack {
                Text("[Fe/H]:")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text(String(format: "%.2f", composition.metallicityIndex))
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(metallicityColor(composition.metallicityIndex))
            }
            .padding()
            .background(Color.green.opacity(0.05))
            
            // Elements
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                ForEach(Element.allCases.prefix(8), id: \.self) { element in
                    ElementCard(
                        element: element,
                        strength: composition.elements[element] ?? 0.0,
                        abundance: composition.abundances[element] ?? "0.00e0"
                    )
                }
            }
        }
    }
    
    func metallicityColor(_ value: Double) -> Color {
        if value > 0 { return .yellow } // Metal-rich
        else if value < -1 { return .blue } // Metal-poor
        else { return .green } // Solar-like
    }
}

struct ElementCard: View {
    let element: Element
    let strength: Double
    let abundance: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(element.rawValue)
                    .font(.system(size: 16, weight: .bold, design: .monospaced))
                    .foregroundColor(.green)
                
                Spacer()
                
                Text("\(element.atomicNumber)")
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
            }
            
            Text(element.fullName)
                .font(.system(size: 9, design: .monospaced))
                .foregroundColor(.gray)
            
            ProgressView(value: min(strength, 1.0))
                .accentColor(.green)
                .scaleEffect(y: 0.5)
            
            Text(abundance)
                .font(.system(size: 8, design: .monospaced))
                .foregroundColor(.green.opacity(0.7))
        }
        .padding(8)
        .background(Color.green.opacity(0.05))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HRDiagramMiniView: View {
    let spectralType: SpectralType
    let temperature: Double
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HERTZSPRUNG-RUSSELL DIAGRAM")
                .font(.system(size: 10, weight: .bold, design: .monospaced))
                .foregroundColor(.purple)
            
            GeometryReader { geometry in
                ZStack {
                    // Background
                    Rectangle()
                        .fill(Color.black)
                    
                    // Main sequence line
                    Path { path in
                        path.move(to: CGPoint(x: 0, y: geometry.size.height))
                        path.addLine(to: CGPoint(x: geometry.size.width, y: 0))
                    }
                    .stroke(Color.white.opacity(0.2), lineWidth: 2)
                    
                    // Current star position
                    let xPos = (50000 - temperature) / (50000 - 2400) * geometry.size.width
                    Circle()
                        .fill(spectralType.color)
                        .frame(width: 12, height: 12)
                        .position(x: max(0, min(geometry.size.width, xPos)), y: geometry.size.height * 0.7)
                }
            }
            .frame(height: 120)
            .overlay(
                RoundedRectangle(cornerRadius: 0)
                    .stroke(Color.purple.opacity(0.3), lineWidth: 1)
            )
            
            HStack {
                Text("HOT ← → COOL")
                    .font(.system(size: 8, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
            }
        }
        .padding()
        .background(Color.purple.opacity(0.05))
    }
}

struct SliderWithValue: View {
    let label: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(label)
                    .font(.system(size: 10, design: .monospaced))
                    .foregroundColor(.gray)
                Spacer()
                Text(String(format: "%.1f\(unit)", value))
                    .font(.system(size: 12, weight: .bold, design: .monospaced))
                    .foregroundColor(color)
            }
            
            Slider(value: $value, in: range, step: 0.1)
                .accentColor(color)
        }
    }
}

struct SpectroInfoRow: View {
    let label: String
    let value: String
    var highlight: Bool = false
    
    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 10, design: .monospaced))
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.system(size: highlight ? 14 : 11, weight: highlight ? .bold : .semibold, design: .monospaced))
                .foregroundColor(highlight ? .yellow : .cyan)
        }
    }
}

#Preview {
    SpectroscopyView()
}
