import Foundation
import AVFoundation

class AudioHandler: ObservableObject {
    static let shared = AudioHandler()

    private var audioPlayer: AVAudioPlayer?

    private init() {
        configureAudioSession()
    }

    // Function to configure the AVAudioSession
    private func configureAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default, options: [])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    // Function to play a sound effect
    func playSound(named soundName: String, withExtension fileExtension: String) {
        if let soundURL = Bundle.main.url(forResource: soundName, withExtension: fileExtension) {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
                print("Sound is playing: \(soundName).\(fileExtension)")
            } catch {
                print("Error loading sound file: \(error)")
            }
        } else {
            print("Sound file not found: \(soundName).\(fileExtension)")
        }
    }
}
