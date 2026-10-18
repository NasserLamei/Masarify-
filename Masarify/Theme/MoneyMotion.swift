import SwiftUI

/// Real EGP coin image used across splash + UI accents.
struct EgpCoinView: View {
    var size: CGFloat = 64

    var body: some View {
        Image("EgpCoin")
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .clipShape(Circle())
            .shadow(color: .black.opacity(0.18), radius: 6, y: 3)
    }
}

/// Egyptian banknotes / bills image (for category & add CTAs).
struct EgpBillsView: View {
    var width: CGFloat = 64
    var height: CGFloat = 44

    var body: some View {
        Image("EgpNotes")
            .resizable()
            .scaledToFill()
            .frame(width: width, height: height)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(.white.opacity(0.45), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.16), radius: 5, y: 2)
    }
}

/// Soft stylized banknote chip (100 / 200).
struct EgpNoteChip: View {
    var amount: Int
    var width: CGFloat = 120
    var rotation: Double = -12

    private var tint: Color {
        amount >= 200 ? Color(hex: 0xB8A4C8) : BrandTheme.azure
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [
                            tint.opacity(0.95),
                            BrandTheme.deepTeal.opacity(0.75),
                            Color.white.opacity(0.35)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            VStack(alignment: .leading, spacing: 4) {
                Text(amount >= 200 ? "٢٠٠" : "١٠٠")
                    .font(AppFont.custom(.extraBold, size: 22))
                    .foregroundStyle(.white)
                Text("جنيه")
                    .font(AppFont.caption())
                    .foregroundStyle(.white.opacity(0.9))
                Spacer(minLength: 0)
                Text("EGP \(amount)")
                    .font(AppFont.custom(.bold, size: 11))
                    .foregroundStyle(.white.opacity(0.85))
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .padding(10)
        }
        .frame(width: width, height: width * 0.55)
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .strokeBorder(.white.opacity(0.45), lineWidth: 1)
        )
        .rotationEffect(.degrees(rotation))
        .shadow(color: BrandTheme.deepTeal.opacity(0.2), radius: 8, y: 4)
    }
}

/// Splash animation — floating bills only (no large coin). Soft orbit around logo space.
struct SplashMoneyOrchestra: View {
    @State private var burst = false
    @State private var floatUp = false
    @State private var pulse = false

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                // Soft teal glow behind brand (center kept clear for logo)
                Circle()
                    .fill(BrandTheme.deepTeal.opacity(pulse ? 0.16 : 0.08))
                    .frame(width: 220, height: 220)
                    .blur(radius: 36)
                    .offset(y: -h * 0.12)
                    .scaleEffect(pulse ? 1.1 : 0.95)

                // Soft highlight wash
                Circle()
                    .fill(BrandTheme.highlight.opacity(pulse ? 0.18 : 0.08))
                    .frame(width: 140, height: 140)
                    .blur(radius: 30)
                    .offset(y: -h * 0.12)

                // Floating banknote chips — elegant ring around empty center
                EgpNoteChip(amount: 100, width: 118, rotation: floatUp ? -16 : -10)
                    .offset(
                        x: burst ? -w * 0.32 : 0,
                        y: burst ? -h * 0.22 + (floatUp ? -8 : 6) : 40
                    )
                    .opacity(burst ? 0.95 : 0)
                    .scaleEffect(burst ? 1 : 0.35)

                EgpNoteChip(amount: 200, width: 126, rotation: floatUp ? 14 : 8)
                    .offset(
                        x: burst ? w * 0.30 : 0,
                        y: burst ? -h * 0.06 + (floatUp ? 6 : -4) : 40
                    )
                    .opacity(burst ? 0.95 : 0)
                    .scaleEffect(burst ? 1 : 0.35)

                EgpNoteChip(amount: 100, width: 88, rotation: floatUp ? 20 : 14)
                    .offset(
                        x: burst ? w * 0.18 : 0,
                        y: burst ? -h * 0.32 + (floatUp ? -6 : 4) : 30
                    )
                    .opacity(burst ? 0.78 : 0)
                    .scaleEffect(burst ? 0.95 : 0.3)

                EgpNoteChip(amount: 200, width: 92, rotation: floatUp ? -20 : -14)
                    .offset(
                        x: burst ? -w * 0.16 : 0,
                        y: burst ? h * 0.02 + (floatUp ? 8 : -4) : 30
                    )
                    .opacity(burst ? 0.78 : 0)
                    .scaleEffect(burst ? 0.95 : 0.3)

                // Soft real bill photos at edges
                EgpBillsView(width: 96, height: 60)
                    .rotationEffect(.degrees(floatUp ? -12 : -6))
                    .offset(
                        x: burst ? -w * 0.28 : 0,
                        y: burst ? h * 0.08 + (floatUp ? 4 : -4) : 50
                    )
                    .opacity(burst ? 0.55 : 0)
                    .scaleEffect(burst ? 1 : 0.4)

                EgpBillsView(width: 88, height: 54)
                    .rotationEffect(.degrees(floatUp ? 12 : 6))
                    .offset(
                        x: burst ? w * 0.26 : 0,
                        y: burst ? -h * 0.34 + (floatUp ? -4 : 4) : 50
                    )
                    .opacity(burst ? 0.5 : 0)
                    .scaleEffect(burst ? 1 : 0.4)
            }
            .frame(width: w, height: h)
        }
        .allowsHitTesting(false)
        .onAppear {
            withAnimation(.spring(response: 0.85, dampingFraction: 0.72)) {
                burst = true
            }
            withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.35)) {
                floatUp = true
            }
            withAnimation(.easeInOut(duration: 1.6).repeatForever(autoreverses: true).delay(0.15)) {
                pulse = true
            }
        }
    }
}

/// Legacy rain (kept for optional use).
struct MoneyRainLayer: View {
    var intensity: Int = 8
    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(0..<intensity, id: \.self) { i in
                    let x = CGFloat((i * 47) % 100) / 100 * geo.size.width
                    let delay = Double(i) * 0.18
                    let size: CGFloat = i.isMultiple(of: 3) ? 54 : (i.isMultiple(of: 2) ? 42 : 34)

                    EgpCoinView(size: size)
                        .opacity(0.85)
                        .rotationEffect(.degrees(animate ? Double(i * 40) : Double(-i * 20)))
                        .offset(
                            x: x - geo.size.width * 0.4,
                            y: animate ? geo.size.height * 0.55 : -geo.size.height * 0.35
                        )
                        .animation(
                            .easeInOut(duration: 3.2 + Double(i % 3) * 0.35)
                            .repeatForever(autoreverses: false)
                            .delay(delay),
                            value: animate
                        )
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .allowsHitTesting(false)
        .onAppear { animate = true }
    }
}
