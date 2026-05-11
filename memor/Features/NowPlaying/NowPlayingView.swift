import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject private var monitor: NowPlayingMonitor
    @EnvironmentObject private var queue: ScrobbleQueue

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                artworkView

                VStack(spacing: 8) {
                    Text(monitor.currentTrack?.title ?? "Nothing Playing")
                        .font(.title2.bold())
                        .multilineTextAlignment(.center)

                    Text(monitor.currentTrack?.artist ?? "Start playback in Apple Music")
                        .font(.headline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)

                    if let album = monitor.currentTrack?.album {
                        Text(album)
                            .font(.subheadline)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                }

                progressSection

                Spacer()
            }
            .padding()
            .navigationTitle("Now Playing")
            .toolbar {
                if !queue.pending.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Label("\(queue.pending.count)", systemImage: "arrow.up.circle.fill")
                            .labelStyle(.titleAndIcon)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var artworkView: some View {
        if let image = monitor.currentArtwork {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
                .accessibilityLabel("Album artwork")
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(.gray.opacity(0.18))
                Image(systemName: "music.note")
                    .font(.system(size: 56, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(width: 220, height: 220)
            .accessibilityLabel("Artwork placeholder")
        }
    }

    @ViewBuilder
    private var progressSection: some View {
        if let track = monitor.currentTrack, track.duration.isFinite, track.duration > 0 {
            TimelineView(.periodic(from: .now, by: 1)) { context in
                let playbackTime = monitor.trackPlaybackTime(at: context.date)
                let scrobbleTime = monitor.scrobblePlayTime(at: context.date)

                VStack(spacing: 8) {
                    ProgressView(value: playbackTime, total: track.duration)
                    HStack {
                        Text(formatTime(playbackTime))
                        Spacer()
                        Text(formatTime(track.duration))
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)

                    if track.shouldEverScrobble {
                        scrobbleStatus(scrobbleTime: scrobbleTime, threshold: track.scrobbleThreshold)
                    } else {
                        Text("Tracks under 30 seconds are skipped")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
            }
        }
    }

    @ViewBuilder
    private func scrobbleStatus(scrobbleTime: TimeInterval, threshold: TimeInterval) -> some View {
        if monitor.hasScrobbledCurrentTrack {
            Label("Scrobbled", systemImage: "checkmark.circle.fill")
                .font(.caption)
                .foregroundStyle(.green)
        } else {
            Text("Scrobbles at \(formatTime(threshold))")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func formatTime(_ interval: TimeInterval) -> String {
        let seconds = max(0, Int(interval.rounded()))
        return "\(seconds / 60):\(String(format: "%02d", seconds % 60))"
    }
}
