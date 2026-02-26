//
//  AttachmentsShelf.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-13.
//

import SwiftUI

enum AttachmentState {
  case ready
  case uploading
  case error
}

struct Attachment: Identifiable, Equatable {
  let id: String
  let image: Image
  let state: AttachmentState

  init(id: String, image: Image, state: AttachmentState = .ready) {
    self.id = id
    self.image = image
    self.state = state
  }
}

struct AttachmentsShelf: View {
  let attachments: [Attachment]
  let onClear: () -> Void

  var body: some View {
    VStack(spacing: 0) {
      Divider()
      ScrollView(.horizontal, showsIndicators: false) {
        HStack(spacing: 8) {
          ForEach(attachments) { attachment in
            attachment.image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(width: 60, height: 60)
              .overlay {
                switch attachment.state {
                case .ready:
                  EmptyView()
                case .uploading:
                  ZStack {
                    Rectangle()
                      .fill(.background.opacity(0.8))
                    ProgressView()
                  }
                case .error:
                  ZStack {
                    Rectangle()
                      .fill(.background.opacity(0.8))
                    Image(systemName: "xmark.circle.fill")
                      .foregroundColor(.red)
                  }
                }
              }
              .clipShape(RoundedRectangle(cornerRadius: 8))
          }
          Button(role: .cancel) {
            onClear()
          } label: {
            Image(systemName: "xmark.circle.fill")
          }
          .frame(height: 72)
        }
        .padding(.horizontal)
      }
      .frame(height: 76)
    }
    .background(.ultraThinMaterial)
    .transition(
      .move(edge: .bottom)
      .combined(with: .opacity)
    )
  }
}

#Preview {
  AttachmentsShelf(attachments: [], onClear: {})
  AttachmentsShelf(attachments: [
    Attachment(
      id: "img1",
      image: Image(systemName: "photo")
    ),
    Attachment(
      id: "img2",
      image: Image(systemName: "photo")
    ),
    Attachment(
      id: "img3",
      image: Image(systemName: "photo")
    )
  ], onClear: {})
  .frame(maxWidth: .infinity)
  .background(Color(.systemBackground))
}
