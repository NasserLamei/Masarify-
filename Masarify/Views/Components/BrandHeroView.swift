import SwiftUI

struct BrandHeroView: View {
    @State private var appeared = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("مصاريفي")
                .font(AppFont.brand(46))
                .foregroundStyle(BrandTheme.ink)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 12)

            Text("Masarify")
                .font(AppFont.custom(.medium, size: 20))
                .foregroundStyle(BrandTheme.deepTeal)
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 8)

            Text("تتبّع مصاريفك بالصوت والكاميرا — عربي أولاً.")
                .font(AppFont.body())
                .foregroundStyle(BrandTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
                .opacity(appeared ? 1 : 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background(
            ZStack {
                BrandTheme.heroGradient
                Circle()
                    .fill(BrandTheme.azure.opacity(0.18))
                    .frame(width: 220, height: 220)
                    .offset(x: -90, y: -40)
                    .blur(radius: 10)
                Circle()
                    .fill(BrandTheme.deepTeal.opacity(0.14))
                    .frame(width: 180, height: 180)
                    .offset(x: 120, y: 50)
                    .blur(radius: 8)
            }
        )
        .clipShape(RoundedRectangle(cornerRadius: 28, style: .continuous))
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.82)) {
                appeared = true
            }
        }
    }
}
