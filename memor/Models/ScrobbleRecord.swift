import Foundation

struct ScrobbleRecord: Codable, Identifiable, Hashable {
    enum Status: String, Codable {
        case pending
        case submitted
        case failed
    }

    let id: UUID
    let track: Track
    let playedAt: Date
    var status: Status
    var failureMessage: String?

    init(id: UUID = UUID(), track: Track, playedAt: Date = Date(), status: Status = .pending, failureMessage: String? = nil) {
        self.id = id
        self.track = track
        self.playedAt = playedAt
        self.status = status
        self.failureMessage = failureMessage
    }
}
