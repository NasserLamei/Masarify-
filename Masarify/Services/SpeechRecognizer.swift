import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var isAvailable = false
    @Published var statusMessage: String = "اضغط على المايك للتحدث"
    @Published var authorizationDenied = false
    @Published var prefersTypedFallback = false

    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var mockIndex = 0
    /// True while we intentionally end a session — ignore cancel callbacks as "errors".
    private var isFinishing = false

    init() {
        speechRecognizer = Self.makeRecognizer()
        prefersTypedFallback = Self.isLikelySimulator
        applyAuthorizationStatus(SFSpeechRecognizer.authorizationStatus())
    }

    private static var isLikelySimulator: Bool {
        #if targetEnvironment(simulator)
        true
        #else
        false
        #endif
    }

    private static func makeRecognizer() -> SFSpeechRecognizer? {
        for id in ["ar-EG", "ar", "en-US"] {
            if let recognizer = SFSpeechRecognizer(locale: Locale(identifier: id)) {
                return recognizer
            }
        }
        return SFSpeechRecognizer()
    }

    func refreshAvailability() {
        speechRecognizer = Self.makeRecognizer()
        applyAuthorizationStatus(SFSpeechRecognizer.authorizationStatus())
    }

    func requestAccessIfNeeded(completion: @escaping (Bool) -> Void = { _ in }) {
        let status = SFSpeechRecognizer.authorizationStatus()
        switch status {
        case .authorized:
            requestMicrophoneAccess { [weak self] micOK in
                self?.applyAuthorizationStatus(.authorized)
                completion(micOK)
            }
        case .denied, .restricted:
            applyAuthorizationStatus(status)
            completion(false)
        case .notDetermined:
            SFSpeechRecognizer.requestAuthorization { [weak self] newStatus in
                Task { @MainActor in
                    guard let self else { return }
                    if newStatus == .authorized {
                        self.requestMicrophoneAccess { micOK in
                            self.applyAuthorizationStatus(newStatus)
                            completion(micOK)
                        }
                    } else {
                        self.applyAuthorizationStatus(newStatus)
                        completion(false)
                    }
                }
            }
        @unknown default:
            applyAuthorizationStatus(status)
            completion(false)
        }
    }

    private func requestMicrophoneAccess(completion: @escaping (Bool) -> Void) {
        switch AVAudioApplication.shared.recordPermission {
        case .granted:
            completion(true)
        case .denied:
            statusMessage = "الميكروفون مرفوض — اكتب الجملة أو افتح الإعدادات"
            authorizationDenied = true
            completion(false)
        case .undetermined:
            AVAudioApplication.requestRecordPermission { [weak self] granted in
                Task { @MainActor in
                    if !granted {
                        self?.statusMessage = "الميكروفون مرفوض — اكتب الجملة بدل الصوت"
                        self?.authorizationDenied = true
                    }
                    completion(granted)
                }
            }
        @unknown default:
            completion(false)
        }
    }

    private func applyAuthorizationStatus(_ status: SFSpeechRecognizerAuthorizationStatus) {
        speechRecognizer = speechRecognizer ?? Self.makeRecognizer()
        let engineSaysAvailable = speechRecognizer?.isAvailable == true

        switch status {
        case .authorized:
            authorizationDenied = false
            isAvailable = speechRecognizer != nil
            if prefersTypedFallback {
                statusMessage = engineSaysAvailable
                    ? "جاهز — أو اكتب الجملة تحت"
                    : "المحاكي ضعيف في الصوت — اكتب الجملة أو جرّب على الآيفون"
            } else if engineSaysAvailable {
                statusMessage = "جاهز للتسجيل بالصوت"
            } else {
                statusMessage = "اضغط المايك للمحاولة — أو اكتب الجملة تحت"
            }
        case .denied, .restricted:
            authorizationDenied = true
            isAvailable = false
            statusMessage = "إذن الكلام مرفوض — اكتب الجملة أو فعّل الإذن من الإعدادات"
        case .notDetermined:
            isAvailable = false
            statusMessage = "اضغط على المايك للسماح بالتعرّف على الكلام"
        @unknown default:
            isAvailable = false
        }
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        requestAccessIfNeeded { [weak self] granted in
            guard let self else { return }
            guard granted else {
                self.statusMessage = "محتاج إذن الميكروفون والكلام — أو اكتب الجملة"
                return
            }
            self.speechRecognizer = Self.makeRecognizer()
            guard let recognizer = self.speechRecognizer else {
                self.statusMessage = "التعرّف غير مدعوم هنا — اكتب الجملة بالأسفل"
                return
            }
            do {
                try self.prepareSession(using: recognizer)
                self.isRecording = true
                self.isFinishing = false
                self.statusMessage = "جارٍ الاستماع… اضغط تاني للإيقاف"
            } catch {
                self.teardownAudio(cancelTask: true)
                self.isRecording = false
                self.statusMessage = Self.isLikelySimulator
                    ? "المحاكي مش بيسجّل كويس — اكتب الجملة تحت"
                    : "تعذّر بدء الميكروفون — اكتب الجملة أو أعِد المحاولة"
            }
        }
    }

    /// User tapped stop — end audio cleanly; do NOT cancel (cancel looks like a recognition error).
    func stopRecording() {
        guard isRecording || audioEngine.isRunning else { return }
        isFinishing = true
        isRecording = false

        recognitionRequest?.endAudio()
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }

        // Give the task a moment to deliver a final result, then finish.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) { [weak self] in
            self?.finishSession(userStopped: true)
        }
    }

    func useMockSample(categories: [CategoryItem] = []) -> ExpenseDraft {
        if isRecording { stopRecording() }
        let sample = VoiceParser.mockParse(index: mockIndex, categories: categories)
        mockIndex += 1
        transcript = sample.transcript
        statusMessage = "مثال تجريبي — راجع وعدّل قبل الحفظ"
        return sample.draft
    }

    private func prepareSession(using recognizer: SFSpeechRecognizer) throws {
        teardownAudio(cancelTask: true)
        transcript = ""
        isFinishing = false

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        request.requiresOnDeviceRecognition = false
        if #available(iOS 16.0, *) {
            request.addsPunctuation = false
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        // Prefer hardware input format; fall back to output format if invalid.
        var format = inputNode.inputFormat(forBus: 0)
        if format.sampleRate <= 0 || format.channelCount == 0 {
            format = inputNode.outputFormat(forBus: 0)
        }
        guard format.sampleRate > 0, format.channelCount > 0 else {
            throw NSError(domain: "MasarifySpeech", code: 1, userInfo: [
                NSLocalizedDescriptionKey: "No audio input format"
            ])
        }

        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = recognizer.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                self?.handleRecognition(result: result, error: error)
            }
        }
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            transcript = result.bestTranscription.formattedString
            if result.isFinal {
                finishSession(userStopped: false)
                return
            }
        }

        guard let error else { return }
        let ns = error as NSError
        // 216 / 203 = cancelled / no speech; common when ending the session.
        let benign = isFinishing
            || ns.domain == "kAFAssistantErrorDomain" && (ns.code == 216 || ns.code == 203 || ns.code == 1110)
            || ns.code == 1 && ns.domain.contains("Speech")

        if benign {
            finishSession(userStopped: true)
            return
        }

        teardownAudio(cancelTask: false)
        isRecording = false
        isFinishing = false
        if transcript.isEmpty {
            statusMessage = prefersTypedFallback
                ? "التعرّف فشل على المحاكي — اكتب الجملة تحت"
                : "مفيش شبكة أو التعرّف فشل — اكتب الجملة أو أعِد المحاولة"
        } else {
            statusMessage = "تم التقاط جزء من الكلام — راجع أو كمّل بالكتابة"
        }
    }

    private func finishSession(userStopped: Bool) {
        teardownAudio(cancelTask: false)
        isRecording = false
        isFinishing = false

        let text = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        if text.isEmpty {
            statusMessage = prefersTypedFallback
                ? "مفيش كلام — اكتب الجملة تحت أو جرّب على الآيفون"
                : (userStopped
                   ? "لم يُلتقط كلام — جرّب مرة أخرى أو اكتب الجملة"
                   : "لم يُسمع كلام واضح — اكتب الجملة تحت")
        } else {
            statusMessage = "تم التقاط الصوت — اضغط مراجعة"
        }
    }

    private func teardownAudio(cancelTask: Bool) {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionRequest = nil
        if cancelTask {
            recognitionTask?.cancel()
        }
        recognitionTask = nil
    }
}
