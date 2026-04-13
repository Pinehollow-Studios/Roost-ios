import Foundation
import Network
import Observation

@MainActor
@Observable
final class NetworkMonitor {
    var isConnected = true

    @ObservationIgnored
    private let monitor = NWPathMonitor()

    @ObservationIgnored
    private let queue = DispatchQueue(label: "com.roostapp.ios.networkmonitor")

    @ObservationIgnored
    private var wasDisconnected = false

    init() {
        monitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                guard let self else { return }
                let connected = path.status == .satisfied
                let previouslyDisconnected = self.wasDisconnected

                self.isConnected = connected

                if connected && previouslyDisconnected {
                    self.wasDisconnected = false
                    await RealtimeManager.shared.resubscribeAll()
                }

                if !connected {
                    self.wasDisconnected = true
                }
            }
        }
        monitor.start(queue: queue)
    }

    deinit {
        monitor.cancel()
    }
}
