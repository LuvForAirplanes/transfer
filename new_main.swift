import CoreBluetooth
import ExternalAccessory

class BluetoothIAPManager: NSObject, EAAccessoryDelegate {

    // Callback for received data
    var onDataReceived: ((Data) -> Void)? 

    private var accessoryManager: EAAccessoryManager!
    private var connectedAccessory: EAAccessory?
    private var session: EASession?

    override init() {
        super.init()
        accessoryManager = EAAccessoryManager.shared()
        accessoryManager.registerForLocalNotifications()
        NotificationCenter.default.addObserver(self, selector: #selector(accessoryDidConnect(_:)), name: .EAAccessoryDidConnect, object: nil)
        // Start connection attempts
        attemptConnection()
    }

    // Attempt connection to AWR300 device
    private func attemptConnection() {
        if connectedAccessory == nil {
            for accessory in accessoryManager.connectedAccessories {
                if accessory.name.hasPrefix("AWR300") {
                    connectToAccessory(accessory)
                    return // Stop searching if found
                }
            }
            // Retry after a delay if not connected
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { 
                self.attemptConnection() 
            }
        }
    }

    // Connect to a specific accessory
    private func connectToAccessory(_ accessory: EAAccessory) {
        let protocolString = "com.example.iap" // Replace with your iAP protocol string

        if let session = EASession(accessory: accessory, forProtocol: protocolString) {
            self.session = session
            session.inputStream?.delegate = self
            session.inputStream?.schedule(in: .main, forMode: .common)
            session.inputStream?.open()
            connectedAccessory = accessory
        } else {
            print("Creating session failed")
            // Handle session creation failure, potentially retry
        }
    }

    // Handle accessory connection notification
    @objc func accessoryDidConnect(_ notification: Notification) {
        if let accessory = notification.userInfo?[EAAccessoryKey] as? EAAccessory,
           accessory.name.hasPrefix("AWR300") {
            connectToAccessory(accessory)
        }
    }

    // Clean up when deinitializing
    deinit {
        NotificationCenter.default.removeObserver(self)
        session?.inputStream?.close()
        session?.inputStream?.remove(from: .main, forMode: .common)
    }
}

// Conform to StreamDelegate for data reception
extension BluetoothIAPManager: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            guard let inputStream = aStream as? InputStream else { return }
            var buffer = [UInt8](repeating: 0, count: 1024) // Adjust buffer size as needed
            let bytesRead = inputStream.read(&buffer, maxLength: buffer.count)
            if bytesRead > 0 {
                let data = Data(buffer: buffer, count: bytesRead)
                onDataReceived?(data) 
            }
        case .errorOccurred:
            print("Stream error")
            // Handle stream errors, potentially reconnect
        default:
            break
        }
    }
}
