import PhotosUI
import SwiftUI
import UIKit

struct ReceiptCaptureView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var pickerItem: PhotosPickerItem?
    @State private var showCamera = false
    @State private var isProcessing = false
    @State private var previewImage: UIImage?
    @State private var extract: ReceiptExtractResult?
    @State private var showReview = false
    @State private var status = "التقط صورة فاتورة أو اختر من المعرض."

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("فاتورة")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(BrandTheme.ink)

                Text("صورة → قراءة النص → مراجعة → حفظ.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(BrandTheme.muted)

                if let previewImage {
                    Image(uiImage: previewImage)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(BrandTheme.deepTeal.opacity(0.2), lineWidth: 1)
                        )
                        .transition(.opacity.combined(with: .scale(scale: 0.98)))
                } else {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(BrandTheme.mist)
                        .frame(height: 220)
                        .overlay {
                            VStack(spacing: 10) {
                                Image(systemName: "doc.text.viewfinder")
                                    .font(.system(size: 40))
                                    .foregroundStyle(BrandTheme.deepTeal)
                                Text("معاينة الفاتورة")
                                    .foregroundStyle(BrandTheme.muted)
                            }
                        }
                }

                Text(status)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(BrandTheme.muted)

                if let extract {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("نتيجة القراءة · \(extract.confidence.rawValue)")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(BrandTheme.azure)
                        ForEach(extract.rawHints, id: \.self) { hint in
                            Text("• \(hint)")
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(BrandTheme.muted)
                        }
                        if !extract.recognizedText.isEmpty {
                            Text(extract.recognizedText)
                                .font(.system(.footnote, design: .rounded))
                                .foregroundStyle(BrandTheme.ink)
                                .padding(12)
                                .background(Color.white.opacity(0.85))
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        showCamera = true
                    } label: {
                        Label("كاميرا", systemImage: "camera.fill")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandTheme.deepTeal)

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label("المعرض", systemImage: "photo.on.rectangle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(BrandTheme.azure)
                }

                Button {
                    showReview = true
                } label: {
                    Label("مراجعة وحفظ", systemImage: "checkmark.circle.fill")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(BrandTheme.azure)
                .disabled(extract == nil || isProcessing)

                if isProcessing {
                    ProgressView("جارٍ قراءة الفاتورة…")
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(colors: [BrandTheme.foam, BrandTheme.mist], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("إغلاق") { dismiss() }
            }
        }
        .onChange(of: pickerItem) { _, newValue in
            guard let newValue else { return }
            Task { await loadPickerItem(newValue) }
        }
        .fullScreenCover(isPresented: $showCamera) {
            CameraPicker { image in
                Task { await process(image: image, fileName: "camera.jpg") }
            }
            .ignoresSafeArea()
        }
        .sheet(isPresented: $showReview) {
            NavigationStack {
                if let extract {
                    ExpenseFormView(mode: .draft(extract.draft))
                }
            }
        }
    }

    private func loadPickerItem(_ item: PhotosPickerItem) async {
        do {
            if let data = try await item.loadTransferable(type: Data.self),
               let image = UIImage(data: data) {
                await process(image: image, fileName: item.itemIdentifier ?? "photo.jpg")
            }
        } catch {
            status = "تعذّر تحميل الصورة."
        }
    }

    @MainActor
    private func process(image: UIImage, fileName: String) async {
        withAnimation {
            previewImage = image
            isProcessing = true
            status = "جارٍ استخراج البيانات…"
        }
        let result = await ReceiptOCRService.extract(from: image, fileNameHint: fileName)
        withAnimation {
            extract = result
            isProcessing = false
            status = "راجع البيانات قبل الحفظ."
        }
    }
}

private struct CameraPicker: UIViewControllerRepresentable {
    var onImage: (UIImage) -> Void
    @Environment(\.dismiss) private var dismiss

    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = UIImagePickerController.isSourceTypeAvailable(.camera) ? .camera : .photoLibrary
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        init(parent: CameraPicker) { self.parent = parent }

        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }

        func imagePickerController(
            _ picker: UIImagePickerController,
            didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
        ) {
            if let image = info[.originalImage] as? UIImage {
                parent.onImage(image)
            }
            parent.dismiss()
        }
    }
}
