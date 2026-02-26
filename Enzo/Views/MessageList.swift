//
//  MessageList.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-03.
//

import SwiftUI

struct MessageList: View {
  let messages: [Message]
  let showTypingIndicator: Bool
  let isLastBubble: (Message) -> Bool
  
  var body: some View {
    VStack {
      ForEach(messages) { message in
        MessageRow(message: message)
          .modifier(MessageRevealModifier(message: message))
          .padding(.bottom, isLastBubble(message) ? 8 : 0)
      }
      
      if showTypingIndicator {
        HStack {
          TypingIndicator()
          Spacer()
        }
        .id("typingIndicator")
        .padding(.horizontal)
        .padding(.bottom, 8)
      }
    }
  }
}

struct MessageRevealModifier: ViewModifier {
  let message: Message
  @State private var isShown = false

  func body(content: Content) -> some View {
    content
      .opacity(isShown ? 1 : 0)
      .animation(.spring(response: 0.3, dampingFraction: 0.8), value: isShown)
      .onAppear {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
          isShown = true
        }
      }
  }
}
