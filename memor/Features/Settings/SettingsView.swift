import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var queue: ScrobbleQueue

    var body: some View {
        NavigationStack {
            List {
                Section("Account") {
                    LabeledContent("Last.fm", value: authStore.username ?? "Signed out")
                    Button(role: .destructive) {
                        authStore.signOut()
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }

                Section("Stats") {
                    LabeledContent("Pending", value: queue.pending.count.formatted())
                    LabeledContent("Failed", value: queue.failed.count.formatted())
                    LabeledContent("Submitted", value: queue.submitted.count.formatted())
                }

                Section("About") {
                    Link(destination: URL(string: "https://www.last.fm/api")!) {
                        Label("Last.fm API", systemImage: "safari")
                    }
                    Link(destination: URL(string: "https://github.com")!) {
                        Label("Open Source", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
}
