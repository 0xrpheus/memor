import SwiftUI

struct LoginView: View {
    @StateObject private var viewModel: AuthViewModel

    init(client: LastFMClient, authStore: AuthStore) {
        _viewModel = StateObject(wrappedValue: AuthViewModel(client: client, authStore: authStore))
    }

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            VStack(spacing: 14) {
                Image(systemName: "music.quarternote.3")
                    .font(.system(size: 54, weight: .semibold))
                    .foregroundStyle(.red)

                Text("memor")
                    .font(.largeTitle.bold())

                Text("A native Last.fm scrobbler for Apple Music playback across the system.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            if let message = viewModel.errorMessage {
                Text(message)
                    .font(.callout)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }

            Button {
                viewModel.signIn()
            } label: {
                Label(viewModel.isSigningIn ? "Signing In" : "Sign In with Last.fm", systemImage: "person.crop.circle.badge.checkmark")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(viewModel.isSigningIn)
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
    }
}
