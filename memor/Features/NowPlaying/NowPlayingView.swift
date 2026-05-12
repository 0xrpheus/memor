import SwiftUI

struct NowPlayingView: View {
    @EnvironmentObject private var monitor: NowPlayingMonitor
    @EnvironmentObject private var queue: ScrobbleQueue

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ArtworkView(image: monitor.currentArtwork)
                        .padding(.bottom, 20)

                    TrackInfoView(track: monitor.currentTrack)
                        .padding(.bottom, 20)

                    if let track = monitor.currentTrack,
                       track.duration.isFinite, track.duration > 0 {
                        TimelineView(.periodic(from: .now, by: 1)) { ctx in
                            ProgressSection(
                                track: track,
                                playbackTime: monitor.trackPlaybackTime(at: ctx.date),
                                scrobbleTime: monitor.scrobblePlayTime(at: ctx.date),
                                hasScrobbled: monitor.hasScrobbledCurrentTrack
                            )
                        }
                        .padding(.bottom, 24)
                    }

                    TransportView()
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 16)
            }
            .background(MemorTheme.cream)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("now playing")
                        .font(MemorTheme.serif(size: 18))
                        .foregroundStyle(MemorTheme.ink)
                }
                if !queue.pending.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Text("\(queue.pending.count) pending")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundStyle(MemorTheme.inkSoft)
                            .monospacedDigit()
                    }
                }
            }
        }
    }
}

private struct ArtworkView: View {
    let image: UIImage?
    @State private var isSpinning = true

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(MemorTheme.creamDark)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.primary.opacity(0.1), lineWidth: 0.5)
                )

            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .accessibilityLabel("Album artwork")
            } else {
                VinylPlaceholder(isSpinning: $isSpinning)
            }

            // scanline overlay
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        stops: (0..<30).map { i in
                            let frac = Double(i) / 30.0
                            let isLine = i % 2 == 0
                            return Gradient.Stop(
                                color: Color.primary.opacity(isLine ? 0.025 : 0),
                                location: frac
                            )
                        },
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .allowsHitTesting(false)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
}

private struct VinylPlaceholder: View {
    @Binding var isSpinning: Bool
    @State private var rotation: Double = 0

    var body: some View {
        ZStack {
            ForEach([130, 96, 66, 38], id: \.self) { size in
                Circle()
                    .strokeBorder(Color.primary.opacity(0.1), lineWidth: 1)
                    .frame(width: CGFloat(size), height: CGFloat(size))
            }
            Circle()
                .fill(MemorTheme.ink.opacity(0.12))
                .frame(width: 28, height: 28)
        }
        .rotationEffect(.degrees(rotation))
        .onAppear {
            withAnimation(.linear(duration: 9).repeatForever(autoreverses: false)) {
                rotation = 360
            }
        }
    }
}

private struct TrackInfoView: View {
    let track: Track?

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(track.map { AttributedString($0.title) } ?? AttributedString("Nothing Playing"))
                .font(MemorTheme.serifItalic(size: 22))
                .foregroundStyle(MemorTheme.ink)
                .lineLimit(2)

            Text(track?.artist ?? "Start playback in Apple Music")
                .font(.system(size: 15, weight: .regular))
                .foregroundStyle(MemorTheme.inkMid)

            if let album = track?.album {
                Text(album.uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .tracking(1.2)
                    .foregroundStyle(MemorTheme.inkSoft)
                    .padding(.top, 1)
            }
        }
    }
}

private struct ProgressSection: View {
    let track: Track
    let playbackTime: TimeInterval
    let scrobbleTime: TimeInterval
    let hasScrobbled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(MemorTheme.creamDeeper)
                        .frame(height: 2)

                    Capsule()
                        .fill(MemorTheme.ink)
                        .frame(width: geo.size.width * CGFloat(playbackTime / track.duration), height: 2)

                    Circle()
                        .fill(MemorTheme.ink)
                        .frame(width: 8, height: 8)
                        .offset(x: geo.size.width * CGFloat(playbackTime / track.duration) - 4)
                }
            }
            .frame(height: 8)
            .padding(.bottom, 6)

            HStack {
                Text(formatTime(playbackTime))
                Spacer()
                Text(formatTime(track.duration))
            }
            .font(.system(size: 11, weight: .regular))
            .foregroundStyle(MemorTheme.inkSoft)
            .monospacedDigit()
            .padding(.bottom, 10)

            if track.shouldEverScrobble {
                ScrobblePill(hasScrobbled: hasScrobbled, threshold: track.scrobbleThreshold)
            } else {
                Text("tracks under 30 seconds are not scrobbled")
                    .font(.system(size: 11))
                    .foregroundStyle(MemorTheme.inkSoft)
            }
        }
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded()))
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}

private struct ScrobblePill: View {
    let hasScrobbled: Bool
    let threshold: TimeInterval

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: hasScrobbled ? "checkmark" : "clock")
                .font(.system(size: 10, weight: .medium))
            Text(hasScrobbled ? "scrobbled" : "scrobbles at \(formatTime(threshold))")
                .font(.system(size: 11, weight: .medium))
                .tracking(0.3)
        }
        .foregroundStyle(hasScrobbled ? Color(red: 0.18, green: 0.48, blue: 0.23) : Color(red: 0.85, green: 0.29, blue: 0.17))
        .padding(.horizontal, 11)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(hasScrobbled
                      ? Color(red: 0.91, green: 0.96, blue: 0.91)
                      : Color(red: 0.96, green: 0.91, blue: 0.89))
        )
    }

    private func formatTime(_ t: TimeInterval) -> String {
        let s = max(0, Int(t.rounded()))
        return "\(s / 60):\(String(format: "%02d", s % 60))"
    }
}

private struct TransportView: View {
    private let player = MPMusicPlayerController.systemMusicPlayer

    @State private var isPlaying: Bool = true

    var body: some View {
        HStack(spacing: 40) {
            Button {
                player.skipToPreviousItem()
            } label: {
                Image(systemName: "backward.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(MemorTheme.inkSoft)
            }
            .buttonStyle(.plain)

            Button {
                if isPlaying { player.pause() } else { player.play() }
                isPlaying.toggle()
            } label: {
                ZStack {
                    Circle()
                        .fill(MemorTheme.ink)
                        .frame(width: 56, height: 56)
                    Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(MemorTheme.cream)
                        .offset(x: isPlaying ? 0 : 1.5)
                }
            }
            .buttonStyle(.plain)
            .animation(.easeInOut(duration: 0.15), value: isPlaying)

            Button {
                player.skipToNextItem()
            } label: {
                Image(systemName: "forward.fill")
                    .font(.system(size: 22, weight: .regular))
                    .foregroundStyle(MemorTheme.inkSoft)
            }
            .buttonStyle(.plain)
        }
        .frame(maxWidth: .infinity)
        .onAppear {
            isPlaying = player.playbackState == .playing
        }
        .onReceive(NotificationCenter.default.publisher(for: .MPMusicPlayerControllerPlaybackStateDidChange)) { _ in
            isPlaying = player.playbackState == .playing
        }
    }
}

import MediaPlayer
