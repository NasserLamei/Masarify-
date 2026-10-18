import SwiftUI

struct BiometricLockOverlay: View {
    @EnvironmentObject private var settings: AppSettings
    @ObservedObject var lock: AppLockController

    var body: some View {
        ZStack {
            BrandTheme.deepTeal.opacity(0.92)
                .ignoresSafeArea()

            LinearGradient(
                colors: [BrandTheme.seafoam.opacity(0.35), BrandTheme.deepTeal.opacity(0.2)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 28) {
                Spacer()

                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 88, height: 88)
                    .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
                    .shadow(color: .black.opacity(0.25), radius: 16, y: 8)

                Text(settings.t(.appName))
                    .font(AppFont.brand(34))
                    .foregroundStyle(.white)

                Text(settings.t(.biometricLockHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(.white.opacity(0.85))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                Button {
                    Task {
                        await lock.unlock(reason: settings.t(.biometricReason))
                    }
                } label: {
                    HStack(spacing: 10) {
                        if lock.isAuthenticating {
                            ProgressView()
                                .tint(.white)
                        } else {
                            Image(systemName: BiometricAuthService.availableKind().systemImage)
                                .font(.system(size: 22, weight: .semibold))
                        }
                        Text(settings.t(.biometricUnlock))
                            .font(AppFont.headline())
                    }
                    .foregroundStyle(BrandTheme.deepTeal)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                }
                .buttonStyle(PressableStyle())
                .padding(.horizontal, 40)
                .disabled(lock.isAuthenticating)

                if lock.statusMessage != nil {
                    Text(settings.t(.biometricFailed))
                        .font(AppFont.caption())
                        .foregroundStyle(.white.opacity(0.9))
                }

                Spacer()
                Spacer()
            }
        }
        .onAppear {
            Task {
                // Auto-prompt once when the lock screen appears.
                try? await Task.sleep(nanoseconds: 350_000_000)
                if lock.isLocked {
                    await lock.unlock(reason: settings.t(.biometricReason))
                }
            }
        }
    }
}
