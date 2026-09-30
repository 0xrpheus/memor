import SwiftUI

@main
struct memorApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    @StateObject private var authStore: AuthStore
    @StateObject private var scrobbleQueue: ScrobbleQueue
    @StateObject private var nowPlayingMonitor: NowPlayingMonitor

    private let client: LastFMClient

    init() {
        let client = LastFMClient()
        let authStore = AuthStore()
        let queue = ScrobbleQueue(client: client)

        // Clear the queue on sign-out so a new account never inherits the old one's
        // history or flushes its pending scrobbles.
        authStore.onSignOut = { [weak queue] in queue?.reset() }
        // An invalid session key forces a sign-out, which returns the UI to LoginView.
        queue.onAuthenticationError = { [weak authStore] in authStore?.signOut() }
        // Lets the queue retry (connectivity restore / background task) without a caller.
        queue.sessionKeyProvider = { [weak authStore] in authStore?.sessionKey }

        _authStore = StateObject(wrappedValue: authStore)
        _scrobbleQueue = StateObject(wrappedValue: queue)
        _nowPlayingMonitor = StateObject(wrappedValue: NowPlayingMonitor(queue: queue, authStore: authStore, client: client))
        self.client = client
    }

    var body: some Scene {
        WindowGroup {
            ContentView(client: client)
                .environmentObject(authStore)
                .environmentObject(scrobbleQueue)
                .environmentObject(nowPlayingMonitor)
                .task {
                    await scrobbleQueue.flush(sessionKey: authStore.sessionKey)
                    nowPlayingMonitor.refreshFromPlayer()
                }
        }
    }
}
