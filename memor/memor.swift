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
