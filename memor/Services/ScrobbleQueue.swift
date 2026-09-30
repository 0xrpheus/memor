import BackgroundTasks
import Combine
import Foundation
import Network

@MainActor
final class ScrobbleQueue: ObservableObject {
    @Published private(set) var pending: [ScrobbleRecord] = []
    @Published private(set) var submitted: [ScrobbleRecord] = []
    @Published private(set) var failed: [ScrobbleRecord] = []

    /// Invoked when a scrobble fails because the session key is no longer valid, so the
    /// app can sign the user out and prompt re-authentication.
    var onAuthenticationError: (@MainActor () -> Void)?
    /// Supplies the current session key for retries triggered internally (connectivity
    /// restore, background task) where no caller is available to pass one.
    var sessionKeyProvider: (@MainActor () -> String?)?

    static let backgroundFlushIdentifier = "orpheuss.memor.flush"
    private let maxSubmitted = 200
    private let maxFailed = 100

    private let client: LastFMClient
    private let pendingURL: URL
    private let historyURL: URL
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    private var isFlushing = false
    private let pathMonitor = NWPathMonitor()
    private var wasReachable = true

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
        registerBackgroundFlush()
        startMonitoringConnectivity()
    }

    func enqueue(_ track: Track, startedAt: Date = Date(), sessionKey: String?) {
        guard track.shouldEverScrobble else { return }
        let record = ScrobbleRecord(track: track, playedAt: startedAt)
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
                submitted = Array(submitted.prefix(maxSubmitted))
                persistAll()
            } catch {
                if client.isAuthenticationError(error) {
                    // Session key is invalid — stop and hand off to re-authentication.
                    // The queue is cleared by the sign-out path (see reset()).
                    persistPending()
                    onAuthenticationError?()
                    return
                }

                if client.shouldKeepPendingAfterFailure(error) {
                    persistPending()
                    break
                }

                pending.removeAll { $0.id == record.id }
                var failedRecord = record
                failedRecord.status = .failed
                failedRecord.failureMessage = error.localizedDescription
                failed.insert(failedRecord, at: 0)
                failed = Array(failed.prefix(maxFailed))
                persistAll()
                break
            }
        }

        if !pending.isEmpty {
            scheduleBackgroundFlush()
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

    /// Clears all in-memory buckets and on-disk state. Called on sign-out so a subsequent
    /// account never sees the previous user's history and pending scrobbles are never
    /// flushed to a different session.
    func reset() {
        pending.removeAll()
        submitted.removeAll()
        failed.removeAll()
        try? FileManager.default.removeItem(at: pendingURL)
        try? FileManager.default.removeItem(at: historyURL)
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
        let history = Array(failed.prefix(maxFailed)) + Array(submitted.prefix(maxSubmitted))
        write(history, to: historyURL)
    }

    private func write(_ records: [ScrobbleRecord], to url: URL) {
        do {
            let data = try encoder.encode(records)
            try data.write(to: url, options: [.atomic])
        } catch {
            assertionFailure("Failed to persist scrobbles: \(error.localizedDescription)")
        }
    }

    // MARK: - Connectivity retry

    private func startMonitoringConnectivity() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            let reachable = path.status == .satisfied
            Task { @MainActor [weak self] in
                guard let self else { return }
                let cameOnline = reachable && !self.wasReachable
                self.wasReachable = reachable
                if cameOnline, !self.pending.isEmpty {
                    await self.flush(sessionKey: self.sessionKeyProvider?())
                }
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "memor.network-monitor"))
    }

    // MARK: - Background flush safety net

    private func registerBackgroundFlush() {
        BGTaskScheduler.shared.register(
            forTaskWithIdentifier: Self.backgroundFlushIdentifier,
            using: nil
        ) { [weak self] task in
            Task { @MainActor [weak self] in
                guard let self else {
                    task.setTaskCompleted(success: false)
                    return
                }
                await self.flush(sessionKey: self.sessionKeyProvider?())
                task.setTaskCompleted(success: self.pending.isEmpty)
                if !self.pending.isEmpty {
                    self.scheduleBackgroundFlush()
                }
            }
        }
    }

    func scheduleBackgroundFlush() {
        let request = BGProcessingTaskRequest(identifier: Self.backgroundFlushIdentifier)
        request.requiresNetworkConnectivity = true
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60)
        try? BGTaskScheduler.shared.submit(request)
    }
}
