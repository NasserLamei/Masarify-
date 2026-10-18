import SwiftUI
import UIKit
import CoreText

/// Applies Cairo to UIKit chrome that SwiftUI does not style (tab bar, nav bar, pickers, fields).
enum AppAppearance {
    static func apply() {
        registerBundledFontsIfNeeded()
        assertFontsLoaded()
        configureNavigationBar()
        configureTabBar()
        configureBarButtons()
        configureLabels()
        configureTextInputs()
        configureSegmentedControl()
        configureButtonsAndLists()
        configureMenus()
        refreshLiveChrome()
    }

    /// Re-apply onto already-created tab/nav bars and force Cairo onto live UIKit text chrome.
    static func refreshLiveChrome() {
        let tabAppearance = makeTabBarAppearance()
        let navAppearance = makeNavigationBarAppearance()
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                apply(tabAppearance: tabAppearance, navAppearance: navAppearance, in: window)
                forceAppFonts(in: window)
            }
        }
    }

    private static func apply(
        tabAppearance: UITabBarAppearance,
        navAppearance: UINavigationBarAppearance,
        in root: UIView
    ) {
        if let tab = root as? UITabBar {
            tab.standardAppearance = tabAppearance
            tab.scrollEdgeAppearance = tabAppearance
            let font = AppFont.ui(.medium, size: 10)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            for item in tab.items ?? [] {
                item.setTitleTextAttributes(attrs, for: .normal)
                item.setTitleTextAttributes(attrs, for: .selected)
                item.setTitleTextAttributes(attrs, for: .highlighted)
                item.setTitleTextAttributes(attrs, for: .disabled)
            }
        }
        if let nav = root as? UINavigationBar {
            nav.standardAppearance = navAppearance
            nav.compactAppearance = navAppearance
            nav.scrollEdgeAppearance = navAppearance
            nav.compactScrollEdgeAppearance = navAppearance
            nav.titleTextAttributes = navAppearance.titleTextAttributes
            nav.largeTitleTextAttributes = navAppearance.largeTitleTextAttributes
            for item in nav.topItem?.leftBarButtonItems ?? [] {
                applyBarButtonFont(item)
            }
            for item in nav.topItem?.rightBarButtonItems ?? [] {
                applyBarButtonFont(item)
            }
            if let back = nav.topItem?.backBarButtonItem {
                applyBarButtonFont(back)
            }
        }
        for child in root.subviews {
            apply(tabAppearance: tabAppearance, navAppearance: navAppearance, in: child)
        }
    }

    private static func applyBarButtonFont(_ item: UIBarButtonItem) {
        let attrs: [NSAttributedString.Key: Any] = [.font: AppFont.ui(.medium, size: 17)]
        for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused] {
            item.setTitleTextAttributes(attrs, for: state)
        }
    }

    /// Walk the live view tree and replace system fonts with Cairo (Form/Picker/Menu chrome).
    private static func forceAppFonts(in root: UIView) {
        if let label = root as? UILabel {
            label.font = remapped(label.font, defaultSize: 16)
            if let attributed = label.attributedText, attributed.length > 0 {
                label.attributedText = remappedAttributed(attributed)
            }
        }
        if let button = root as? UIButton {
            let size = button.titleLabel?.font.pointSize ?? 17
            let font = AppFont.ui(.medium, size: size)
            button.titleLabel?.font = font
            for state: UIControl.State in [.normal, .highlighted, .disabled, .selected] {
                if let title = button.attributedTitle(for: state) {
                    button.setAttributedTitle(remappedAttributed(title), for: state)
                }
            }
        }
        if let field = root as? UITextField {
            let placeholderSize = field.font?.pointSize ?? 17
            let placeholderText = field.attributedPlaceholder?.string ?? field.placeholder

            // Amount fields: keep system digits for typed value, but Cairo for placeholder.
            if field is VisibleAmountTextField || field.accessibilityIdentifier == "masarify.amount.field" {
                field.textColor = .black
                if let placeholderText, !placeholderText.isEmpty {
                    field.attributedPlaceholder = AppFont.placeholderAttributed(
                        placeholderText,
                        size: max(15, placeholderSize - 2),
                        weight: .medium
                    )
                }
            } else if field.isFirstResponder {
                // Don't fight the caret while typing — still refresh placeholder font.
                field.textColor = .label
                if let placeholderText, !placeholderText.isEmpty {
                    field.attributedPlaceholder = AppFont.placeholderAttributed(
                        placeholderText,
                        size: placeholderSize,
                        weight: .medium
                    )
                }
            } else {
                field.font = remapped(field.font, defaultSize: 17)
                field.textColor = .label
                field.tintColor = UIColor(BrandTheme.deepTeal)
                if let placeholderText, !placeholderText.isEmpty {
                    field.attributedPlaceholder = AppFont.placeholderAttributed(
                        placeholderText,
                        size: field.font?.pointSize ?? 17,
                        weight: .medium
                    )
                }
            }
        }
        if let textView = root as? UITextView {
            textView.font = remapped(textView.font, defaultSize: 17)
        }
        if let segmented = root as? UISegmentedControl {
            let font = AppFont.ui(.medium, size: 13)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            for state: UIControl.State in [.normal, .selected, .highlighted, .disabled] {
                segmented.setTitleTextAttributes(attrs, for: state)
            }
        }
        for child in root.subviews {
            forceAppFonts(in: child)
        }
    }

    private static func remapped(
        _ font: UIFont?,
        defaultSize: CGFloat,
        preferMedium: Bool = false
    ) -> UIFont {
        let size = font?.pointSize ?? defaultSize
        if let font, isAppFont(font) { return font }
        let weight = preferMedium ? AppFont.Weight.medium : inferredWeight(font)
        return AppFont.ui(weight, size: size)
    }

    private static func remappedAttributed(_ attributed: NSAttributedString) -> NSAttributedString {
        let mutable = NSMutableAttributedString(attributedString: attributed)
        mutable.enumerateAttribute(.font, in: NSRange(location: 0, length: mutable.length)) { value, range, _ in
            let current = value as? UIFont
            let size = current?.pointSize ?? 16
            let weight = inferredWeight(current)
            mutable.addAttribute(.font, value: AppFont.ui(weight, size: size), range: range)
        }
        return mutable
    }

    private static func isAppFont(_ font: UIFont) -> Bool {
        let name = font.fontName.lowercased()
        let family = font.familyName.lowercased()
        return name.contains("cairo") || family.contains("cairo")
    }

    private static func inferredWeight(_ font: UIFont?) -> AppFont.Weight {
        guard let font else { return .regular }
        let traits = font.fontDescriptor.symbolicTraits
        if traits.contains(.traitBold) { return .bold }
        let name = font.fontName.lowercased()
        if name.contains("semibold") || name.contains("medium") || name.contains("demibold") {
            return .medium
        }
        if name.contains("heavy") || name.contains("black") || name.contains("extrabold") {
            return .extraBold
        }
        if name.contains("bold") { return .bold }
        return .regular
    }

    private static func assertFontsLoaded() {
        let names = ["Cairo-Regular", "Cairo-Medium", "Cairo-Bold", "Cairo-ExtraBold"]
        let loaded = names.compactMap { UIFont(name: $0, size: 16) }
        #if DEBUG
        if loaded.count < 4 {
            let families = UIFont.familyNames.filter { $0.localizedCaseInsensitiveContains("cairo") }
            print("Masarify warning: Cairo fonts not fully loaded (\(loaded.count)/4). Families: \(families)")
        } else {
            print("Masarify: Cairo fonts loaded OK")
        }
        #endif
    }

    // MARK: - Font registration

    private static func registerBundledFontsIfNeeded() {
        let fileNames = [
            "Cairo-Regular.ttf",
            "Cairo-Medium.ttf",
            "Cairo-Bold.ttf",
            "Cairo-ExtraBold.ttf"
        ]
        let bundleURLs = Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: nil)
            ?? Bundle.main.urls(forResourcesWithExtension: "ttf", subdirectory: "Fonts")
            ?? []
        for name in fileNames {
            if let url = bundleURLs.first(where: { $0.lastPathComponent == name })
                ?? Bundle.main.url(forResource: (name as NSString).deletingPathExtension, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    // MARK: - Navigation

    private static func makeNavigationBarAppearance() -> UINavigationBarAppearance {
        let ink = UIColor(BrandTheme.ink)
        let appearance = UINavigationBarAppearance()
        // Transparent so money wallpaper shows through the top bar
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        appearance.titleTextAttributes = [
            .font: AppFont.ui(.medium, size: 17),
            .foregroundColor: ink
        ]
        appearance.largeTitleTextAttributes = [
            .font: AppFont.ui(.bold, size: 34),
            .foregroundColor: ink
        ]
        let buttonFont = AppFont.ui(.medium, size: 17)
        let doneFont = AppFont.ui(.bold, size: 17)
        appearance.buttonAppearance.normal.titleTextAttributes = [.font: buttonFont]
        appearance.buttonAppearance.highlighted.titleTextAttributes = [.font: buttonFont]
        appearance.buttonAppearance.disabled.titleTextAttributes = [.font: buttonFont]
        appearance.doneButtonAppearance.normal.titleTextAttributes = [.font: doneFont]
        appearance.doneButtonAppearance.highlighted.titleTextAttributes = [.font: doneFont]
        appearance.backButtonAppearance.normal.titleTextAttributes = [.font: buttonFont]
        appearance.backButtonAppearance.highlighted.titleTextAttributes = [.font: buttonFont]
        return appearance
    }

    private static func configureNavigationBar() {
        let appearance = makeNavigationBarAppearance()
        let nav = UINavigationBar.appearance()
        nav.standardAppearance = appearance
        nav.compactAppearance = appearance
        nav.scrollEdgeAppearance = appearance
        nav.compactScrollEdgeAppearance = appearance
        nav.titleTextAttributes = appearance.titleTextAttributes
        nav.largeTitleTextAttributes = appearance.largeTitleTextAttributes
    }

    // MARK: - Tab bar

    private static func makeTabBarAppearance() -> UITabBarAppearance {
        let itemFont = AppFont.ui(.medium, size: 10)
        let selectedColor = UIColor(BrandTheme.deepTeal)
        let normalColor = UIColor(BrandTheme.muted)
        let normal: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: normalColor
        ]
        let selected: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: selectedColor
        ]

        let tabAppearance = UITabBarAppearance()
        // Solid app tab bar — no glass / blur.
        tabAppearance.configureWithOpaqueBackground()
        tabAppearance.backgroundEffect = nil
        tabAppearance.backgroundColor = UIColor(BrandTheme.surface)
        tabAppearance.shadowColor = UIColor(BrandTheme.deepTeal).withAlphaComponent(0.12)

        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = normal
        itemAppearance.normal.iconColor = normalColor
        itemAppearance.selected.titleTextAttributes = selected
        itemAppearance.selected.iconColor = selectedColor
        itemAppearance.disabled.titleTextAttributes = normal
        itemAppearance.disabled.iconColor = normalColor
        itemAppearance.focused.titleTextAttributes = selected
        itemAppearance.focused.iconColor = selectedColor

        // No selection pill / glass highlight.
        itemAppearance.normal.badgeBackgroundColor = selectedColor
        itemAppearance.selected.badgeBackgroundColor = selectedColor

        tabAppearance.stackedLayoutAppearance = itemAppearance
        tabAppearance.inlineLayoutAppearance = itemAppearance
        tabAppearance.compactInlineLayoutAppearance = itemAppearance
        return tabAppearance
    }

    private static func configureTabBar() {
        let itemFont = AppFont.ui(.medium, size: 10)
        let selectedColor = UIColor(BrandTheme.deepTeal)
        let normalColor = UIColor(BrandTheme.muted)
        let normal: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: normalColor
        ]
        let selected: [NSAttributedString.Key: Any] = [
            .font: itemFont,
            .foregroundColor: selectedColor
        ]

        let item = UITabBarItem.appearance()
        item.setTitleTextAttributes(normal, for: .normal)
        item.setTitleTextAttributes(selected, for: .selected)
        item.setTitleTextAttributes(normal, for: .highlighted)
        item.setTitleTextAttributes(normal, for: .disabled)

        let tabAppearance = makeTabBarAppearance()
        let tab = UITabBar.appearance()
        tab.standardAppearance = tabAppearance
        tab.scrollEdgeAppearance = tabAppearance
        tab.isTranslucent = false
        tab.barTintColor = UIColor(BrandTheme.surface)
        tab.backgroundColor = UIColor(BrandTheme.surface)
        tab.tintColor = selectedColor
        tab.unselectedItemTintColor = normalColor
    }

    // MARK: - Bar buttons / toolbars

    private static func configureBarButtons() {
        let attrs: [NSAttributedString.Key: Any] = [.font: AppFont.ui(.medium, size: 17)]
        let bar = UIBarButtonItem.appearance()
        for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused] {
            bar.setTitleTextAttributes(attrs, for: state)
        }
        let inNav = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UINavigationBar.self])
        for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused] {
            inNav.setTitleTextAttributes(attrs, for: state)
        }
        let inToolbar = UIBarButtonItem.appearance(whenContainedInInstancesOf: [UIToolbar.self])
        for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused] {
            inToolbar.setTitleTextAttributes(attrs, for: state)
        }
    }

    // MARK: - Labels (nav/tab/list/picker chrome)

    private static func configureLabels() {
        UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self]).font =
            AppFont.ui(.medium, size: 17)
        UILabel.appearance(whenContainedInInstancesOf: [UITabBar.self]).font =
            AppFont.ui(.medium, size: 10)
        UILabel.appearance(whenContainedInInstancesOf: [UITableViewCell.self]).font =
            AppFont.ui(.regular, size: 16)
        UILabel.appearance(whenContainedInInstancesOf: [UICollectionViewCell.self]).font =
            AppFont.ui(.regular, size: 16)
        UILabel.appearance(whenContainedInInstancesOf: [UIPickerView.self]).font =
            AppFont.ui(.regular, size: 20)
        UILabel.appearance(whenContainedInInstancesOf: [UIAlertController.self]).font =
            AppFont.ui(.regular, size: 15)
        UILabel.appearance(whenContainedInInstancesOf: [UIButton.self]).font =
            AppFont.ui(.medium, size: 17)
        UILabel.appearance(whenContainedInInstancesOf: [UISegmentedControl.self]).font =
            AppFont.ui(.medium, size: 13)
        UILabel.appearance(whenContainedInInstancesOf: [UITableViewHeaderFooterView.self]).font =
            AppFont.ui(.medium, size: 13)
    }

    // MARK: - Text fields / views

    private static func configureTextInputs() {
        let field = UITextField.appearance()
        field.font = AppFont.ui(.regular, size: 17)
        field.textColor = .label
        field.tintColor = UIColor(BrandTheme.deepTeal)
        UITextView.appearance().font = AppFont.ui(.regular, size: 17)
        UITextView.appearance().textColor = .label
        UISearchTextField.appearance().font = AppFont.ui(.regular, size: 17)
    }

    // MARK: - Segmented control

    private static func configureSegmentedControl() {
        let attrs: [NSAttributedString.Key: Any] = [.font: AppFont.ui(.medium, size: 13)]
        let segmented = UISegmentedControl.appearance()
        for state: UIControl.State in [.normal, .selected, .highlighted, .disabled] {
            segmented.setTitleTextAttributes(attrs, for: state)
        }
    }

    // MARK: - Menus

    private static func configureMenus() {
        // UIMenuController / UIEditMenu are system chrome; menu list rows use UILabel proxies above.
        if #available(iOS 15.0, *) {
            UILabel.appearance(whenContainedInInstancesOf: [UINavigationBar.self, UITableView.self]).font =
                AppFont.ui(.regular, size: 16)
        }
    }

    // MARK: - Buttons / lists

    private static func configureButtonsAndLists() {
        UITableView.appearance().sectionHeaderTopPadding = 8
        UIButton.appearance().titleLabel?.font = AppFont.ui(.medium, size: 17)
    }
}

// MARK: - SwiftUI helpers

struct MasarifyNavTitle: ViewModifier {
    let title: String
    var large: Bool = false

    func body(content: Content) -> some View {
        content
            // Keep a11y / back context, but always draw Cairo in `.principal`
            // so UIKit never flashes the system nav font.
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(large ? .large : .inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text(title)
                        .font(large ? AppFont.custom(.bold, size: 28) : AppFont.custom(.bold, size: 17))
                        .foregroundStyle(BrandTheme.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }
            }
            .onAppear {
                AppAppearance.apply()
                DispatchQueue.main.async { AppAppearance.refreshLiveChrome() }
            }
    }
}

extension View {
    func masarifyInlineTitle(_ title: String) -> some View {
        modifier(MasarifyNavTitle(title: title, large: false))
    }
}
