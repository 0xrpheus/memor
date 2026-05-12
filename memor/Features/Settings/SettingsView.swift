import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var authStore: AuthStore
    @EnvironmentObject private var queue: ScrobbleQueue

    var body: some View {
        NavigationStack {
            List {
                Section {
                    AccountHeader(username: authStore.username)
                        .listRowBackground(MemorTheme.cream)
                        .listRowInsets(EdgeInsets(top: 12, leading: 20, bottom: 12, trailing: 20))
                        .listRowSeparator(.hidden)
                }
                
                Section {
                    StatGrid(
                        submitted: queue.submitted.count,
                        pending: queue.pending.count,
                        failed: queue.failed.count
                    )
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
                    .listRowSeparator(.hidden)
                } header: {
                    SectionHeader("stats")
                }

                Section {
                    SettingsLink(
                        icon: "arrow.up.right.square",
                        label: "Last.fm API",
                        destination: URL(string: "https://www.last.fm/api")!
                    )
                    SettingsLink(
                        icon: "chevron.left.forwardslash.chevron.right",
                        label: "Source code",
                        destination: URL(string: "https://github.com/0xrpheus/memor")!
                    )
                } header: {
                    SectionHeader("links")
                }

                Section {
                    Button(role: .destructive) {
                        authStore.signOut()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 15))
                                .frame(width: 20)
                                .foregroundStyle(MemorTheme.red)
                            Text("sign out")
                                .font(.system(size: 15))
                                .foregroundStyle(MemorTheme.red)
                        }
                        .padding(.vertical, 2)
                    }
                    .listRowBackground(MemorTheme.cream)
                } header: {
                    SectionHeader("account")
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(MemorTheme.cream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("settings")
                        .font(MemorTheme.serif(size: 18))
                        .foregroundStyle(MemorTheme.ink)
                }
            }
        }
    }
}

private struct AccountHeader: View {
    let username: String?

    private var initials: String {
        guard let u = username, !u.isEmpty else { return "?" }
        return String(u.prefix(2)).lowercased()
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(MemorTheme.ink)
                    .frame(width: 50, height: 50)
                Text(initials)
                    .font(MemorTheme.serif(size: 18))
                    .foregroundStyle(MemorTheme.cream)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(username ?? "signed out")
                    .font(MemorTheme.serif(size: 17))
                    .foregroundStyle(MemorTheme.ink)
                Text("LAST.FM · CONNECTED")
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.1)
                    .foregroundStyle(MemorTheme.inkSoft)
            }
        }
    }
}

private struct StatGrid: View {
    let submitted: Int
    let pending: Int
    let failed: Int

    var body: some View {
        HStack(spacing: 8) {
            StatCard(value: submitted, label: "submitted")
            StatCard(value: pending,   label: "pending")
            StatCard(value: failed,    label: "failed")
        }
    }
}

private struct StatCard: View {
    let value: Int
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(MemorTheme.serif(size: 26))
                .foregroundStyle(MemorTheme.ink)
                .monospacedDigit()

            Text(label.uppercased())
                .font(.system(size: 9, weight: .medium))
                .tracking(1.0)
                .foregroundStyle(MemorTheme.inkSoft)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(MemorTheme.creamDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.primary.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

private struct SettingsLink: View {
    let icon: String
    let label: String
    let destination: URL

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: 10) {
                Image(systemName: icon)
                    .font(.system(size: 15))
                    .frame(width: 20)
                    .foregroundStyle(MemorTheme.inkSoft)
                Text(label)
                    .font(.system(size: 15))
                    .foregroundStyle(MemorTheme.inkMid)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MemorTheme.inkSoft)
            }
            .padding(.vertical, 2)
        }
        .listRowBackground(MemorTheme.cream)
    }
}

private struct SectionHeader: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Text(text)
            .font(.system(size: 10, weight: .medium))
            .tracking(1.4)
            .textCase(.lowercase)
            .foregroundStyle(MemorTheme.inkSoft)
            .padding(.leading, 4)
    }
}
