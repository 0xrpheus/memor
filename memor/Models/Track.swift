import Foundation
import MediaPlayer

struct Track: Codable, Hashable, Identifiable {
    let title: String
    let artist: String
    let album: String?
    let duration: TimeInterval
    let persistentID: UInt64

    var id: String { "\(persistentID)-\(title)-\(artist)-\(duration)" }
    var shouldEverScrobble: Bool { duration >= 30 }
    var scrobbleThreshold: TimeInterval { max(30, min(duration / 2, 240)) }

    init(title: String, artist: String, album: String?, duration: TimeInterval, persistentID: UInt64) {
        self.title = title
        self.artist = artist
        self.album = album
        self.duration = duration
        self.persistentID = persistentID
    }

    init?(item: MPMediaItem?) {
        guard let item,
              let title = item.title?.trimmingCharacters(in: .whitespacesAndNewlines), !title.isEmpty,
              let artist = item.artist?.trimmingCharacters(in: .whitespacesAndNewlines), !artist.isEmpty else {
            return nil
        }

        self.title = title
        self.artist = artist
        self.album = item.albumTitle?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        self.duration = item.playbackDuration
        self.persistentID = item.persistentID
    }
}

private extension String {
    var nilIfEmpty: String? { isEmpty ? nil : self }
}
