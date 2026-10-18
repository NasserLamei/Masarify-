import Foundation
import AVFoundation
import Combine

/// Speaks financial-coach tips aloud (TTS). Toggle-gated via AppSettings.
@MainActor
final class CoachSpeechService: NSObject, ObservableObject {
    static let shared = CoachSpeechService()

    @Published private(set) var isSpeaking = false

    private let synthesizer = AVSpeechSynthesizer()

    override init() {
        super.init()
        synthesizer.delegate = self
    }

    func speak(title: String, message: String, language: AppLanguage, enabled: Bool) {
        guard enabled else { return }
        let text = [title, message]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .joined(separator: ". ")
        speak(text, language: language, enabled: enabled)
    }

    func speak(_ text: String, language: AppLanguage, enabled: Bool) {
        guard enabled else { return }
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        stop()

        // Soften interruption with other audio (voice expense entry).
        try? AVAudioSession.sharedInstance().setCategory(.playback, mode: .spokenAudio, options: [.duckOthers])
        try? AVAudioSession.sharedInstance().setActive(true)

        let utterance = AVSpeechUtterance(string: trimmed)
        utterance.voice = preferredVoice(for: language)
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.92
        utterance.pitchMultiplier = 1.05
        utterance.preUtteranceDelay = 0.05
        utterance.postUtteranceDelay = 0.1

        isSpeaking = true
        synthesizer.speak(utterance)
    }

    func stop() {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
        isSpeaking = false
    }

    private func preferredVoice(for language: AppLanguage) -> AVSpeechSynthesisVoice? {
        let preferredIds: [String]
        switch language {
        case .arabic:
            preferredIds = ["ar-EG", "ar-SA", "ar"]
        case .english:
            preferredIds = ["en-US", "en-GB", "en"]
        }
        for id in preferredIds {
            if let voice = AVSpeechSynthesisVoice(language: id) { return voice }
        }
        return AVSpeechSynthesisVoice(language: language == .arabic ? "ar-SA" : "en-US")
    }
}

extension CoachSpeechService: AVSpeechSynthesizerDelegate {
    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didFinish utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }

    nonisolated func speechSynthesizer(_ synthesizer: AVSpeechSynthesizer, didCancel utterance: AVSpeechUtterance) {
        Task { @MainActor in
            self.isSpeaking = false
        }
    }
}
