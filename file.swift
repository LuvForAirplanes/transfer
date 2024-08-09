import CoreBluetooth
import ExternalAccessory

class BluetoothIAPReceiver: NSObject, EAAccessoryDelegate {

    // MARK: - Properties

    private var accessory: EAAccessory?
    private var session: EASession?
    private var inputStream: InputStream?
    private var dataReceivedCallback: ((Data) -> Void)?

    // MARK: - Public Methods

    func startReceivingData(from accessory: EAAccessory, dataReceivedCallback: @escaping (Data) -> Void) {
        self.accessory = accessory
        self.dataReceivedCallback = dataReceivedCallback

        // Open a session with the accessory
        openSession()
    }

    // MARK: - Private Methods

    private func openSession() {
        guard let accessory = accessory else { return }

        // Find the protocol string for iAP communication
        let protocolString = accessory.protocolStrings.first { $0.hasPrefix("com.apple.iap") }

        if let protocolString = protocolString {
            // Create a session with the iAP protocol
            session = EASession(accessory: accessory, forProtocol: protocolString)

            if let session = session {
                // Get the input stream for reading data
                inputStream = session.inputStream

                if let inputStream = inputStream {
                    // Set the delegate for handling incoming data
                    inputStream.delegate = self
                    inputStream.schedule(in: .main, forMode: .common)
                    inputStream.open()
                }
            }
        }
    }

    private func handleReceivedData(_ data: Data) {
        dataReceivedCallback?(data)
    }
}

// MARK: - StreamDelegate

extension BluetoothIAPReceiver: StreamDelegate {
    func stream(_ aStream: Stream, handle eventCode: Stream.Event) {
        switch eventCode {
        case .hasBytesAvailable:
            readAvailableBytes(from: aStream as! InputStream)
        case .errorOccurred:
            print("Error occurred while reading from the stream.")
        default:
            break
        }
    }

    private func readAvailableBytes(from stream: InputStream) {
        let bufferSize = 1024 // Adjust as needed
        var buffer = [UInt8](repeating: 0, count: bufferSize)

        while stream.hasBytesAvailable {
            let bytesRead = stream.read(&buffer, maxLength: bufferSize)

            if bytesRead > 0 {
                let data = Data(buffer[0..<bytesRead])
                handleReceivedData(data)
            } else if bytesRead < 0 {
                print("Error occurred while reading bytes from the stream.")
                break
            }
        }
    }
}
