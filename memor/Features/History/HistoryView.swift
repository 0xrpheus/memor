import SwiftUI

struct HistoryView: View {
    @EnvironmentObject private var queue: ScrobbleQueue
    @EnvironmentObject private var authStore: AuthStore

    private var grouped: [(String, [ScrobbleRecord])] {
        let cal = Calendar.current
        let records = queue.allRecords
        var buckets: [(String, [ScrobbleRecord])] = []
        var seen: [String: Int] = [:]

        for record in records {
            let label: String
            if cal.isDateInToday(record.playedAt)     { label = "today" }
            else if cal.isDateInYesterday(record.playedAt) { label = "yesterday" }
            else {
                let f = DateFormatter()
                f.dateFormat = "EEEE, MMM d"
                label = f.string(from: record.playedAt).lowercased()
            }

            if let idx = seen[label] {
                buckets[idx].1.append(record)
            } else {
                seen[label] = buckets.count
                buckets.append((label, [record]))
            }
        }
        return buckets
    }

    var body: some View {
        NavigationStack {
            Group {
                if queue.allRecords.isEmpty {
                    emptyState
                } else {
                    List {
                        if !queue.failed.isEmpty {
                            Section {
                                ErrorBanner(count: queue.failed.count) {
                                    Task { await queue.retryFailed(sessionKey: authStore.sessionKey) }
                                }
                                .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                            }
                        }

                        ForEach(grouped, id: \.0) { label, records in
                            Section {
                                ForEach(records) { record in
                                    HistoryRow(record: record)
                                        .listRowBackground(MemorTheme.cream)
                                        .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 20))
                                }
                            } header: {
                                Text(label)
                                    .font(.system(size: 10, weight: .medium))
                                    .tracking(1.4)
                                    .textCase(.lowercase)
                                    .foregroundStyle(MemorTheme.inkSoft)
                                    .padding(.leading, 4)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                    .scrollContentBackground(.hidden)
                    .background(MemorTheme.cream)
                }
            }
            .background(MemorTheme.cream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("history")
                        .font(MemorTheme.serif(size: 18))
                        .foregroundStyle(MemorTheme.ink)
                }
                if !queue.failed.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            Task { await queue.retryFailed(sessionKey: authStore.sessionKey) }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 11, weight: .medium))
                                Text("retry")
                                    .font(.system(size: 13, weight: .medium))
                            }
                            .foregroundStyle(MemorTheme.red)
                        }
                    }
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 14) {
            Image(systemName: "clock")
                .font(.system(size: 38, weight: .light))
                .foregroundStyle(MemorTheme.inkSoft)

            Text("nothing yet")
                .font(MemorTheme.serifItalic(size: 20))
                .foregroundStyle(MemorTheme.ink)

            Text("tracks appear here once they reach\nthe scrobble threshold.")
                .font(.system(size: 13))
                .foregroundStyle(MemorTheme.inkSoft)
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

private struct HistoryRow: View {
    let record: ScrobbleRecord

    var body: some View {
        HStack(spacing: 12) {
            StatusDot(status: record.status)

            VStack(alignment: .leading, spacing: 2) {
                Text(record.track.title)
                    .font(MemorTheme.serif(size: 14))
                    .foregroundStyle(MemorTheme.ink)
                    .lineLimit(1)

                Text([record.track.artist, record.track.album].compactMap { $0 }.joined(separator: " · "))
                    .font(.system(size: 11))
                    .foregroundStyle(MemorTheme.inkSoft)
                    .lineLimit(1)

                if let msg = record.failureMessage, record.status == .failed {
                    Text(msg)
                        .font(.system(size: 10))
                        .foregroundStyle(MemorTheme.red)
                        .lineLimit(1)
                        .padding(.top, 1)
                }
            }

            Spacer(minLength: 0)

            Text(record.playedAt, format: .dateTime.hour().minute())
                .font(.system(size: 11))
                .foregroundStyle(MemorTheme.inkSoft)
                .monospacedDigit()
        }
        .padding(.vertical, 10)
    }
}

private struct StatusDot: View {
    let status: ScrobbleRecord.Status

    var color: Color {
        switch status {
        case .submitted: Color(red: 0.18, green: 0.48, blue: 0.23)
        case .pending:   Color(red: 0.91, green: 0.44, blue: 0.35)
        case .failed:    MemorTheme.red
        }
    }

    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 7, height: 7)
            .overlay(
                status == .failed
                    ? Circle().strokeBorder(MemorTheme.red.opacity(0.3), lineWidth: 2.5).frame(width: 12, height: 12)
                    : nil
            )
            .frame(width: 14, height: 14)
    }
}

private struct ErrorBanner: View {
    let count: Int
    let onRetry: () -> Void

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 14))
                .foregroundStyle(MemorTheme.red)

            VStack(alignment: .leading, spacing: 1) {
                Text("\(count) failed scrobble\(count == 1 ? "" : "s")")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(MemorTheme.ink)
                Text("network error · tap retry to requeue")
                    .font(.system(size: 11))
                    .foregroundStyle(MemorTheme.inkSoft)
            }

            Spacer()

            Button("retry", action: onRetry)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(MemorTheme.red)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(MemorTheme.creamDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
}
