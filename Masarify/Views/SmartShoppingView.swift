import SwiftUI

struct SmartShoppingView: View {
    @EnvironmentObject private var settings: AppSettings

    private var tips: [SmartShoppingService.Tip] {
        SmartShoppingService.recentTips(language: settings.language)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text(settings.t(.shopTipsHint))
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)

                if tips.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Label(settings.t(.shopTipsEmpty), systemImage: "cart.badge.questionmark")
                            .font(AppFont.headline())
                            .foregroundStyle(BrandTheme.deepTeal)
                        Text(settings.t(.shopTipsEmptyDetail))
                            .font(AppFont.subheadline())
                            .foregroundStyle(BrandTheme.muted)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .masarifyCard(cornerRadius: 18, accent: BrandTheme.azure, fillOpacity: 0.45)
                } else {
                    ForEach(tips) { tip in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: tip.systemImage)
                                .foregroundStyle(.white)
                                .frame(width: 40, height: 40)
                                .background(BrandTheme.azure)
                                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(tip.title)
                                    .font(AppFont.headline())
                                    .foregroundStyle(BrandTheme.ink)
                                Text(tip.message)
                                    .font(AppFont.subheadline())
                                    .foregroundStyle(BrandTheme.muted)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(14)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .masarifyCard(cornerRadius: 16, accent: BrandTheme.azure, fillOpacity: 0.45)
                    }
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 16)
            .padding(.bottom, 100)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(title: settings.t(.shopTipsTitle))
    }
}
