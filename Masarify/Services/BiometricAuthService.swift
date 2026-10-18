import Foundation
import LocalAuthentication

enum BiometricKind {
    case faceID
    case touchID
    case opticID
    case none

    var systemImage: String {
        switch self {
        case .faceID: return "faceid"
        case .touchID: return "touchid"
        case .opticID: return "opticid"
        case .none: return "lock.fill"
        }
    }
}

enum BiometricAuthService {
    static func availableKind() -> BiometricKind {
        let context = LAContext()
        var error: NSError?
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            return .none
        }
        switch context.biometryType {
        case .faceID: return .faceID
        case .touchID: return .touchID
        case .opticID: return .opticID
        @unknown default: return .faceID
        }
    }

    static func canUseBiometrics() -> Bool {
        availableKind() != .none
    }

    /// Prefer biometrics; fall back to device passcode if biometrics unavailable/locked out.
    static func authenticate(reason: String) async -> Bool {
        let context = LAContext()
        context.localizedCancelTitle = nil
        var error: NSError?
        let policy: LAPolicy
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            policy = .deviceOwnerAuthenticationWithBiometrics
        } else if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            policy = .deviceOwnerAuthentication
        } else {
            return false
        }

        return await withCheckedContinuation { continuation in
            context.evaluatePolicy(policy, localizedReason: reason) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}

@MainActor
final class AppLockController: ObservableObject {
    @Published var isLocked = false
    @Published var isAuthenticating = false
    @Published var statusMessage: String?

    func lockIfEnabled(_ enabled: Bool) {
        guard enabled else {
            isLocked = false
            return
        }
        isLocked = true
        statusMessage = nil
    }

    func unlock(reason: String) async {
        guard !isAuthenticating else { return }
        isAuthenticating = true
        statusMessage = nil
        let ok = await BiometricAuthService.authenticate(reason: reason)
        isAuthenticating = false
        if ok {
            isLocked = false
            statusMessage = nil
        } else {
            statusMessage = "authFailed"
        }
    }
}
