import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var authStore: AuthStore
    let client: LastFMClient

    var body: some View {
        Group {
            if authStore.isAuthenticated {
                MainTabView()
            } else {
                LoginView(client: client, authStore: authStore)
            }
        }
    }
}

#Preview {
    let client = LastFMClient()
    let authStore = AuthStore()
    let queue = ScrobbleQueue(client: client)
    let monitor = NowPlayingMonitor(queue: queue, authStore: authStore, client: client)
    ContentView(client: client)
        .environmentObject(authStore)
        .environmentObject(queue)
        .environmentObject(monitor)
}
