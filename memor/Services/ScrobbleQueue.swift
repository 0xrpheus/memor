import Combine
import Foundation

@MainActor
final class ScrobbleQueue: ObservableObject {
    @Published private(set) var pending: [ScrobbleRecord] = []
    @Published private(set) var submitted: [ScrobbleRecord] = []
    @Published private(set) var failed: [ScrobbleRecord] = []

    private let client: LastFMClient
    private let pendingURL: URL
    private let historyURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var isFlushing = false

    var allRecords: [ScrobbleRecord] {
        (pending + failed + submitted).sorted { $0.playedAt > $1.playedAt }
    }

    init(client: LastFMClient) {
        self.client = client
        let support = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let directory = support.appendingPathComponent("memor", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        pendingURL = directory.appendingPathComponent("pending-scrobbles.json")
        historyURL = directory.appendingPathComponent("scrobble-history.json")
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        load()
    }

    func enqueue(_ track: Track, sessionKey: String?) {
        guard track.shouldEverScrobble else { return }
        let record = ScrobbleRecord(track: track)
        pending.insert(record, at: 0)
        persistPending()
        Task { await flush(sessionKey: sessionKey) }
    }

    func flush(sessionKey: String?) async {
        guard !isFlushing, let sessionKey, !pending.isEmpty else { return }
        isFlushing = true
        defer { isFlushing = false }

        while let record = pending.last {
            do {
                try await client.scrobble(record: record, sessionKey: sessionKey)
                pending.removeLast()
                failed.removeAll { $0.id == record.id }
                var submittedRecord = record
                submittedRecord.status = .submitted
                submitted.insert(submittedRecord, at: 0)
                submitted = Array(submitted.prefix(200))
                persistAll()
            } catch {
                if client.shouldKeepPendingAfterFailure(error) {
                    persistPending()
                    break
                }

                pending.removeAll { $0.id == record.id }
                var failedRecord = record
                failedRecord.status = .failed
                failedRecord.failureMessage = error.localizedDescription
                failed.insert(failedRecord, at: 0)
                persistAll()
                break
            }
        }
    }

    func retryFailed(sessionKey: String?) async {
        guard !failed.isEmpty else { return }
        pending.append(contentsOf: failed.map { record in
            var retry = record
            retry.status = .pending
            retry.failureMessage = nil
            return retry
        })
        failed.removeAll()
        persistAll()
        await flush(sessionKey: sessionKey)
    }

    private func load() {
        pending = loadRecords(from: pendingURL).filter { $0.status == .pending }
        let history = loadRecords(from: historyURL)
        submitted = history.filter { $0.status == .submitted }
        failed = history.filter { $0.status == .failed }
    }

    private func loadRecords(from url: URL) -> [ScrobbleRecord] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? decoder.decode([ScrobbleRecord].self, from: data)) ?? []
    }

    private func persistAll() {
        persistPending()
        persistHistory()
    }

    private func persistPending() {
        write(pending, to: pendingURL)
    }

    private func persistHistory() {
        write(Array((failed + submitted).prefix(250)), to: historyURL)
    }

    private func write(_ records: [ScrobbleRecord], to url: URL) {
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            assertionFailure("Failed to persist scrobbles: \(error.localizedDescription)")
        }
    }
}
