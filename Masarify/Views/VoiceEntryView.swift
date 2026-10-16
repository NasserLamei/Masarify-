import SwiftUI
import SwiftData

struct VoiceEntryView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recognizer = SpeechRecognizer()
    @State private var draft = ExpenseDraft.empty(source: .voice)
    @State private var showReview = false
    @State private var pulse = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("بالصوت")
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .foregroundStyle(BrandTheme.ink)

                Text("قل المبلغ والفئة والملاحظة بالعربية أو الإنجليزية.")
                    .font(.system(.body, design: .rounded))
                    .foregroundStyle(BrandTheme.muted)

                VStack(spacing: 16) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                            pulse = true
                        }
                        recognizer.toggleRecording()
                        if !recognizer.isRecording {
                            pulse = false
                            applyTranscript()
                        }
                    } label: {
                        ZStack {
                            Circle()
                                .fill(BrandTheme.deepTeal.opacity(recognizer.isRecording ? 0.2 : 0.12))
                                .frame(width: pulse && recognizer.isRecording ? 140 : 120, height: pulse && recognizer.isRecording ? 140 : 120)
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

                    Text(recognizer.statusMessage)
                        .font(.system(.subheadline, design: .rounded))
                        .foregroundStyle(BrandTheme.muted)
                        .frame(maxWidth: .infinity)
                }
                .padding(.vertical, 8)

                if !recognizer.transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("النص")
                            .font(.system(.caption, design: .rounded).weight(.semibold))
                            .foregroundStyle(BrandTheme.muted)
                        Text(recognizer.transcript)
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(BrandTheme.ink)
                            .padding(16)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(Color.white.opacity(0.8))
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    }
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                }

                HStack(spacing: 12) {
                    Button {
                        draft = recognizer.useMockSample()
                        showReview = true
                    } label: {
                        Label("تجربة تجريبية", systemImage: "sparkles")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.bordered)
                    .tint(BrandTheme.azure)

                    Button {
                        applyTranscript()
                        showReview = true
                    } label: {
                        Label("مراجعة", systemImage: "checkmark.circle")
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(BrandTheme.deepTeal)
                    .disabled(recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(20)
        }
        .background(
            LinearGradient(colors: [BrandTheme.foam, BrandTheme.seafoam.opacity(0.5)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("إغلاق") { dismiss() }
            }
        }
        .sheet(isPresented: $showReview) {
            NavigationStack {
                ExpenseFormView(mode: .draft(draft))
            }
        }
    }

    private func applyTranscript() {
        let text = recognizer.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        draft = VoiceParser.parse(text)
    }
}
