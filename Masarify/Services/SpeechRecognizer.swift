import AVFoundation
import Foundation
import Speech

@MainActor
final class SpeechRecognizer: ObservableObject {
    @Published var transcript: String = ""
    @Published var isRecording = false
    @Published var isAvailable = false
    @Published var statusMessage: String = "اضغط للتحدث أو استخدم التجربة"
    @Published var authorizationDenied = false

    private let speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "ar-EG"))
        ?? SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    private let audioEngine = AVAudioEngine()
    private var mockIndex = 0

    init() {
        applyAuthorizationStatus(SFSpeechRecognizer.authorizationStatus())
    }

    func refreshAvailability() {
        applyAuthorizationStatus(SFSpeechRecognizer.authorizationStatus())
    }

    func requestAccessIfNeeded(completion: @escaping (Bool) -> Void = { _ in }) {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .authorized {
            applyAuthorizationStatus(status)
            completion(true)
            return
        }
        if status == .denied || status == .restricted {
            applyAuthorizationStatus(status)
            completion(false)
            return
        }
        SFSpeechRecognizer.requestAuthorization { [weak self] newStatus in
            Task { @MainActor in
                self?.applyAuthorizationStatus(newStatus)
                completion(newStatus == .authorized)
            }
        }
    }

    private func applyAuthorizationStatus(_ status: SFSpeechRecognizerAuthorizationStatus) {
        switch status {
        case .authorized:
            authorizationDenied = false
            isAvailable = speechRecognizer?.isAvailable == true
            statusMessage = isAvailable
                ? "جاهز للتسجيل بالصوت"
                : "التعرّف غير متاح — استخدم التجربة"
        case .denied, .restricted:
            authorizationDenied = true
            isAvailable = false
            statusMessage = "الإذن مرفوض — استخدم التجربة التجريبية"
        case .notDetermined:
            isAvailable = false
            statusMessage = "اضغط للتحدث أو استخدم التجربة"
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
            guard granted, self.isAvailable else {
                self.statusMessage = "التعرّف غير متاح — جرّب العرض التجريبي"
                return
            }
            do {
                try self.prepareSession()
                self.isRecording = true
                self.statusMessage = "جارٍ الاستماع…"
            } catch {
                self.isRecording = false
                self.statusMessage = "تعذّر بدء التسجيل — استخدم التجربة"
            }
        }
    }

    func stopRecording() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        recognitionRequest = nil
        recognitionTask = nil
        isRecording = false
        if transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            statusMessage = "لم يُلتقط كلام — جرّب مرة أخرى أو استخدم التجربة"
        } else {
            statusMessage = "تم التقاط الصوت — راجع الحقول"
        }
    }

    func useMockSample() -> ExpenseDraft {
        let sample = VoiceParser.mockParse(index: mockIndex)
        mockIndex += 1
        transcript = sample.transcript
        statusMessage = "تجربة تجريبية — راجع وعدّل قبل الحفظ"
        return sample.draft
    }

    private func prepareSession() throws {
        recognitionTask?.cancel()
        recognitionTask = nil

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let request = SFSpeechAudioBufferRecognitionRequest()
        request.shouldReportPartialResults = true
        if speechRecognizer?.supportsOnDeviceRecognition == true {
            request.requiresOnDeviceRecognition = false
        }
        recognitionRequest = request

        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        inputNode.removeTap(onBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { buffer, _ in
            request.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        recognitionTask = speechRecognizer?.recognitionTask(with: request) { [weak self] result, error in
            Task { @MainActor in
                guard let self else { return }
                if let result {
                    self.transcript = result.bestTranscription.formattedString
                }
                if error != nil || result?.isFinal == true {
                    self.stopRecording()
                }
            }
        }
    }
}
