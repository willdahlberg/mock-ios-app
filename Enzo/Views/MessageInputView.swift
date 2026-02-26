//
//  MessageInputView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-31.
//

import SwiftUI
import PhotosUI

struct MessageInputView: View {
  @State var inputString: String = ""
  let isTyping: Bool
  var isFocused: FocusState<Bool>.Binding
  let onSend: (String) -> Void
  @Binding var photoPickerItem: PhotosPickerItem?

  var body: some View {
    HStack {
      ZStack {
        RoundedRectangle(cornerRadius: 24)
          .fill(.background)
          .allowsHitTesting(false)

        RoundedRectangle(cornerRadius: 24)
          .stroke(Color.secondary.opacity(0.5), lineWidth: 1)
          .allowsHitTesting(false)

        RoundedRectangle(cornerRadius: 24)
          .fill(
            LinearGradient(
              colors: [
                .black.opacity(0.2),
                .clear
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )
          .mask(
            RoundedRectangle(cornerRadius: 24)
              .stroke(lineWidth: 4)
              .blur(radius: 4)
          )
          .allowsHitTesting(false)

        HStack(spacing: 4) {
          PhotosPicker(selection: $photoPickerItem, matching: .images) {
            Image(systemName: "paperclip.circle.fill")
              .fontWeight(.light)
              .font(.system(size: 32))
              .dynamicGradient(.accent, .white)
          }
          .padding(.leading, 6)

          TextField("Ask Enzo...", text: $inputString)
            .focused(isFocused)

          Button(action: {
            onSend(inputString)
            inputString = ""
          }) {
            Image(systemName: "arrow.up.circle.fill")
              .fontWeight(.light)
              .font(.system(size: 32))
              .dynamicGradient(inputString.isEmpty || isTyping ? .gray : .accent, .white)
          }
          .disabled(inputString.isEmpty || isTyping)
          .padding(.trailing, 6)
        }
      }
      .frame(height: 48)
      .padding(.horizontal)
    }
    .padding(.vertical, 8)
    .background(.ultraThinMaterial)
  }
}

#Preview {
  struct PreviewWrapper: View {
    @State private var text = ""
    @FocusState private var isFocused: Bool

    var body: some View {
      VStack(spacing: 20) {
        // Empty state
        MessageInputView(
          isTyping: false,
          isFocused: $isFocused,
          onSend: { _ in },
          photoPickerItem: .constant(nil)
        )
        Spacer()
        // With text
        MessageInputView(
          isTyping: false,
          isFocused: $isFocused,
          onSend: { _ in },
          photoPickerItem: .constant(nil)
        )
        Spacer()
        // Typing state
        MessageInputView(
          isTyping: true,
          isFocused: $isFocused,
          onSend: { _ in },
          photoPickerItem: .constant(nil)
        )
      }
//      .frame(maxHeight: .infinity, alignment: .top)
      .background(Color(.systemBackground))
    }
  }

  return PreviewWrapper()
}
