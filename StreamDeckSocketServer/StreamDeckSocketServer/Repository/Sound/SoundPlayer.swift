//
//  SoundPlayer.swift
//  StreamDeckSocketServer
//
//  Created by h.tsuruta on 2025/08/31.
//

import Foundation
import AVFoundation

// MARK: - Player
final class SoundPlayer {
    static let shared = SoundPlayer()
    private var audioPlayer: AVAudioPlayer?

    func playSound(named soundName: String) {
        guard let url = Bundle.main.url(forResource: soundName, withExtension: "mp3") else {
            print("❌ MP3 file not found: \(soundName)")
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.play()
        } catch {
            print("❌ Failed to play MP3: \(error)")
        }
    }
}
