import SwiftUI
import SwiftData
import PhotosUI
import UIKit

struct CategoriesView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @Query private var expenses: [Expense]
    @Query private var budgets: [MonthlyBudget]

    @State private var showEditor = false
    @State private var editing: CategoryItem?
    @State private var draftName = ""
    @State private var draftIcon = "tag.fill"
    @State private var draftTint = 0x0A5C5A
    @State private var draftIconData: Data? = nil
    @State private var showValidation = false
    @State private var deleteError: String?

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                Text(
                    settings.language == .arabic
                        ? "الفئات الافتراضية + اللي تضيفها بنفسك. بتظهر في المصروفات والميزانية."
                        : "Built-in categories plus ones you add. They show in expenses and budgets."
                )
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)
                    .masarifyAppear(0)

                VStack(spacing: 10) {
                    ForEach(Array(categories.enumerated()), id: \.element.id) { index, category in
                        Button {
                            beginEdit(category)
                        } label: {
                            HStack(spacing: 14) {
                                CategoryIconView(category: category, size: 48)

                                VStack(alignment: .leading, spacing: 4) {
                                    Text(settings.categoryLabel(category))
                                        .font(AppFont.headline())
                                        .foregroundStyle(BrandTheme.ink)
                                    Text(
                                        category.isBuiltIn
                                            ? (settings.language == .arabic ? "افتراضية" : "Built-in")
                                            : (settings.language == .arabic ? "مخصصة" : "Custom")
                                    )
                                        .font(AppFont.caption())
                                        .foregroundStyle(BrandTheme.muted)
                                }
                                Spacer(minLength: 8)
                                Image(systemName: "chevron.backward")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundStyle(BrandTheme.muted.opacity(0.7))
                                    .flipsForRightToLeftLayoutDirection(true)
                            }
                            .padding(.vertical, 12)
                            .padding(.horizontal, 16)
                            .background(
                                RoundedRectangle(cornerRadius: 18, style: .continuous)
                                    .fill(Color.white.opacity(0.55))
                            )
                        }
                        .buttonStyle(PressableStyle())
                        .masarifyAppear(index + 1)
                    }
                }

                Button {
                    beginCreate()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .bold))
                        Text(settings.language == .arabic ? "إضافة فئة جديدة" : "Add category")
                            .font(AppFont.headline())
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(BrandTheme.brandGradient)
                    .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                }
                .buttonStyle(PressableStyle())
                .masarifyAppear(categories.count + 2)

                if let deleteError {
                    Text(deleteError)
                        .font(AppFont.subheadline())
                        .foregroundStyle(.red)
                }
            }
            .masarifyScreenInsets()
            .padding(.top, 20)
            .padding(.bottom, 110)
        }
        .masarifyScreenBackground()
        .masarifyPushedChrome(
            title: settings.t(.categories),
            trailing: AnyView(
                ToolbarCircleButton(systemImage: "plus", action: beginCreate)
                    .accessibilityLabel(settings.language == .arabic ? "إضافة فئة" : "Add category")
            )
        )
        .onAppear {
            CategoryItem.seedDefaults(into: modelContext)
        }
        .sheet(isPresented: $showEditor) {
            CategoryEditorSheet(
                title: editing == nil
                    ? (settings.language == .arabic ? "فئة جديدة" : "New category")
                    : (settings.language == .arabic ? "تعديل الفئة" : "Edit category"),
                draftName: $draftName,
                draftIcon: $draftIcon,
                draftTint: $draftTint,
                draftIconData: $draftIconData,
                showValidation: $showValidation,
                canDelete: editing.map { !$0.isBuiltIn } ?? false,
                canChangeIcon: editing.map { !$0.isBuiltIn } ?? true,
                language: settings.language,
                onCancel: { showEditor = false },
                onSave: saveDraft,
                onDelete: deleteEditing
            )
            .environmentObject(settings)
            .environment(\.layoutDirection, settings.language.layoutDirection)
            .environment(\.font, AppFont.body())
        }
    }

    private func beginCreate() {
        editing = nil
        draftName = ""
        let preset = CategoryPalette.presets[categories.count % CategoryPalette.presets.count]
        draftIcon = preset.image
        draftTint = preset.hex
        draftIconData = nil
        showValidation = false
        deleteError = nil
        showEditor = true
    }

    private func beginEdit(_ category: CategoryItem) {
        editing = category
        draftName = category.nameAr
        draftIcon = category.systemImage
        draftTint = category.tintHex
        draftIconData = category.iconImageData
        showValidation = false
        deleteError = nil
        showEditor = true
    }

    private func saveDraft() {
        let name = draftName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            showValidation = true
            return
        }
        showValidation = false

        if let editing {
            editing.nameAr = name
            if !editing.isBuiltIn {
                editing.nameEn = name
                editing.systemImage = draftIcon
                editing.tintHex = draftTint
                editing.iconImageData = draftIconData
            }
        } else {
            let nextOrder = (categories.map(\.sortOrder).max() ?? 10) + 1
            modelContext.insert(
                CategoryItem(
                    nameAr: name,
                    nameEn: name,
                    systemImage: draftIcon,
                    iconImageData: draftIconData,
                    tintHex: draftTint,
                    isBuiltIn: false,
                    sortOrder: nextOrder,
                    keywordsCSV: name
                )
            )
        }
        try? modelContext.save()
        showEditor = false
    }

    private func deleteEditing() {
        guard let editing, !editing.isBuiltIn else { return }
        let inUseExpenses = expenses.contains { $0.categoryId == editing.id }
        let inUseBudgets = budgets.contains { $0.categoryId == editing.id }
        if inUseExpenses || inUseBudgets {
            deleteError = settings.language == .arabic
                ? "الفئة مستخدمة في مصروفات أو ميزانية. انقلها أولاً أو احذف القيود."
                : "Category is used in expenses or budgets. Move them first."
            showEditor = false
            return
        }
        modelContext.delete(editing)
        try? modelContext.save()
        showEditor = false
    }
}

private struct CategoryEditorSheet: View {
    let title: String
    @Binding var draftName: String
    @Binding var draftIcon: String
    @Binding var draftTint: Int
    @Binding var draftIconData: Data?
    @Binding var showValidation: Bool
    let canDelete: Bool
    let canChangeIcon: Bool
    let language: AppLanguage
    let onCancel: () -> Void
    let onSave: () -> Void
    let onDelete: () -> Void

    @State private var photoItem: PhotosPickerItem?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    MasarifyFormCard(header: language == .arabic ? "الاسم" : "Name") {
                        TextField(
                            language == .arabic ? "مثال: اشتراكات" : "e.g. Subscriptions",
                            text: $draftName
                        )
                            .masarifyFieldFont(16)
                            .font(AppFont.title3())
                            .foregroundStyle(BrandTheme.ink)
                    }

                    MasarifyFormCard(header: language == .arabic ? "اللون والأيقونة" : "Color & icon") {
                        VStack(alignment: .leading, spacing: 14) {
                            if canChangeIcon {
                                galleryPickerRow
                            }

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 52), spacing: 10)], spacing: 10) {
                                ForEach(Array(CategoryPalette.presets.enumerated()), id: \.offset) { _, preset in
                                    let selected = draftIconData == nil
                                        && draftTint == preset.hex
                                        && draftIcon == preset.image
                                    Button {
                                        guard canChangeIcon else { return }
                                        draftTint = preset.hex
                                        draftIcon = preset.image
                                        draftIconData = nil
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(Color(hex: UInt32(preset.hex)).opacity(0.2))
                                                .frame(width: 48, height: 48)
                                            Image(systemName: preset.image)
                                                .foregroundStyle(Color(hex: UInt32(preset.hex)))
                                            if selected {
                                                Circle()
                                                    .stroke(BrandTheme.ink, lineWidth: 2)
                                                    .frame(width: 48, height: 48)
                                            }
                                        }
                                    }
                                    .buttonStyle(.plain)
                                    .disabled(!canChangeIcon)
                                    .opacity(canChangeIcon ? 1 : 0.55)
                                }
                            }
                        }
                    }

                    if showValidation {
                        Text(language == .arabic ? "اكتب اسم الفئة." : "Enter a category name.")
                            .font(AppFont.subheadline())
                            .foregroundStyle(.red)
                    }

                    if canDelete {
                        Button(role: .destructive, action: onDelete) {
                            Text(language == .arabic ? "حذف الفئة" : "Delete category")
                                .font(AppFont.headline())
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .masarifyScreenInsets()
                .padding(.vertical, 20)
            }
            .background(Color(uiColor: .systemGroupedBackground).ignoresSafeArea())
            .masarifyInlineTitle(title)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    MasarifyToolbarButton(
                        title: language == .arabic ? "إلغاء" : "Cancel",
                        action: onCancel
                    )
                }
                ToolbarItem(placement: .confirmationAction) {
                    MasarifyToolbarButton(
                        title: language == .arabic ? "حفظ" : "Save",
                        prominent: true,
                        action: onSave
                    )
                }
            }
            .background(MasarifyChromeHost())
            .onChange(of: photoItem) { _, item in
                Task { await loadPhoto(item) }
            }
        }
    }

    private var galleryPickerRow: some View {
        HStack(spacing: 12) {
            CategoryIconView(
                systemImage: draftIcon,
                iconImageData: draftIconData,
                tint: Color(hex: UInt32(draftTint & 0xFFFFFF)),
                size: 56
            )

            VStack(alignment: .leading, spacing: 6) {
                PhotosPicker(selection: $photoItem, matching: .images, photoLibrary: .shared()) {
                    Label(
                        language == .arabic ? "اختيار من المعرض" : "Choose from gallery",
                        systemImage: "photo.on.rectangle"
                    )
                    .font(AppFont.headline())
                    .foregroundStyle(BrandTheme.deepTeal)
                }

                if draftIconData != nil {
                    Button {
                        draftIconData = nil
                        photoItem = nil
                    } label: {
                        Text(language == .arabic ? "استخدام أيقونة جاهزة" : "Use symbol icon")
                            .font(AppFont.caption())
                            .foregroundStyle(BrandTheme.muted)
                    }
                    .buttonStyle(.plain)
                } else {
                    Text(language == .arabic ? "أو اختَر أيقونة من تحت" : "Or pick a symbol below")
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.bottom, 4)
    }

    @MainActor
    private func loadPhoto(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                let squared = Self.squareCropped(image, maxSide: 256)
                draftIconData = squared.jpegData(compressionQuality: 0.82)
            }
        } catch {
            // Keep previous icon on failure.
        }
    }

    private static func squareCropped(_ image: UIImage, maxSide: CGFloat) -> UIImage {
        let size = image.size
        let side = min(size.width, size.height)
        let origin = CGPoint(x: (size.width - side) / 2, y: (size.height - side) / 2)
        let crop = CGRect(origin: origin, size: CGSize(width: side, height: side))
        guard let cg = image.cgImage?.cropping(to: crop) else { return image }
        let cropped = UIImage(cgImage: cg, scale: image.scale, orientation: image.imageOrientation)
        let target = CGSize(width: maxSide, height: maxSide)
        let renderer = UIGraphicsImageRenderer(size: target)
        return renderer.image { _ in
            cropped.draw(in: CGRect(origin: .zero, size: target))
        }
    }
}
