import AuthenticationServices
import Foundation
import SwiftUI

/// Sign in with Apple identity (iCloud/CloudKit handles the actual expense sync).
@MainActor
final class CloudAccountStore: ObservableObject {
    @Published private(set) var userID: String?
    @Published private(set) var displayName: String?
    @Published private(set) var email: String?
    @Published var lastError: String?

    var isSignedIn: Bool { userID != nil && !(userID?.isEmpty ?? true) }

    private static let userKey = "masarify.appleUserId"
    private static let nameKey = "masarify.appleDisplayName"
    private static let emailKey = "masarify.appleEmail"

    init() {
        userID = UserDefaults.standard.string(forKey: Self.userKey)
        displayName = UserDefaults.standard.string(forKey: Self.nameKey)
        email = UserDefaults.standard.string(forKey: Self.emailKey)
    }

    func handleAuthorization(_ result: Result<ASAuthorization, Error>) {
        switch result {
        case .success(let auth):
            guard let credential = auth.credential as? ASAuthorizationAppleIDCredential else {
                lastError = "badCredential"
                return
            }
            let id = credential.user
            userID = id
            UserDefaults.standard.set(id, forKey: Self.userKey)

            if let fullName = credential.fullName {
                let formatted = PersonNameComponentsFormatter().string(from: fullName)
                    .trimmingCharacters(in: .whitespacesAndNewlines)
                if !formatted.isEmpty {
                    displayName = formatted
                    UserDefaults.standard.set(formatted, forKey: Self.nameKey)
                }
            }
            if let mail = credential.email, !mail.isEmpty {
                email = mail
                UserDefaults.standard.set(mail, forKey: Self.emailKey)
            }
            lastError = nil
        case .failure(let error):
            // User cancel is not a hard failure to surface loudly.
            let ns = error as NSError
            if ns.code == ASAuthorizationError.canceled.rawValue {
                lastError = nil
            } else {
                lastError = error.localizedDescription
            }
        }
    }

    func signOut() {
        userID = nil
        displayName = nil
        email = nil
        UserDefaults.standard.removeObject(forKey: Self.userKey)
        UserDefaults.standard.removeObject(forKey: Self.nameKey)
        UserDefaults.standard.removeObject(forKey: Self.emailKey)
    }

    /// Re-check Apple credential state when returning to the app.
    func refreshCredentialState() {
        guard let userID else { return }
        let provider = ASAuthorizationAppleIDProvider()
        provider.getCredentialState(forUserID: userID) { [weak self] state, _ in
            Task { @MainActor in
                switch state {
                case .revoked, .notFound:
                    self?.signOut()
                default:
                    break
                }
            }
        }
    }
}

/// Tiny bridge so `SignInWithAppleButton` works cleanly in SwiftUI.
struct AppleSignInButton: View {
    var onCompletion: (Result<ASAuthorization, Error>) -> Void
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        SignInWithAppleButton(.signIn) { request in
            request.requestedScopes = [.fullName, .email]
        } onCompletion: { result in
            onCompletion(result)
        }
        .signInWithAppleButtonStyle(colorScheme == .dark ? .white : .black)
        .frame(height: 48)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
