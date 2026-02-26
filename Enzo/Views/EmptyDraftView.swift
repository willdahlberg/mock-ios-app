//
//  EmptyDraftView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-01.
//

import SwiftUI

struct EmptyDraftView: View {
  let onShortcutSelected: (String) -> Void

  private let shortcuts = [
    Shortcut(
      title: "Make Images",
      message: "Create some images for me",
      icon: "photo.stack"
    ),
    Shortcut(
      title: "Create Videos",
      message: "Create some videos for me",
      icon: "video.fill"
    ),
    Shortcut(
      title: "Swap Background",
      message: "Help me swap the background in my image",
      icon: "wand.and.stars"
    ),
    Shortcut(
      title: "Write Marketing Content",
      message: "Help me write some marketing content",
      icon: "megaphone.fill"
    )
  ]

  var body: some View {
    GeometryReader { geometry in
      ScrollView {
        VStack(spacing: 20) {
          Image("assistant_avatar")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 120, height: 120)

          Text("Let's create something")
            .font(.largeTitle)
            .bold()

          Text("Choose a starting point, or ask me anything below")
            .font(.subheadline)
            .foregroundColor(.secondary)

          VStack(spacing: 12) {
            ForEach(shortcuts) { shortcut in
              Button(action: { onShortcutSelected(shortcut.message) }) {
                HStack {
                  HStack(spacing: 8) {
                    Image(systemName: shortcut.icon)
                      .foregroundStyle(.white)
                      .font(.system(size: 20))
                      .frame(width: 24)

                    Text(shortcut.title)
                      .font(.callout)
                      .foregroundStyle(.white)
                  }
                }
                .frame(height: 24)
                .fontWeight(.semibold)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background {
                  RoundedRectangle(cornerRadius: 16)
                    .dynamicGradient(.accent)
                }
              }
              .buttonStyle(.automatic)
            }
          }
          .padding(.horizontal, 16)
        }
        .frame(minHeight: geometry.size.height)
        .frame(maxWidth: .infinity)
        .multilineTextAlignment(.center)
      }
    }
  }
}

private struct Shortcut: Identifiable {
  let id = UUID()
  let title: String
  let message: String
  let icon: String
}

#Preview {
  EmptyDraftView { message in }
}
