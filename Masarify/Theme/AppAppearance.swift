import SwiftUI
import UIKit
import CoreText

/// Applies Tajawal to UIKit chrome that SwiftUI does not style (tab bar, nav bar, pickers, fields).
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
        refreshLiveChrome()
    }

    /// Re-apply onto already-created tab/nav bars (SwiftUI TabView creates them after first layout).
    static func refreshLiveChrome() {
        let tabAppearance = makeTabBarAppearance()
        let navAppearance = makeNavigationBarAppearance()
        for scene in UIApplication.shared.connectedScenes {
            guard let windowScene = scene as? UIWindowScene else { continue }
            for window in windowScene.windows {
                apply(tabAppearance: tabAppearance, navAppearance: navAppearance, in: window)
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
            }
        }
        if let nav = root as? UINavigationBar {
            nav.standardAppearance = navAppearance
            nav.compactAppearance = navAppearance
            nav.scrollEdgeAppearance = navAppearance
            nav.compactScrollEdgeAppearance = navAppearance
        }
        for child in root.subviews {
            apply(tabAppearance: tabAppearance, navAppearance: navAppearance, in: child)
        }
    }

    private static func assertFontsLoaded() {
        let names = ["Tajawal-Regular", "Tajawal-Medium", "Tajawal-Bold", "Tajawal-ExtraBold"]
        let loaded = names.compactMap { UIFont(name: $0, size: 16) }
        #if DEBUG
        if loaded.count < 4 {
            let families = UIFont.familyNames.filter { $0.localizedCaseInsensitiveContains("tajawal") }
            print("Masarify warning: Tajawal fonts not fully loaded (\(loaded.count)/4). Families: \(families)")
        }
        #endif
    }

    // MARK: - Font registration

    private static func registerBundledFontsIfNeeded() {
        let fileNames = [
            "Tajawal-Regular.ttf",
            "Tajawal-Medium.ttf",
            "Tajawal-Bold.ttf",
            "Tajawal-ExtraBold.ttf"
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
        appearance.configureWithDefaultBackground()
        appearance.titleTextAttributes = [
            .font: AppFont.ui(.medium, size: 17),
            .foregroundColor: ink
        ]
        appearance.largeTitleTextAttributes = [
            .font: AppFont.ui(.bold, size: 34),
            .foregroundColor: ink
        ]
        appearance.buttonAppearance.normal.titleTextAttributes = [
            .font: AppFont.ui(.medium, size: 17)
        ]
        appearance.doneButtonAppearance.normal.titleTextAttributes = [
            .font: AppFont.ui(.bold, size: 17)
        ]
        appearance.backButtonAppearance.normal.titleTextAttributes = [
            .font: AppFont.ui(.medium, size: 17)
        ]
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
        let normal: [NSAttributedString.Key: Any] = [.font: itemFont]
        let selected: [NSAttributedString.Key: Any] = [.font: itemFont]

        let tabAppearance = UITabBarAppearance()
        tabAppearance.configureWithDefaultBackground()
        let itemAppearance = UITabBarItemAppearance()
        itemAppearance.normal.titleTextAttributes = normal
        itemAppearance.selected.titleTextAttributes = selected
        itemAppearance.disabled.titleTextAttributes = normal
        itemAppearance.focused.titleTextAttributes = selected
        tabAppearance.stackedLayoutAppearance = itemAppearance
        tabAppearance.inlineLayoutAppearance = itemAppearance
        tabAppearance.compactInlineLayoutAppearance = itemAppearance
        return tabAppearance
    }

    private static func configureTabBar() {
        let itemFont = AppFont.ui(.medium, size: 10)
        let normal: [NSAttributedString.Key: Any] = [.font: itemFont]
        let selected: [NSAttributedString.Key: Any] = [.font: itemFont]

        let item = UITabBarItem.appearance()
        item.setTitleTextAttributes(normal, for: .normal)
        item.setTitleTextAttributes(selected, for: .selected)
        item.setTitleTextAttributes(normal, for: .highlighted)
        item.setTitleTextAttributes(normal, for: .disabled)

        let tabAppearance = makeTabBarAppearance()
        let tab = UITabBar.appearance()
        tab.standardAppearance = tabAppearance
        tab.scrollEdgeAppearance = tabAppearance
    }

    // MARK: - Bar buttons / toolbars

    private static func configureBarButtons() {
        let attrs: [NSAttributedString.Key: Any] = [.font: AppFont.ui(.medium, size: 17)]
        let bar = UIBarButtonItem.appearance()
        for state: UIControl.State in [.normal, .highlighted, .disabled, .selected, .focused] {
            bar.setTitleTextAttributes(attrs, for: state)
        }
    }

    // MARK: - Labels (nav/tab/list/picker chrome)

    private static func configureLabels() {
        UILabel.appearance().font = AppFont.ui(.regular, size: 16)

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
    }

    // MARK: - Text fields / views

    private static func configureTextInputs() {
        UITextField.appearance().font = AppFont.ui(.regular, size: 17)
        UITextView.appearance().font = AppFont.ui(.regular, size: 17)
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

    // MARK: - Buttons / lists

    private static func configureButtonsAndLists() {
        UITableView.appearance().sectionHeaderTopPadding = 8
    }
}
