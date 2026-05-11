import Combine
import Foundation
import MediaPlayer
import UIKit

@MainActor
final class NowPlayingMonitor: ObservableObject {
    @Published private(set) var currentTrack: Track?
    @Published private(set) var currentArtwork: UIImage?
    @Published private(set) var playbackState: MPMusicPlaybackState = .stopped
    @Published private(set) var accumulatedPlayTime: TimeInterval = 0
    @Published private(set) var hasScrobbledCurrentTrack = false

    private let player = MPMusicPlayerController.systemMusicPlayer
    private let queue: ScrobbleQueue
    private let authStore: AuthStore
    private let client: LastFMClient
    private var observers: [NSObjectProtocol] = []
    private var thresholdTimer: DispatchSourceTimer?
    private var lastResumeDate: Date?
    private var lastKnownPlaybackTime: TimeInterval = 0
    private var lastPlaybackTimeDate = Date()

    init(queue: ScrobbleQueue, authStore: AuthStore, client: LastFMClient) {
        self.queue = queue
        self.authStore = authStore
        self.client = client
        startObserving()
        refreshFromPlayer()
    }

    deinit {
        observers.forEach(NotificationCenter.default.removeObserver)
        thresholdTimer?.cancel()
    }

    func refreshFromPlayer() {
        handleNowPlayingItemChange(to: player.nowPlayingItem)
        handlePlaybackStateChange(to: player.playbackState)
        snapshotPlaybackPosition()
    }

    func scrobblePlayTime(at date: Date) -> TimeInterval {
        guard playbackState == .playing, let lastResumeDate else {
            return accumulatedPlayTime
        }
        return accumulatedPlayTime + date.timeIntervalSince(lastResumeDate)
    }

    func trackPlaybackTime(at date: Date) -> TimeInterval {
        let liveTime: TimeInterval
        if playbackState == .playing {
            liveTime = lastKnownPlaybackTime + date.timeIntervalSince(lastPlaybackTimeDate)
        } else {
            liveTime = lastKnownPlaybackTime
        }
        guard let duration = currentTrack?.duration, duration.isFinite, duration > 0 else {
            return max(0, liveTime)
        }
        return min(max(0, liveTime), duration)
    }

    private func startObserving() {
        let center = NotificationCenter.default
        observers.append(center.addObserver(forName: .MPMusicPlayerControllerNowPlayingItemDidChange, object: player, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.handleNowPlayingItemChange(to: self.player.nowPlayingItem)
            }
        })
        observers.append(center.addObserver(forName: .MPMusicPlayerControllerPlaybackStateDidChange, object: player, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.handlePlaybackStateChange(to: self.player.playbackState)
            }
        })
        observers.append(center.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] _ in
            Task { @MainActor [weak self] in self?.refreshFromPlayer() }
        })
        player.beginGeneratingPlaybackNotifications()
    }

    private func handleNowPlayingItemChange(to item: MPMediaItem?) {
        handleTrackChange(to: Track(item: item), artwork: artwork(from: item))
    }

    private func handleTrackChange(to newTrack: Track?, artwork: UIImage?) {
        finishOutgoingTrackIfNeeded()
        thresholdTimer?.cancel()
        thresholdTimer = nil
        currentTrack = newTrack
        currentArtwork = artwork
        accumulatedPlayTime = 0
        hasScrobbledCurrentTrack = false
        lastResumeDate = nil
        snapshotPlaybackPosition()

        if let newTrack, playbackState == .playing {
            resumeCurrentTrack(newTrack)
        }
    }

    private func handlePlaybackStateChange(to newState: MPMusicPlaybackState) {
        snapshotPlaybackPosition()
        guard newState != playbackState else { return }
        playbackState = newState

        switch newState {
        case .playing:
            if let currentTrack {
                resumeCurrentTrack(currentTrack)
            }
        default:
            pauseCurrentTrack()
        }
    }

    private func resumeCurrentTrack(_ track: Track) {
        guard track.shouldEverScrobble, !hasScrobbledCurrentTrack else { return }
        if lastResumeDate == nil {
            lastResumeDate = Date()
        }
        Task { [client, authStore] in
            if let sessionKey = authStore.sessionKey {
                try? await client.updateNowPlaying(track: track, sessionKey: sessionKey)
            }
        }
        scheduleThresholdTimer(for: track)
    }

    private func pauseCurrentTrack() {
        accumulatePlaybackTimeThroughNow()
        thresholdTimer?.cancel()
        thresholdTimer = nil
        lastResumeDate = nil
    }

    private func finishOutgoingTrackIfNeeded() {
        accumulatePlaybackTimeThroughNow()
        guard let currentTrack,
              !hasScrobbledCurrentTrack,
              currentTrack.shouldEverScrobble,
              accumulatedPlayTime >= currentTrack.scrobbleThreshold else {
            return
        }
        submitCurrentTrack(currentTrack)
    }

    private func scheduleThresholdTimer(for track: Track) {
        thresholdTimer?.cancel()
        let remaining = track.scrobbleThreshold - accumulatedPlayTime
        guard remaining > 0 else {
            submitCurrentTrack(track)
            return
        }

        let timer = DispatchSource.makeTimerSource(queue: .main)
        timer.schedule(deadline: .now() + remaining, leeway: .milliseconds(250))
        timer.setEventHandler { [weak self] in
            Task { @MainActor [weak self] in
                guard let self, self.currentTrack?.id == track.id, self.playbackState == .playing else { return }
                self.accumulatePlaybackTimeThroughNow()
                self.submitCurrentTrack(track)
            }
        }
        thresholdTimer = timer
        timer.resume()
    }

    private func accumulatePlaybackTimeThroughNow() {
        guard let lastResumeDate else { return }
        accumulatedPlayTime += Date().timeIntervalSince(lastResumeDate)
        self.lastResumeDate = Date()
    }

    private func submitCurrentTrack(_ track: Track) {
        guard !hasScrobbledCurrentTrack else { return }
        hasScrobbledCurrentTrack = true
        thresholdTimer?.cancel()
        thresholdTimer = nil
        queue.enqueue(track, sessionKey: authStore.sessionKey)
    }

    private func snapshotPlaybackPosition() {
        let playbackTime = player.currentPlaybackTime
        if playbackTime.isFinite, playbackTime >= 0 {
            lastKnownPlaybackTime = playbackTime
        }
        lastPlaybackTimeDate = Date()
    }

    private func artwork(from item: MPMediaItem?) -> UIImage? {
        if let image = item?.artwork?.image(at: CGSize(width: 600, height: 600)) {
            return image
        }
        if let artwork = MPNowPlayingInfoCenter.default().nowPlayingInfo?[MPMediaItemPropertyArtwork] as? MPMediaItemArtwork {
            return artwork.image(at: CGSize(width: 600, height: 600))
        }
        return nil
    }
}
