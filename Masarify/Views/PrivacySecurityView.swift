import SwiftUI

/// Face ID / Touch ID lock + iCloud sync + Sign in with Apple.
struct PrivacySecurityView: View {
    @EnvironmentObject private var settings: AppSettings
    @EnvironmentObject private var cloudAccount: CloudAccountStore
    @EnvironmentObject private var appLock: AppLockController
    @State private var appeared = false
    @State private var biometricError: String?
    @State private var showRestartHint = false

    private var biometryLabel: String {
        switch BiometricAuthService.availableKind() {
        case .faceID: return settings.t(.biometricFaceID)
        case .touchID: return settings.t(.biometricTouchID)
        case .opticID: return settings.t(.biometricFaceID)
        case .none: return settings.t(.biometricUnavailable)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text(settings.t(.privacySubtitle))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)
                    .masarifyAppear(0)

                panel(title: settings.t(.biometricLock), icon: BiometricAuthService.availableKind().systemImage) {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: biometricBinding) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(biometryLabel)
                                    .font(AppFont.headline())
                                    .foregroundStyle(BrandTheme.ink)
                                Text(settings.t(.biometricLockHint))
                                    .font(AppFont.caption())
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                        .tint(BrandTheme.deepTeal)
                        .disabled(BiometricAuthService.availableKind() == .none)

                        if let biometricError {
                            Text(biometricError)
                                .font(AppFont.caption())
                                .foregroundStyle(BrandTheme.coral)
                        }
                    }
                }
                .masarifyAppear(1)

                panel(title: settings.t(.cloudSync), icon: "icloud.fill") {
                    VStack(alignment: .leading, spacing: 12) {
                        Toggle(isOn: iCloudBinding) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(settings.t(.cloudSyncTitle))
                                    .font(AppFont.headline())
                                    .foregroundStyle(BrandTheme.ink)
                                Text(settings.t(.cloudSyncHint))
                                    .font(AppFont.caption())
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                        .tint(BrandTheme.azure)

                        Text(settings.t(.cloudSyncRequiresICloud))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)

                        if showRestartHint {
                            Text(settings.t(.cloudSyncRestart))
                                .font(AppFont.caption())
                                .foregroundStyle(BrandTheme.coral)
                        }
                    }
                }
                .masarifyAppear(2)

                panel(title: settings.t(.appleAccount), icon: "person.crop.circle.badge.checkmark") {
                    VStack(alignment: .leading, spacing: 14) {
                        Text(settings.t(.appleAccountHint))
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)

                        if cloudAccount.isSignedIn {
                            HStack(spacing: 12) {
                                Image(systemName: "checkmark.seal.fill")
                                    .foregroundStyle(BrandTheme.lagoon)
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(cloudAccount.displayName ?? settings.t(.appleSignedIn))
                                        .font(AppFont.headline())
                                        .foregroundStyle(BrandTheme.ink)
                                    if let email = cloudAccount.email {
                                        Text(email)
                                            .font(AppFont.caption())
                                            .foregroundStyle(BrandTheme.muted)
                                    }
                                }
                                Spacer()
                            }

                            Button(role: .destructive) {
                                cloudAccount.signOut()
                            } label: {
                                Text(settings.t(.appleSignOut))
                                    .font(AppFont.subheadline())
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                            }
                            .buttonStyle(.bordered)
                        } else {
                            AppleSignInButton { result in
                                cloudAccount.handleAuthorization(result)
                            }
                        }

                        if let err = cloudAccount.lastError, !err.isEmpty {
                            Text(err)
                                .font(AppFont.caption())
                                .foregroundStyle(BrandTheme.coral)
                        }
                    }
                }
                .masarifyAppear(3)
            }
            .masarifyScreenInsets()
            .padding(.vertical, 20)
            .padding(.bottom, 100)
            .opacity(appeared ? 1 : 0)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.privacyTitle))
        .onAppear {
            cloudAccount.refreshCredentialState()
            withAnimation(Motion.gentle) { appeared = true }
        }
    }

    private var biometricBinding: Binding<Bool> {
        Binding(
            get: { settings.biometricLockEnabled },
            set: { newValue in
                Task {
                    if newValue {
                        let ok = await BiometricAuthService.authenticate(reason: settings.t(.biometricEnableReason))
                        if ok {
                            settings.biometricLockEnabled = true
                            biometricError = nil
                            appLock.isLocked = false
                        } else {
                            biometricError = settings.t(.biometricFailed)
                            settings.biometricLockEnabled = false
                        }
                    } else {
                        settings.biometricLockEnabled = false
                        appLock.isLocked = false
                        biometricError = nil
                    }
                }
            }
        )
    }

    private var iCloudBinding: Binding<Bool> {
        Binding(
            get: { settings.iCloudSyncEnabled },
            set: { newValue in
                settings.iCloudSyncEnabled = newValue
                showRestartHint = true
            }
        )
    }

    private func panel<Content: View>(
        title: String,
        icon: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Label {
                Text(title)
                    .font(AppFont.title3())
                    .foregroundStyle(BrandTheme.ink)
            } icon: {
                Image(systemName: icon)
                    .foregroundStyle(BrandTheme.deepTeal)
            }

            content()
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .masarifyCard(cornerRadius: 18, accent: BrandTheme.deepTeal, fillOpacity: 0.55)
        }
    }
}
