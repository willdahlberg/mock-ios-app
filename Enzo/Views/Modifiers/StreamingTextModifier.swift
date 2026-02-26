//
//  StreamingTextModifier.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-02.
//

import SwiftUI

enum StreamingMode {
  case none
  case character
  case word
}

struct StreamingTextModifier: ViewModifier {
  let fullText: String
  let mode: StreamingMode
  @State private var displayedText: String = ""
  @State private var animationTask: Task<Void, Never>?

  func body(content: Content) -> some View {
    Text(mode != .none ? displayedText : fullText)
      .onChange(of: fullText) { oldText, newText in
        let newText = newText.trimmingCharacters(in: .whitespacesAndNewlines)

        if mode == .none {
          displayedText = newText
          return
        }

        if newText.hasPrefix(displayedText) {
          animateNewContent(newText)
        } else {
          startNewAnimation(newText)
        }
      }
      .onAppear {
        if mode != .none {
          startNewAnimation(fullText)
        } else {
          displayedText = fullText
        }
      }
  }

  private func startNewAnimation(_ text: String) {
    displayedText = ""
    animateNewContent(text)
  }

  private func animateNewContent(_ newText: String) {
    animationTask?.cancel()

    switch mode {
    case .character:
      animateCharacterByCharacter(newText)
    case .word:
      animateWordByWord(newText)
    case .none:
      displayedText = newText
    }
  }

  private func animateCharacterByCharacter(_ newText: String) {
    let startIndex = displayedText.count
    let newCharacters = Array(newText.dropFirst(startIndex))

    animationTask = Task { @MainActor in
      for character in newCharacters {
        if Task.isCancelled { return }
        try? await Task.sleep(for: .milliseconds(20))
        if Task.isCancelled { return }

        displayedText += String(character)
      }
    }
  }

  private func animateWordByWord(_ newText: String) {
    let startIndex = displayedText.count
    let remainingText = String(newText.dropFirst(startIndex))
    let words = remainingText.split(separator: " ", omittingEmptySubsequences: false)

    animationTask = Task { @MainActor in
      for (index, word) in words.enumerated() {
        if Task.isCancelled { return }
        try? await Task.sleep(for: .milliseconds(100))
        if Task.isCancelled { return }

        if index > 0 {
          displayedText += " "
        }
        displayedText += String(word)
      }
    }
  }
}

extension View {
  func streamingText(_ text: String, mode: StreamingMode = .character) -> some View {
    modifier(StreamingTextModifier(fullText: text, mode: mode))
  }
}

struct StreamingTitleModifier: ViewModifier {
  let title: String
  @State private var displayedTitle: String
  @State private var streamingTask: Task<Void, Never>?

  init(title: String) {
    self.title = title
    self.displayedTitle = title
  }

  func body(content: Content) -> some View {
    content
      .navigationTitle(displayedTitle)
      .onChange(of: title) { _, newValue in
        startStreaming(newValue)
      }
  }

  private func startStreaming(_ title: String) {
    streamingTask?.cancel()
    displayedTitle = ""

    streamingTask = Task { @MainActor in
      for (index, character) in title.enumerated() {
        if Task.isCancelled { return }
        try? await Task.sleep(for: .milliseconds(50))
        if Task.isCancelled { return }

        displayedTitle += String(character)

        if index == title.count - 1 {
          break
        }
      }
    }
  }
}

extension View {
  func streamingNavigationTitle(_ title: String) -> some View {
    modifier(StreamingTitleModifier(title: title))
  }
}
