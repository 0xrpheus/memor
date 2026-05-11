import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var queue: ScrobbleQueue
    @EnvironmentObject private var authStore: AuthStore

    var body: some View {
        NavigationStack {
            List {
                if queue.allRecords.isEmpty {
                    emptyState
                        .listRowSeparator(.hidden)
                } else {
                    ForEach(queue.allRecords) { record in
                        HStack(spacing: 12) {
                            Image(systemName: iconName(for: record.status))
                                .foregroundStyle(color(for: record.status))
                                .frame(width: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(record.track.title)
                                    .font(.headline)
                                Text(record.track.artist)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                if let failureMessage = record.failureMessage, record.status == .failed {
                                    Text(failureMessage)
                                        .font(.caption)
                                        .foregroundStyle(.red)
                                        .lineLimit(2)
                                }
                            }

                            Spacer()

                            Text(record.playedAt, style: .time)
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                if !queue.failed.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await queue.retryFailed(sessionKey: authStore.sessionKey) }
                        } label: {
                            Label("Retry", systemImage: "arrow.clockwise")
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "clock")
                .font(.system(size: 40, weight: .medium))
                .foregroundStyle(.secondary)
            Text("No Scrobbles")
                .font(.headline)
            Text("Tracks appear here after they reach the scrobble threshold.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 48)
    }

    private func iconName(for status: ScrobbleRecord.Status) -> String {
        switch status {
        case .pending: "arrow.up.circle"
        case .submitted: "checkmark.circle.fill"
        case .failed: "exclamationmark.circle.fill"
        }
    }

    private func color(for status: ScrobbleRecord.Status) -> Color {
        switch status {
        case .pending: .blue
        case .submitted: .green
        case .failed: .red
        }
    }
}
