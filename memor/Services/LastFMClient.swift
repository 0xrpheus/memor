import CryptoKit
import Foundation

struct LastFMSession: Codable, Equatable {
    let username: String
    let key: String
}

struct LastFMConfiguration: Sendable {
    let apiKey: String
    let apiSecret: String

    static var current: LastFMConfiguration {
        LastFMConfiguration(apiKey: Secrets.lastFMApiKey, apiSecret: Secrets.lastFMApiSecret)
    }

    var isConfigured: Bool {
        !apiKey.isEmpty && !apiSecret.isEmpty && apiKey != "YOUR_KEY" && apiSecret != "YOUR_SECRET"
    }
}

final class LastFMClient: Sendable {
    enum LastFMError: LocalizedError {
        case missingCredentials
        case invalidResponse
        case apiError(String)

        var errorDescription: String? {
            switch self {
            case .missingCredentials:
                return "Add Last.fm API credentials in Resources/Secrets.swift before signing in."
            case .invalidResponse:
                return "Last.fm returned an invalid response."
            case .apiError(let message):
                return message
            }
        }
    }

    private let configuration: LastFMConfiguration
    private let session: URLSession
    private let baseURL = URL(string: "https://ws.audioscrobbler.com/2.0/")!

    init(configuration: LastFMConfiguration = .current, session: URLSession = .lastFMDefault) {
        self.configuration = configuration
        self.session = session
    }

    var authenticationURLBase: URL {
        URL(string: "https://www.last.fm/api/auth/")!
    }

    func requestToken() async throws -> String {
        let json: TokenResponse = try await post(method: "auth.getToken", params: [:], signed: true)
        return json.token
    }

    func session(for token: String) async throws -> LastFMSession {
        let response: SessionEnvelope = try await post(method: "auth.getSession", params: ["token": token], signed: true)
        return LastFMSession(username: response.session.name, key: response.session.key)
    }

    func updateNowPlaying(track: Track, sessionKey: String) async throws {
        var params = commonTrackParams(track)
        params["sk"] = sessionKey
        let _: EmptyResponse = try await post(method: "track.updateNowPlaying", params: params, signed: true)
    }

    func scrobble(record: ScrobbleRecord, sessionKey: String) async throws {
        var params = commonTrackParams(record.track)
        params["timestamp"] = String(Int(record.playedAt.timeIntervalSince1970))
        params["sk"] = sessionKey
        let _: EmptyResponse = try await post(method: "track.scrobble", params: params, signed: true)
    }

    func authURL(token: String) throws -> URL {
        guard configuration.isConfigured else { throw LastFMError.missingCredentials }
        var components = URLComponents(url: authenticationURLBase, resolvingAgainstBaseURL: false)!
        components.queryItems = [
            URLQueryItem(name: "api_key", value: configuration.apiKey),
            URLQueryItem(name: "token", value: token)
        ]
        guard let url = components.url else { throw LastFMError.invalidResponse }
        return url
    }

    func shouldKeepPendingAfterFailure(_ error: Error) -> Bool {
        if let urlError = error as? URLError {
            return urlError.isTransientConnectivityFailure
        }
        if let lastFMError = error as? LastFMError {
            switch lastFMError {
            case .apiError:
                return false
            case .missingCredentials, .invalidResponse:
                return true
            }
        }
        return true
    }

    private func commonTrackParams(_ track: Track) -> [String: String] {
        var params = [
            "artist": track.artist,
            "track": track.title,
            "duration": String(Int(track.duration.rounded()))
        ]
        if let album = track.album {
            params["album"] = album
        }
        return params
    }

    private func post<T: Decodable>(method: String, params: [String: String], signed: Bool) async throws -> T {
        guard configuration.isConfigured else { throw LastFMError.missingCredentials }

        var requestParams = params
        requestParams["method"] = method
        requestParams["api_key"] = configuration.apiKey
        requestParams["format"] = "json"
        if signed {
            requestParams["api_sig"] = signature(for: requestParams)
        }

        var request = URLRequest(url: baseURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = formBody(from: requestParams)

        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { throw LastFMError.invalidResponse }
        if !(200...299).contains(http.statusCode) {
            if let apiError = try? JSONDecoder().decode(APIError.self, from: data) {
                throw LastFMError.apiError(apiError.message)
            }
            throw LastFMError.invalidResponse
        }

        if let apiError = try? JSONDecoder().decode(APIError.self, from: data), apiError.error != nil {
            throw LastFMError.apiError(apiError.message)
        }

        if T.self == EmptyResponse.self {
            return EmptyResponse() as! T
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func signature(for params: [String: String]) -> String {
        let source = params
            .filter { $0.key != "format" }
            .sorted { $0.key < $1.key }
            .map { $0.key + $0.value }
            .joined() + configuration.apiSecret
        let digest = Insecure.MD5.hash(data: Data(source.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }

    private func formBody(from params: [String: String]) -> Data {
        params
            .map { key, value in "\(key.urlFormEncoded)=\(value.urlFormEncoded)" }
            .joined(separator: "&")
            .data(using: .utf8) ?? Data()
    }
}

private struct TokenResponse: Decodable {
    let token: String
}

private struct SessionEnvelope: Decodable {
    let session: SessionPayload
}

private struct SessionPayload: Decodable {
    let name: String
    let key: String
}

private struct APIError: Decodable {
    let error: Int?
    let message: String
}

private struct EmptyResponse: Decodable {
    init() {}
}

private extension URLSession {
    static let lastFMDefault: URLSession = {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = true
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 24 * 60 * 60
        return URLSession(configuration: configuration)
    }()
}

private extension URLError {
    var isTransientConnectivityFailure: Bool {
        switch code {
        case .notConnectedToInternet,
             .networkConnectionLost,
             .timedOut,
             .cannotFindHost,
             .cannotConnectToHost,
             .dnsLookupFailed,
             .internationalRoamingOff,
             .dataNotAllowed,
             .callIsActive:
            return true
        default:
            return false
        }
    }
}

private extension String {
    var urlFormEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .lastFMFormAllowed) ?? self
    }
}

private extension CharacterSet {
    static let lastFMFormAllowed: CharacterSet = {
        var set = CharacterSet.urlQueryAllowed
        set.remove(charactersIn: "+&=")
        return set
    }()
}
