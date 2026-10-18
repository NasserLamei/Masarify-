import SwiftUI
import UIKit

/// Cairo-backed segmented control (avoids UISegmentedControl system font).
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

/// Full-width Cairo dropdown (inline expand — not a narrow system Menu popover).
struct MasarifyMenuPicker<Value: Hashable>: View {
    let title: String
    let options: [(Value, String)]
    @Binding var selection: Value
    @State private var expanded = false

    private var selectedLabel: String {
        options.first(where: { $0.0 == selection })?.1 ?? ""
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.caption())
                .foregroundStyle(BrandTheme.muted)

            Button {
                UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                withAnimation(Motion.snappy) { expanded.toggle() }
            } label: {
                HStack(spacing: 10) {
                    Text(selectedLabel.isEmpty ? "—" : selectedLabel)
                        .font(AppFont.headline())
                        .foregroundStyle(BrandTheme.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)

                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(BrandTheme.deepTeal)
                        .rotationEffect(.degrees(expanded ? 180 : 0))
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 13)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(BrandTheme.seafoam.opacity(0.35))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(BrandTheme.deepTeal.opacity(0.28), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)

            if expanded {
                VStack(spacing: 0) {
                    ForEach(Array(options.enumerated()), id: \.element.0) { index, option in
                        let value = option.0
                        let label = option.1
                        let selected = selection == value
                        Button {
                            selection = value
                            withAnimation(Motion.snappy) { expanded = false }
                        } label: {
                            HStack(spacing: 10) {
                                Text(label)
                                    .font(selected ? AppFont.headline() : AppFont.body())
                                    .foregroundStyle(selected ? BrandTheme.deepTeal : BrandTheme.ink)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                if selected {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundStyle(BrandTheme.deepTeal)
                                }
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 12)
                            .background(selected ? BrandTheme.deepTeal.opacity(0.08) : Color.clear)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < options.count - 1 {
                            Divider().opacity(0.35)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(BrandTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(BrandTheme.deepTeal.opacity(0.22), lineWidth: 1)
                )
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                .padding(BrandTheme.screenInset)
                .frame(maxWidth: .infinity, alignment: .leading)
                .masarifyCard(cornerRadius: 14, accent: BrandTheme.deepTeal, fillOpacity: 0.92)
        }
    }
}

struct MasarifyToolbarButton: View {
    let title: String
    var prominent: Bool = false
    let action: () -> Void

    var body: some View {
        MasarifyHeaderTextButton(title: title, prominent: prominent, action: action)
    }
}
