import SwiftUI

/// Tajawal-backed segmented control (avoids UISegmentedControl system font).
struct MasarifySegmentedControl<Value: Hashable>: View {
    let options: [(Value, String)]
    @Binding var selection: Value

    var body: some View {
        HStack(spacing: 4) {
            ForEach(options, id: \.0) { value, title in
                let selected = selection == value
                Button {
                    selection = value
                } label: {
                    Text(title)
                        .font(AppFont.caption(13))
                        .foregroundStyle(selected ? BrandTheme.ink : BrandTheme.muted)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 9, style: .continuous)
                                .fill(selected ? Color.white : Color.clear)
                                .shadow(color: selected ? .black.opacity(0.06) : .clear, radius: 2, y: 1)
                        )
                }
                .buttonStyle(.plain)
            }
        }
        .padding(3)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color(uiColor: .tertiarySystemFill))
        )
    }
}

/// Tajawal-backed menu picker (avoids system Menu/Picker chrome fonts).
struct MasarifyMenuPicker<Value: Hashable>: View {
    let title: String
    let options: [(Value, String)]
    @Binding var selection: Value

    private var selectedLabel: String {
        options.first(where: { $0.0 == selection })?.1 ?? ""
    }

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.body())
                .foregroundStyle(BrandTheme.ink)
            Spacer()
            Menu {
                ForEach(options, id: \.0) { value, label in
                    Button(label) { selection = value }
                }
            } label: {
                HStack(spacing: 6) {
                    Text(selectedLabel)
                        .font(AppFont.body())
                        .foregroundStyle(BrandTheme.deepTeal)
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(BrandTheme.azure)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

struct MasarifyFormCard<Content: View>: View {
    let header: String
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(header)
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)
                .textCase(nil)
            content
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
    }
}

struct MasarifyToolbarButton: View {
    let title: String
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(prominent ? AppFont.custom(.bold, size: 17) : AppFont.headline())
        }
    }
}
