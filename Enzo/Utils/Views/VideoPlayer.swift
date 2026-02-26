//
//  VideoPlayer.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-19.
//

import SwiftUI
import AVFoundation
import NukeVideo

struct VideoPlayer: View {
  var asset: AVAsset?
  var videoGravity: AVLayerVideoGravity = .resizeAspectFill
  var isLooping: Bool = true
  var animatesFrameChanges: Bool = true
  var autoPlay: Bool = true
  var showsControls: Bool = true
  var onVideoFinished: (() -> Void)?

  @State private var isPlaying: Bool = false
  @State private var shouldAutoPlay: Bool

  // Reference to actual player for external control
  let playerRef = VideoPlayerReference()

  // MARK: - Initialization
  init(
    asset: AVAsset? = nil,
    videoGravity: AVLayerVideoGravity = .resizeAspectFill,
    isLooping: Bool = true,
    animatesFrameChanges: Bool = true,
    autoPlay: Bool = true,
    showsControls: Bool = true,
    onVideoFinished: (() -> Void)? = nil
  ) {
    self.asset = asset
    self.videoGravity = videoGravity
    self.isLooping = isLooping
    self.animatesFrameChanges = animatesFrameChanges
    self.autoPlay = autoPlay
    self.showsControls = showsControls
    self.onVideoFinished = onVideoFinished
    self._shouldAutoPlay = State(initialValue: autoPlay)
  }

  // MARK: - Body
  var body: some View {
    ZStack {
      // Video player wrapper
      VideoPlayerViewWrapper(
        asset: asset,
        videoGravity: videoGravity,
        isLooping: isLooping,
        animatesFrameChanges: animatesFrameChanges,
        playerRef: playerRef,
        onVideoFinished: {
          isPlaying = false
          onVideoFinished?()
        }
      )
      .onChange(of: asset) { _, _ in
        if autoPlay {
          playWithDelay()
        }
      }
      .onAppear {
        playerRef.onPlayStateChanged = { playing in
          isPlaying = playing
        }

        if shouldAutoPlay && asset != nil {
          playWithDelay()
          shouldAutoPlay = false
        }
      }

      // Overlay controls
      if showsControls && !isPlaying {
        Button {
          play()
        } label: {
          Image(systemName: "play.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 60, height: 60)
            .foregroundColor(.white)
            .opacity(0.8)
            .shadow(color: .black.opacity(0.5), radius: 2)
        }
      }
    }
  }

  // MARK: - Helper Methods
  private func playWithDelay() {
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
      play()
    }
  }

  // MARK: - Public Control Methods

  /// Plays the video from current position
  public func play() {
    playerRef.play()
    isPlaying = true
  }

  /// Pauses the video at current position
  public func pause() {
    playerRef.reset() // VideoPlayerView doesn't have pause, only reset
    isPlaying = false
  }

  /// Resets video to beginning and stops
  public func reset() {
    playerRef.reset()
    isPlaying = false
  }

  /// Restarts video from beginning
  public func restart() {
    playerRef.restart()
    isPlaying = true
  }
}

// MARK: - URL Convenience Extension
extension VideoPlayer {
  /// Initialize with URL
  init(
    url: URL?,
    videoGravity: AVLayerVideoGravity = .resizeAspectFill,
    isLooping: Bool = true,
    animatesFrameChanges: Bool = true,
    autoPlay: Bool = true,
    showsControls: Bool = true,
    onVideoFinished: (() -> Void)? = nil
  ) {
    let asset = url.map { AVURLAsset(url: $0) }
    self.init(
      asset: asset,
      videoGravity: videoGravity,
      isLooping: isLooping,
      animatesFrameChanges: animatesFrameChanges,
      autoPlay: autoPlay,
      showsControls: showsControls,
      onVideoFinished: onVideoFinished
    )
  }
}

// MARK: - Convenience methods for SwiftUI modifiers
extension VideoPlayer {
  /// Set the video content using an asset
  func asset(_ asset: AVAsset?) -> VideoPlayer {
    var view = self
    view.asset = asset
    return view
  }

  /// Set the video content using a URL
  func url(_ url: URL?) -> VideoPlayer {
    var view = self
    view.asset = url.map { AVURLAsset(url: $0) }
    return view
  }

  /// Set the video scaling/cropping behavior
  func videoGravity(_ videoGravity: AVLayerVideoGravity) -> VideoPlayer {
    var view = self
    view.videoGravity = videoGravity
    return view
  }

  /// Set whether the video should loop
  func looping(_ isLooping: Bool) -> VideoPlayer {
    var view = self
    view.isLooping = isLooping
    return view
  }

  /// Set whether to animate frame changes
  func animatesFrameChanges(_ animatesFrameChanges: Bool) -> VideoPlayer {
    var view = self
    view.animatesFrameChanges = animatesFrameChanges
    return view
  }

  /// Set whether to automatically start playback
  func autoPlay(_ autoPlay: Bool) -> VideoPlayer {
    var view = self
    view.autoPlay = autoPlay
    return view
  }

  /// Set whether to show playback controls
  func showsControls(_ showsControls: Bool) -> VideoPlayer {
    var view = self
    view.showsControls = showsControls
    return view
  }

  /// Set the callback for when video finishes playing
  func onFinished(_ action: @escaping () -> Void) -> VideoPlayer {
    var view = self
    view.onVideoFinished = action
    return view
  }
}

// MARK: - Player Reference for external control
class VideoPlayerReference {
  private weak var playerView: VideoPlayerView?
  var onPlayStateChanged: ((Bool) -> Void)?

  @MainActor func play() {
    playerView?.play()
  }

  @MainActor func reset() {
    playerView?.reset()
  }

  @MainActor func restart() {
    playerView?.restart()
  }

  fileprivate func setPlayerView(_ playerView: VideoPlayerView) {
    self.playerView = playerView
  }
}

// MARK: - UIViewRepresentable Implementation
struct VideoPlayerViewWrapper: UIViewRepresentable {
  var asset: AVAsset?
  var videoGravity: AVLayerVideoGravity
  var isLooping: Bool
  var animatesFrameChanges: Bool
  var playerRef: VideoPlayerReference
  var onVideoFinished: (() -> Void)?

  func makeUIView(context: Context) -> VideoPlayerView {
    let playerView = VideoPlayerView()
    playerView.videoGravity = videoGravity
    playerView.isLooping = isLooping
    playerView.animatesFrameChanges = animatesFrameChanges
    playerView.onVideoFinished = onVideoFinished

    // Store reference to player for external control
    playerRef.setPlayerView(playerView)

    // Set asset last to ensure proper configuration before playback
    if let asset = asset {
      playerView.asset = asset
    }

    return playerView
  }

  func updateUIView(_ playerView: VideoPlayerView, context: Context) {
    // Update properties if needed
    playerView.videoGravity = videoGravity
    playerView.isLooping = isLooping
    playerView.animatesFrameChanges = animatesFrameChanges
    playerView.onVideoFinished = onVideoFinished

    // Only update asset if it changed
    if playerView.asset != asset {
      playerView.asset = asset
    }
  }
}

// MARK: - Example Usage
struct VideoPlayerExampleView: View {
  // Create a single instance of the player
  @State private var videoPlayer = VideoPlayer(
    url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"),
    videoGravity: .resizeAspect,
    isLooping: true,
    autoPlay: true,
    showsControls: true,
    onVideoFinished: {
      print("Video finished playing")
    }
  )

  var body: some View {
    VStack(spacing: 24) {
      Text("Video Player Demo")
        .font(.title)
        .fontWeight(.bold)

      // Use the same player instance
      VideoPlayer(
        url: URL(string: "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ElephantsDream.mp4"),
        videoGravity: .resizeAspect,
        isLooping: true,
        autoPlay: true,
        showsControls: true,
        onVideoFinished: {
          print("Video finished playing")
        }
      )
        .cornerRadius(12)
        .shadow(radius: 8)
        .frame(height: 240)

      // Custom controls connected to the actual player instance
      HStack(spacing: 40) {
        Button {
          videoPlayer.play()
        } label: {
          Label("Play", systemImage: "play.fill")
        }
        .buttonStyle(.bordered)

        Button {
          videoPlayer.reset()
        } label: {
          Label("Stop", systemImage: "stop.fill")
        }
        .buttonStyle(.bordered)

        Button {
          videoPlayer.restart()
        } label: {
          Label("Restart", systemImage: "arrow.clockwise")
        }
        .buttonStyle(.bordered)
      }
      .padding(.top)

      Spacer()

      Text("Create beautiful video experiences with minimal code")
        .font(.callout)
        .foregroundColor(.secondary)
        .multilineTextAlignment(.center)
        .padding()
    }
    .padding()
  }
}

// MARK: - Preview
#Preview {
  VideoPlayerExampleView()
}
