import CoreBluetooth

class BluetoothScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    private var centralManager: CBCentralManager!
    private var discoveredPeripherals: [CBPeripheral] = []

    // Callback for discovered peripherals
    var onPeripheralDiscovered: ((CBPeripheral) -> Void)? 

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }

    // Start scanning for peripherals
    func startScanning() {
        centralManager.scanForPeripherals(withServices: nil, options: nil) 
    }

    // Stop scanning
    func stopScanning() {
        centralManager.stopScan()
    }

    // CBCentralManagerDelegate methods
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            startScanning() // Start scanning when Bluetooth is powered on
        default:
            print("Central Manager state: \(central.state)")
            // Handle other states as needed (e.g., .poweredOff, .unauthorized)
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            onPeripheralDiscovered?(peripheral) 
        }
    }
}
