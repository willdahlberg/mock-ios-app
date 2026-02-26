//
//  SoundPlayer.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-02.
//

import AVFoundation
import UIKit

class SoundPlayer {
  static let shared = SoundPlayer()
  private var audioPlayer: AVAudioPlayer?

  private init() {
    setupAudioSession()
  }

  private func setupAudioSession() {
    do {
      try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
      try AVAudioSession.sharedInstance().setActive(true)
    } catch {
      print("Failed to set up audio session: \(error)")
    }
  }

  func playContentGenerated() {
    guard let soundData = NSDataAsset(name: "incoming")?.data else {
      print("Sound data not found in asset catalog")
      return
    }

    do {
      audioPlayer = try AVAudioPlayer(data: soundData)
      audioPlayer?.prepareToPlay()
      audioPlayer?.play()
    } catch {
      print("Failed to play sound: \(error)")
    }
  }
}
