import Observation

@MainActor
@Observable
final class WelcomeViewModel {
    var title = "Welcome"
    var connectionStatus = SupabaseConnectionStatus(
        message: "Tap the button below any time you want to re-check the Supabase connection.",
        isConnected: false
    )
    var isCheckingConnection = false

    func verifySupabaseConnection() async {
        guard !isCheckingConnection else { return }

        isCheckingConnection = true
        connectionStatus = await Task.detached(priority: .utility) {
            await SupabaseClientProvider.shared.verifyConnection()
        }.value
        isCheckingConnection = false
    }
}
