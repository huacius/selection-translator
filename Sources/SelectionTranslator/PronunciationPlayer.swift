import AVFoundation
import Foundation

@MainActor
final class PronunciationPlayer: NSObject {
    private var player: AVPlayer?
    private let synthesizer = AVSpeechSynthesizer()

    func play(text: String, audioURL: URL?) {
        if let audioURL {
            player = AVPlayer(url: audioURL)
            player?.play()
            return
        }

        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synthesizer.speak(utterance)
    }
}
