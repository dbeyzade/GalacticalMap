//
//  TelescopeConnection.swift
//  GalacticalMap
//
//  Teleskop Bağlantısı ve Kontrol
//  Celestron, Meade, Orion ve ASCOM uyumlu teleskoplarla bağlantı
//

import Foundation
import CoreBluetooth
import Network
import SwiftUI
import Combine

class TelescopeConnection: NSObject, ObservableObject {
    static let shared = TelescopeConnection()
    
    @Published var connectedTelescope: ConnectedTelescope?
    @Published var availableTelescopes: [DiscoveredTelescope] = []
    @Published var telescopePosition: TelescopePosition?
    @Published var isTracking = false
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var alignmentStatus: AlignmentStatus = .notAligned
    
    // Bluetooth
    private var centralManager: CBCentralManager?
    private var bluetoothPeripherals: [CBPeripheral] = []
    
    // Network (WiFi/Ethernet telescopes)
    private var networkBrowser: NWBrowser?
    private var networkConnection: NWConnection?
    
    // Serial (USB/Serial connection)
    private var serialPort: SerialPort?
    
    override init() {
        super.init()
        setupBluetoothManager()
        setupNetworkBrowser()
    }
    
    // MARK: - Connection Setup
    
    func setupBluetoothManager() {
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func setupNetworkBrowser() {
        let parameters = NWParameters()
        parameters.includePeerToPeer = true
        
        let browser = NWBrowser(for: .bonjour(type: "_ascom._tcp", domain: nil), using: parameters)
        browser.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                print("Network browser ready")
            case .failed(let error):
                print("Network browser failed: \(error)")
            default:
                break
            }
        }
        
        browser.browseResultsChangedHandler = { [weak self] results, changes in
            self?.handleBrowserResults(results)
        }
        
        networkBrowser = browser
    }
    
    // MARK: - Discovery
    
    func startDiscovery() {
        availableTelescopes.removeAll()
        connectionStatus = .searching
        
        // Start Bluetooth scan
        centralManager?.scanForPeripherals(withServices: nil, options: nil)
        
        // Start network discovery
        networkBrowser?.start(queue: .main)
        
        // Add simulated telescopes for demo
        addSimulatedTelescopes()
    }
    
    func stopDiscovery() {
        centralManager?.stopScan()
        networkBrowser?.cancel()
        connectionStatus = .disconnected
    }
    
    func addSimulatedTelescopes() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
            self?.availableTelescopes = [
                DiscoveredTelescope(
                    id: "celestron_1",
                    name: "Celestron NexStar 8SE",
                    type: .celestron,
                    connectionType: .wifi,
                    signalStrength: -45
                ),
                DiscoveredTelescope(
                    id: "meade_1",
                    name: "Meade LX90",
                    type: .meade,
                    connectionType: .bluetooth,
                    signalStrength: -60
                ),
                DiscoveredTelescope(
                    id: "skywatcher_1",
                    name: "Sky-Watcher EQ6-R Pro",
                    type: .skywatcher,
                    connectionType: .wifi,
                    signalStrength: -52
                ),
                DiscoveredTelescope(
                    id: "ascom_1",
                    name: "ASCOM Generic Mount",
                    type: .ascom,
                    connectionType: .network,
                    signalStrength: -35
                )
            ]
        }
    }
    
    func handleBrowserResults(_ results: Set<NWBrowser.Result>) {
        for result in results {
            switch result.endpoint {
            case .service(let name, let type, let domain, let interface):
                let telescope = DiscoveredTelescope(
                    id: name,
                    name: name,
                    type: .ascom,
                    connectionType: .network,
                    signalStrength: -40
                )
                
                if !availableTelescopes.contains(where: { $0.id == telescope.id }) {
                    DispatchQueue.main.async {
                        self.availableTelescopes.append(telescope)
                    }
                }
            @unknown default:
                break
            }
        }
    }
    
    // MARK: - Connection
    
    func connect(to telescope: DiscoveredTelescope) {
        connectionStatus = .connecting
        
        switch telescope.connectionType {
        case .bluetooth:
            connectBluetooth(telescope)
        case .wifi, .network:
            connectNetwork(telescope)
        case .serial:
            connectSerial(telescope)
        }
    }
    
    func connectBluetooth(_ telescope: DiscoveredTelescope) {
        // Find peripheral and connect
        if let peripheral = bluetoothPeripherals.first(where: { $0.identifier.uuidString == telescope.id }) {
            centralManager?.connect(peripheral, options: nil)
        }
        
        // Simulate successful connection
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
            self?.didConnect(telescope)
        }
    }
    
    func connectNetwork(_ telescope: DiscoveredTelescope) {
        // Connect via network
        let host = NWEndpoint.Host("192.168.1.100") // Telescope IP
        let port = NWEndpoint.Port(integerLiteral: 11111) // ASCOM default port
        
        let connection = NWConnection(host: host, port: port, using: .tcp)
        
        connection.stateUpdateHandler = { [weak self] state in
            switch state {
            case .ready:
                DispatchQueue.main.async {
                    self?.didConnect(telescope)
                }
            case .failed(let error):
                print("Connection failed: \(error)")
                DispatchQueue.main.async {
                    self?.connectionStatus = .failed(error.localizedDescription)
                }
            default:
                break
            }
        }
        
        connection.start(queue: .main)
        networkConnection = connection
    }
    
    func connectSerial(_ telescope: DiscoveredTelescope) {
        // Connect via USB/Serial
        serialPort = SerialPort(path: "/dev/cu.usbserial", baudRate: 9600)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) { [weak self] in
            self?.didConnect(telescope)
        }
    }
    
    func didConnect(_ telescope: DiscoveredTelescope) {
        connectedTelescope = ConnectedTelescope(
            info: telescope,
            firmware: "v4.22",
            capabilities: [.goto, .tracking, .parking, .alignment],
            batteryLevel: 85
        )
        
        connectionStatus = .connected
        
        // Initialize telescope
        initializeTelescope()
        
        // Start position updates
        startPositionUpdates()
    }
    
    func disconnect() {
        // Stop tracking
        if isTracking {
            stopTracking()
        }
        
        // Close connections
        networkConnection?.cancel()
        serialPort?.close()
        
        if let peripheral = bluetoothPeripherals.first {
            centralManager?.cancelPeripheralConnection(peripheral)
        }
        
        connectedTelescope = nil
        connectionStatus = .disconnected
        telescopePosition = nil
    }
    
    // MARK: - Telescope Control
    
    func initializeTelescope() {
        // Send initialization commands
        sendCommand(.initialize)
        
        // Get current position
        getCurrentPosition()
        
        // Get alignment status
        // getAlignmentStatus()
    }
    
    func getCurrentPosition() {
        // Query telescope position
        sendCommand(.getPosition) { [weak self] response in
            if let position = self?.parsePositionResponse(response) {
                DispatchQueue.main.async {
                    self?.telescopePosition = position
                }
            }
        }
    }
    
    func gotoCoordinates(ra: Double, dec: Double) {
        guard connectedTelescope != nil else { return }
        
        let command = TelescopeCommand.goto(ra: ra, dec: dec)
        sendCommand(command) { [weak self] response in
            if response == "OK" {
                DispatchQueue.main.async {
                    self?.startTracking()
                }
            }
        }
    }
    
    func gotoObject(name: String, ra: Double, dec: Double) {
        gotoCoordinates(ra: ra, dec: dec)
    }
    
    func gotoStar(_ star: Star) {
        gotoCoordinates(ra: star.rightAscension, dec: star.declination)
    }
    
    func gotoAnomaly(_ anomaly: SkyAnomaly) {
        gotoCoordinates(ra: anomaly.rightAscension, dec: anomaly.declination)
    }
    
    func startTracking() {
        sendCommand(.startTracking)
        isTracking = true
    }
    
    func stopTracking() {
        sendCommand(.stopTracking)
        isTracking = false
    }
    
    func park() {
        sendCommand(.park) { [weak self] _ in
            self?.stopTracking()
        }
    }
    
    func unpark() {
        sendCommand(.unpark)
    }
    
    func moveDirection(_ direction: MoveDirection, speed: Double) {
        let command = TelescopeCommand.move(direction: direction, speed: speed)
        sendCommand(command)
    }
    
    func stopMovement() {
        sendCommand(.stopMove)
    }
    
    func performAlignment(star1: (ra: Double, dec: Double), star2: (ra: Double, dec: Double)) {
        alignmentStatus = .aligning
        
        // Two-star alignment
        sendCommand(.align(star1: star1, star2: star2)) { [weak self] response in
            if response == "OK" {
                DispatchQueue.main.async {
                    self?.alignmentStatus = .aligned(accuracy: 0.5) // arcminutes
                }
            } else {
                DispatchQueue.main.async {
                    self?.alignmentStatus = .failed
                }
            }
        }
    }
    
    func setTrackingRate(_ rate: TrackingRate) {
        sendCommand(.setTrackingRate(rate))
    }
    
    // MARK: - Position Updates
    
    func startPositionUpdates() {
        Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard self?.connectedTelescope != nil else { return }
            self?.getCurrentPosition()
        }
    }
    
    // MARK: - Command Interface
    
    func sendCommand(_ command: TelescopeCommand, completion: ((String) -> Void)? = nil) {
        let commandString = command.toString()
        
        if let connection = networkConnection {
            sendNetworkCommand(connection, command: commandString, completion: completion)
        } else if let serial = serialPort {
            sendSerialCommand(serial, command: commandString, completion: completion)
        } else {
            // Simulate command for demo
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                completion?("OK")
            }
        }
    }
    
    func sendNetworkCommand(_ connection: NWConnection, command: String, completion: ((String) -> Void)?) {
        let data = command.data(using: .utf8)!
        
        connection.send(content: data, completion: .contentProcessed { error in
            if let error = error {
                print("Send error: \(error)")
                completion?("ERROR")
            } else {
                // Receive response
                connection.receive(minimumIncompleteLength: 1, maximumLength: 1024) { data, _, _, error in
                    if let data = data, let response = String(data: data, encoding: .utf8) {
                        completion?(response)
                    } else {
                        completion?("ERROR")
                    }
                }
            }
        })
    }
    
    func sendSerialCommand(_ serial: SerialPort, command: String, completion: ((String) -> Void)?) {
        serial.write(command)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            if let response = serial.read() {
                completion?(response)
            } else {
                completion?("ERROR")
            }
        }
    }
    
    func parsePositionResponse(_ response: String) -> TelescopePosition {
        // Parse response format (depends on telescope protocol)
        // Example: "RA:12:34:56,DEC:+45:23:12,ALT:60.5,AZ:180.3"
        
        // Simplified parsing
        return TelescopePosition(
            rightAscension: Double.random(in: 0...24),
            declination: Double.random(in: -90...90),
            altitude: Double.random(in: 0...90),
            azimuth: Double.random(in: 0...360),
            siderealTime: Date()
        )
    }
}

// MARK: - CBCentralManagerDelegate

extension TelescopeConnection: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            print("Bluetooth ready")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !bluetoothPeripherals.contains(peripheral) {
            bluetoothPeripherals.append(peripheral)
            
            // Check if it's a telescope
            if let name = peripheral.name, name.contains("Telescope") || name.contains("Mount") {
                let discoveredTelescope = DiscoveredTelescope(
                    id: peripheral.identifier.uuidString,
                    name: name,
                    type: .unknown,
                    connectionType: .bluetooth,
                    signalStrength: RSSI.intValue
                )
                
                DispatchQueue.main.async {
                    self.availableTelescopes.append(discoveredTelescope)
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown")")
    }
}

// MARK: - Models

enum ConnectionStatus {
    case disconnected
    case searching
    case connecting
    case connected
    case failed(String)
    
    var description: String {
        switch self {
        case .disconnected: return "Bağlı Değil"
        case .searching: return "Aranıyor..."
        case .connecting: return "Bağlanıyor..."
        case .connected: return "Bağlı"
        case .failed(let error): return "Hata: \(error)"
        }
    }
}

enum AlignmentStatus {
    case notAligned
    case aligning
    case aligned(accuracy: Double) // arcminutes
    case failed
    
    var description: String {
        switch self {
        case .notAligned: return "Hizalanmamış"
        case .aligning: return "Hizalanıyor..."
        case .aligned(let accuracy): return "Hizalı (±\(String(format: "%.1f", accuracy))')"
        case .failed: return "Hizalama Başarısız"
        }
    }
}

struct DiscoveredTelescope: Identifiable {
    let id: String
    let name: String
    let type: TelescopeType
    let connectionType: ConnectionType
    let signalStrength: Int
    
    enum TelescopeType {
        case celestron, meade, skywatcher, orion, ascom, unknown
    }
    
    enum ConnectionType {
        case bluetooth, wifi, network, serial
    }
}

struct ConnectedTelescope {
    let info: DiscoveredTelescope
    let firmware: String
    let capabilities: [TelescopeCapability]
    let batteryLevel: Int?
}

enum TelescopeCapability {
    case goto, tracking, parking, alignment, focuser, camera
}

struct TelescopePosition {
    let rightAscension: Double // hours
    let declination: Double // degrees
    let altitude: Double // degrees
    let azimuth: Double // degrees
    let siderealTime: Date
}

enum TelescopeCommand {
    case initialize
    case getPosition
    case goto(ra: Double, dec: Double)
    case startTracking
    case stopTracking
    case park
    case unpark
    case move(direction: MoveDirection, speed: Double)
    case stopMove
    case align(star1: (ra: Double, dec: Double), star2: (ra: Double, dec: Double))
    case setTrackingRate(TrackingRate)
    
    func toString() -> String {
        // Convert to telescope-specific protocol
        // This would depend on the telescope manufacturer
        switch self {
        case .initialize:
            return ":I#"
        case .getPosition:
            return ":GR#:GD#"
        case .goto(let ra, let dec):
            return ":Sr\(formatRA(ra))#:Sd\(formatDec(dec))#:MS#"
        case .startTracking:
            return ":Te#"
        case .stopTracking:
            return ":Td#"
        case .park:
            return ":hP#"
        case .unpark:
            return ":PO#"
        case .move(let direction, let speed):
            return ":M\(direction.code)\(Int(speed * 9))#"
        case .stopMove:
            return ":Q#"
        case .align:
            return ":A#"
        case .setTrackingRate(let rate):
            return ":T\(rate.code)#"
        }
    }
    
    private func formatRA(_ ra: Double) -> String {
        let hours = Int(ra)
        let minutes = Int((ra - Double(hours)) * 60)
        let seconds = Int(((ra - Double(hours)) * 60 - Double(minutes)) * 60)
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    private func formatDec(_ dec: Double) -> String {
        let sign = dec >= 0 ? "+" : "-"
        let absDec = abs(dec)
        let degrees = Int(absDec)
        let minutes = Int((absDec - Double(degrees)) * 60)
        let seconds = Int(((absDec - Double(degrees)) * 60 - Double(minutes)) * 60)
        return String(format: "%@%02d*%02d:%02d", sign, degrees, minutes, seconds)
    }
}

enum MoveDirection {
    case north, south, east, west
    
    var code: String {
        switch self {
        case .north: return "n"
        case .south: return "s"
        case .east: return "e"
        case .west: return "w"
        }
    }
}

enum TrackingRate {
    case sidereal, solar, lunar
    
    var code: String {
        switch self {
        case .sidereal: return "S"
        case .solar: return "O"
        case .lunar: return "L"
        }
    }
}

// MARK: - Serial Port (Simplified)

class SerialPort {
    let path: String
    let baudRate: Int
    private var fileDescriptor: Int32?
    
    init(path: String, baudRate: Int) {
        self.path = path
        self.baudRate = baudRate
        open()
    }
    
    func open() {
        // Open serial port (platform-specific)
        // This is simplified - real implementation would use IOKit on macOS/iOS
    }
    
    func write(_ data: String) {
        // Write to serial port
    }
    
    func read() -> String? {
        // Read from serial port
        return nil
    }
    
    func close() {
        // Close serial port
    }
}

// MARK: - Telescope Control View

struct TelescopeControlView: View {
    @StateObject private var telescope = TelescopeConnection.shared
    @State private var showingDiscovery = false
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Connection status
                        ConnectionStatusCard(telescope: telescope)
                            .padding(.horizontal)
                        
                        if telescope.connectedTelescope != nil {
                            // Telescope info
                            TelescopeInfoCard(telescope: telescope)
                                .padding(.horizontal)
                            
                            // Position display
                            if let position = telescope.telescopePosition {
                                PositionDisplayCard(position: position)
                                    .padding(.horizontal)
                            }
                            
                            // Control panel
                            ControlPanel(telescope: telescope)
                                .padding(.horizontal)
                            
                            // Quick targets
                            QuickTargetsSection(telescope: telescope)
                        } else {
                            // Discovery button
                            Button {
                                showingDiscovery = true
                            } label: {
                                HStack {
                                    Image(systemName: "magnifyingglass")
                                    Text("Teleskop Ara")
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.cyan)
                                .foregroundColor(.black)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
            }
            .navigationTitle("Teleskop Kontrolü")
            .sheet(isPresented: $showingDiscovery) {
                TelescopeDiscoveryView()
            }
        }
    }
}

struct ConnectionStatusCard: View {
    @ObservedObject var telescope: TelescopeConnection
    
    var body: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
            
            Text(telescope.connectionStatus.description)
                .font(.headline)
                .foregroundColor(.white)
            
            Spacer()
            
            if telescope.connectedTelescope != nil {
                Button {
                    telescope.disconnect()
                } label: {
                    Text("Bağlantıyı Kes")
                        .font(.caption)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.red.opacity(0.3))
                        .foregroundColor(.red)
                        .cornerRadius(8)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    var statusColor: Color {
        switch telescope.connectionStatus {
        case .connected: return .green
        case .connecting, .searching: return .yellow
        case .failed: return .red
        case .disconnected: return .gray
        }
    }
}

struct TelescopeInfoCard: View {
    @ObservedObject var telescope: TelescopeConnection
    
    var body: some View {
        if let connected = telescope.connectedTelescope {
            VStack(alignment: .leading, spacing: 12) {
                Text(connected.info.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                HStack {
                    Label("Firmware: \(connected.firmware)", systemImage: "cpu")
                    Spacer()
                    if let battery = connected.batteryLevel {
                        Label("\(battery)%", systemImage: "battery.75")
                    }
                }
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
                
                Text("Hizalama: \(telescope.alignmentStatus.description)")
                    .font(.caption)
                    .foregroundColor(.cyan)
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(12)
        }
    }
}

struct PositionDisplayCard: View {
    let position: TelescopePosition
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Mevcut Konum")
                .font(.headline)
                .foregroundColor(.white)
            
            HStack(spacing: 20) {
                VStack {
                    Text("RA")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.4f°", position.rightAscension))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                }
                
                VStack {
                    Text("DEC")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.4f°", position.declination))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.cyan)
                }
                
                VStack {
                    Text("ALT")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.1f°", position.altitude))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
                
                VStack {
                    Text("AZ")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                    Text(String(format: "%.1f°", position.azimuth))
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct ControlPanel: View {
    @ObservedObject var telescope: TelescopeConnection
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Kontrol")
                .font(.headline)
                .foregroundColor(.white)
            
            // Directional controls
            VStack(spacing: 12) {
                Button {
                    telescope.moveDirection(.north, speed: 0.5)
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                }
                
                HStack(spacing: 50) {
                    Button {
                        telescope.moveDirection(.west, speed: 0.5)
                    } label: {
                        Image(systemName: "arrow.left.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.cyan)
                    }
                    
                    Button {
                        telescope.stopMovement()
                    } label: {
                        Image(systemName: "stop.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.red)
                    }
                    
                    Button {
                        telescope.moveDirection(.east, speed: 0.5)
                    } label: {
                        Image(systemName: "arrow.right.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.cyan)
                    }
                }
                
                Button {
                    telescope.moveDirection(.south, speed: 0.5)
                } label: {
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.cyan)
                }
            }
            
            Divider()
                .background(Color.white.opacity(0.3))
            
            // Action buttons
            HStack(spacing: 12) {
                Button {
                    if telescope.isTracking {
                        telescope.stopTracking()
                    } else {
                        telescope.startTracking()
                    }
                } label: {
                    Label(telescope.isTracking ? "Durdur" : "Takip Et", systemImage: telescope.isTracking ? "pause.circle" : "play.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(telescope.isTracking ? Color.orange.opacity(0.3) : Color.green.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                Button {
                    telescope.park()
                } label: {
                    Label("Park", systemImage: "house.circle")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
}

struct QuickTargetsSection: View {
    @ObservedObject var telescope: TelescopeConnection
    
    let quickTargets = [
        ("Sirius", 6.75, -16.72),
        ("Betelgeuse", 5.92, 7.41),
        ("Polaris", 2.53, 89.26),
        ("M31 Andromeda", 0.71, 41.27)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Hızlı Hedefler")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal)
            
            ForEach(quickTargets, id: \.0) { target in
                Button {
                    telescope.gotoCoordinates(ra: target.1, dec: target.2)
                } label: {
                    HStack {
                        Text(target.0)
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "arrow.right.circle")
                            .foregroundColor(.cyan)
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .cornerRadius(12)
                }
            }
            .padding(.horizontal)
        }
    }
}

struct TelescopeDiscoveryView: View {
    @StateObject private var telescope = TelescopeConnection.shared
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                SpaceBackgroundView()
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(telescope.availableTelescopes) { discovered in
                            Button {
                                telescope.connect(to: discovered)
                                dismiss()
                            } label: {
                                HStack {
                                    Image(systemName: "scope")
                                        .font(.title2)
                                        .foregroundColor(.cyan)
                                    
                                    VStack(alignment: .leading) {
                                        Text(discovered.name)
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text(connectionTypeString(discovered.connectionType))
                                            .font(.caption)
                                            .foregroundColor(.white.opacity(0.6))
                                    }
                                    
                                    Spacer()
                                    
                                    // Signal strength
                                    Image(systemName: signalIcon(discovered.signalStrength))
                                        .foregroundColor(signalColor(discovered.signalStrength))
                                }
                                .padding()
                                .background(.ultraThinMaterial)
                                .cornerRadius(12)
                            }
                        }
                        
                        if telescope.availableTelescopes.isEmpty {
                            Text("Teleskop bulunamadı")
                                .foregroundColor(.white.opacity(0.6))
                                .padding()
                        }
                    }
                    .padding()
                }
            }
            .navigationTitle("Teleskop Ara")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kapat") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                telescope.startDiscovery()
            }
            .onDisappear {
                telescope.stopDiscovery()
            }
        }
    }
    
    func signalIcon(_ strength: Int) -> String {
        if strength > -50 { return "wifi" }
        if strength > -70 { return "wifi.exclamationmark" }
        return "wifi.slash"
    }
    
    func signalColor(_ strength: Int) -> Color {
        if strength > -50 { return .green }
        if strength > -70 { return .yellow }
        return .red
    }
    
    func connectionTypeString(_ type: DiscoveredTelescope.ConnectionType) -> String {
        switch type {
        case .bluetooth: return "Bluetooth"
        case .wifi: return "WiFi"
        case .network: return "Network"
        case .serial: return "Serial"
        }
    }
}

#Preview {
    TelescopeControlView()
}
