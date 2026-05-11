import AuthenticationServices
import Combine
import Foundation
import UIKit

@MainActor
final class AuthViewModel: NSObject, ObservableObject {
    @Published var isSigningIn = false
    @Published var errorMessage: String?

    private let client: LastFMClient
    private let authStore: AuthStore
    private var webSession: ASWebAuthenticationSession?

    init(client: LastFMClient, authStore: AuthStore) {
        self.client = client
        self.authStore = authStore
    }

    func signIn() {
        guard !isSigningIn else { return }
        isSigningIn = true
        errorMessage = nil

        Task {
            do {
                let token = try await client.requestToken()
                let url = try client.authURL(token: token)
                try await authorize(url: url)
                let session = try await client.session(for: token)
                authStore.signIn(session: session)
            } catch {
                errorMessage = error.localizedDescription
            }
            isSigningIn = false
        }
    }

    private func authorize(url: URL) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            let session = ASWebAuthenticationSession(url: url, callbackURLScheme: nil) { _, error in
                if let authError = error as? ASWebAuthenticationSessionError,
                   authError.code == .canceledLogin {
                    continuation.resume()
                } else if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
            session.presentationContextProvider = self
            session.prefersEphemeralWebBrowserSession = false
            webSession = session
            if !session.start() {
                continuation.resume(throwing: ASWebAuthenticationSessionError(.canceledLogin))
            }
        }
    }
}

extension AuthViewModel: ASWebAuthenticationPresentationContextProviding {
    nonisolated func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        MainActor.assumeIsolated {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow } ?? ASPresentationAnchor()
        }
    }
}
