import SwiftUI
import SwiftData

struct VoiceEntryView: View {
    @EnvironmentObject private var settings: AppSettings
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CategoryItem.sortOrder) private var categories: [CategoryItem]
    @StateObject private var recognizer = SpeechRecognizer()
    @State private var draft = ExpenseDraft.empty(source: .voice)
    @State private var showReview = false
    @State private var pulse = false
    @State private var typedText = ""

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text(settings.language == .arabic
                     ? "قل المبلغ والفئة والملاحظة بالعربية أو الإنجليزية."
                     : "Say the amount, category, and note in Arabic or English.")
                    .font(AppFont.subheadline())
                    .foregroundStyle(BrandTheme.muted)
                    .padding(.top, 4)

                VStack(spacing: 12) {
                    Button {
                        recognizer.toggleRecording()
                    } label: {
                        ZStack {
                            Circle()
                                .fill(BrandTheme.deepTeal.opacity(recognizer.isRecording ? 0.2 : 0.12))
                                .frame(
                                    width: pulse && recognizer.isRecording ? 140 : 120,
                                    height: pulse && recognizer.isRecording ? 140 : 120
                                )
                            Circle()
                                .fill(BrandTheme.brandGradient)
                                .frame(width: 88, height: 88)
                                .shadow(color: BrandTheme.deepTeal.opacity(0.35), radius: 16, y: 8)
                            Image(systemName: recognizer.isRecording ? "stop.fill" : "mic.fill")
                                .font(.system(size: 32, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)
                    .accessibilityLabel(recognizer.isRecording ? "إيقاف" : settings.t(.voiceCaptureA11y))

                    Text(recognizer.statusMessage)
                        .font(AppFont.subheadline())
                        .foregroundStyle(
                            recognizer.statusMessage.contains("فشل") || recognizer.statusMessage.contains("مرفوض")
                            ? BrandTheme.coral
                            : BrandTheme.muted
                        )
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .animation(Motion.gentle, value: recognizer.statusMessage)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text(settings.language == .arabic ? "أو اكتب الجملة هنا" : "Or type the phrase here")
                        .font(AppFont.caption())
                        .foregroundStyle(BrandTheme.muted)
                    TextField(
                        settings.language == .arabic
                            ? "مثال: دفعت ٥٠ جنيه أوبير"
                            : "e.g. paid 50 EGP Uber",
                        text: $typedText,
                        axis: .vertical
                    )
                    .font(AppFont.title3())
                    .foregroundStyle(BrandTheme.ink)
                    .lineLimit(2...4)
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.white.opacity(0.8))
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .disabled(recognizer.isRecording)
                    .onChange(of: typedText) { _, value in
                        guard !recognizer.isRecording else { return }
                        recognizer.transcript = value
                    }
                }

                HStack(spacing: 12) {
                    Button {
                        draft = recognizer.useMockSample(categories: categories)
                        typedText = recognizer.transcript
                        showReview = true
                    } label: {
                        Label(
                            settings.language == .arabic ? "مثال جاهز" : "Sample",
                            systemImage: "sparkles"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(BrandTheme.azure)
                    .disabled(recognizer.isRecording)

                    Button {
                        applyTranscript()
                        showReview = true
                    } label: {
                        Label(
                            settings.language == .arabic ? "مراجعة" : "Review",
                            systemImage: "checkmark.circle"
                        )
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandTheme.deepTeal)
                    .disabled(activeText.isEmpty || recognizer.isRecording)
                }
            }
            .masarifyScreenInsets()
            .padding(.vertical, 20)
        }
        .masarifyScreenBackground()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(settings.t(.cancel)) {
                    if recognizer.isRecording { recognizer.stopRecording() }
                    dismiss()
                }
            }
        }
        .sheet(isPresented: $showReview) {
            NavigationStack {
                ExpenseFormView(mode: .draft(draft))
            }
            .environmentObject(settings)
        }
        .onAppear {
            recognizer.refreshAvailability()
            recognizer.requestAccessIfNeeded()
        }
        .onChange(of: recognizer.isRecording) { _, recording in
            if recording {
                withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            } else {
                pulse = false
                syncTypedFromTranscript()
                if !recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    applyTranscript()
                }
            }
        }
        .onChange(of: recognizer.transcript) { _, value in
            guard recognizer.isRecording else { return }
            typedText = value
        }
    }

    private var activeText: String {
        let typed = typedText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !typed.isEmpty { return typed }
        return recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func syncTypedFromTranscript() {
        let text = recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if !text.isEmpty {
            typedText = recognizer.transcript
        }
    }

    private func applyTranscript() {
        let text = activeText
        guard !text.isEmpty else { return }
        recognizer.transcript = text
        draft = VoiceParser.parse(text, categories: categories)
    }
}
