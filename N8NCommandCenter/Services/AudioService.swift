import Foundation
import AVFoundation
import Speech
import Combine

class AudioService: ObservableObject {
    @Published var isRecording = false
    @Published var transcript = ""
    @Published var error: Error?
    
    private var audioEngine: AVAudioEngine?
    private var speechRecognizer: SFSpeechRecognizer?
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    private let transcriptionSubject = PassthroughSubject<String, Never>()
    var transcriptionPublisher: AnyPublisher<String, Never> {
        transcriptionSubject.eraseToAnyPublisher()
    }
    
    init() {
        self.speechRecognizer = SFSpeechRecognizer(locale: Locale(identifier: "en-US"))
    }
    
    func requestPermissions() {
        SFSpeechRecognizer.requestAuthorization { authStatus in
            // Handle auth status on the main thread
        }
        
        AVAudioSession.sharedInstance().requestRecordPermission { granted in
            // Handle permission on the main thread
        }
    }
    
    func startRecording() {
        guard !isRecording else { return }
        
        audioEngine = AVAudioEngine()
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.record, mode: .measurement, options: .duckOthers)
            try audioSession.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = error
            return
        }
        
        let inputNode = audioEngine!.inputNode
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create a SFSpeechAudioBufferRecognitionRequest object")
        }
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = speechRecognizer?.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                self.transcript = result.bestTranscription.formattedString
            } else if let error = error {
                self.error = error
                self.stopRecording()
            }
        }
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine?.prepare()
        
        do {
            try audioEngine?.start()
            isRecording = true
        } catch {
            self.error = error
            stopRecording()
        }
    }
    
    func stopRecording() {
        audioEngine?.stop()
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        audioEngine?.inputNode.removeTap(onBus: 0)
        
        recognitionRequest = nil
        recognitionTask = nil
        audioEngine = nil
        
        isRecording = false
        
        if !transcript.isEmpty {
            transcriptionSubject.send(transcript)
            transcript = ""
        }
    }
} 