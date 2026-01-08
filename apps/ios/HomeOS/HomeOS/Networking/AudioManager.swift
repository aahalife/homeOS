import Foundation
import AVFoundation

/// Manages audio recording and playback for voice mode
@MainActor
class AudioManager: NSObject, ObservableObject {
    static let shared = AudioManager()

    @Published var isRecording = false
    @Published var isPlaying = false
    @Published var recordingDuration: TimeInterval = 0
    @Published var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var audioPlayer: AVAudioPlayer?
    private var levelTimer: Timer?
    private var durationTimer: Timer?

    var recordingURL: URL {
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentsPath.appendingPathComponent("voice_recording.m4a")
    }

    override init() {
        super.init()
        setupAudioSession()
    }

    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker, .allowBluetooth])
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }

    func startRecording() {
        // Request microphone permission
        AVAudioSession.sharedInstance().requestRecordPermission { [weak self] granted in
            guard let self = self else { return }

            Task { @MainActor in
                if granted {
                    self.beginRecording()
                } else {
                    print("Microphone permission denied")
                }
            }
        }
    }

    private func beginRecording() {
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            // Remove existing recording
            try? FileManager.default.removeItem(at: recordingURL)

            audioRecorder = try AVAudioRecorder(url: recordingURL, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
            audioRecorder?.record()

            isRecording = true
            recordingDuration = 0

            // Start level monitoring
            levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.updateAudioLevel()
                }
            }

            // Start duration tracking
            durationTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
                Task { @MainActor in
                    self?.recordingDuration += 0.1
                }
            }
        } catch {
            print("Failed to start recording: \(error)")
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        levelTimer?.invalidate()
        durationTimer?.invalidate()
        levelTimer = nil
        durationTimer = nil
        isRecording = false
        audioLevel = 0

        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            return nil
        }

        return recordingURL
    }

    func cancelRecording() {
        audioRecorder?.stop()
        levelTimer?.invalidate()
        durationTimer?.invalidate()
        levelTimer = nil
        durationTimer = nil
        isRecording = false
        audioLevel = 0
        recordingDuration = 0

        try? FileManager.default.removeItem(at: recordingURL)
    }

    private func updateAudioLevel() {
        audioRecorder?.updateMeters()
        let level = audioRecorder?.averagePower(forChannel: 0) ?? -160
        // Normalize to 0-1 range
        audioLevel = max(0, (level + 50) / 50)
    }

    func playAudio(from url: URL) {
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
        }
    }

    func playAudio(data: Data) {
        do {
            audioPlayer = try AVAudioPlayer(data: data)
            audioPlayer?.delegate = self
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
            isPlaying = true
        } catch {
            print("Failed to play audio: \(error)")
        }
    }

    func stopPlayback() {
        audioPlayer?.stop()
        isPlaying = false
    }

    func getRecordingData() -> Data? {
        guard FileManager.default.fileExists(atPath: recordingURL.path) else {
            return nil
        }
        return try? Data(contentsOf: recordingURL)
    }
}

extension AudioManager: AVAudioPlayerDelegate {
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            isPlaying = false
        }
    }
}
