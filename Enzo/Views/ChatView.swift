//
//  ChatView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI
import PhotosUI

struct ChatView: View {
  @StateObject private var viewModel: ChatViewModel
  @StateObject private var fileManager = FileUploadManager.shared
  @FocusState private var inputIsFocused
  @State private var scrollPosition: String?
  @State private var showTypingIndicator = false
  @State private var hasLoadedInitialMessages = false
  @State private var photoPickerItem: PhotosPickerItem?

  init(chat: Chat, assistantManager: AssistantManager) {
    _viewModel = StateObject(wrappedValue: ChatViewModel(chat: chat, assistantManager: assistantManager))
  }

  private var isEmptyDraft: Bool {
    viewModel.isPendingChat
  }

  private func isLastBubble(_ message: Message) -> Bool {
    !showTypingIndicator && message.serverId == viewModel.displayedChat.messages.last?.serverId
  }

  private func handleMessageCountChange() {
    guard (hasLoadedInitialMessages) else {
      showTypingIndicator = false
      return
    }

    if let lastMessage = viewModel.displayedChat.messages.last {
      if lastMessage.role == .user {
        // Wait 0.5 seconds, then show the indicator
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
          showTypingIndicator = true
          withAnimation {
            scrollPosition = "typingIndicator"
          }
        }
      } else {
        // Hide indicator when we get a non-user message
        showTypingIndicator = false
        withAnimation {
          scrollPosition = lastMessage.serverId
        }
      }
    }
  }

  private func handleUseGeneration(_ generation: Generation, preview: Image) {
    let attachment = Attachment(id: generation.id, image: preview)
    if !viewModel.generationAttachments.contains(attachment) {
      withAnimation(.smooth) {
        viewModel.generationAttachments.append(attachment)
      }
    }
  }

  var body: some View {
      VStack(spacing: 0) {
        ZStack {
          if isEmptyDraft {
            EmptyDraftView(onShortcutSelected: { message in
              viewModel.sendMessage(message)
            })
            .transition(.blurReplace)
            .scrollDismissesKeyboard(.immediately)
          } else {
            ScrollView {
              MessageList(
                messages: viewModel.displayedChat.messages,
                showTypingIndicator: showTypingIndicator,
                isLastBubble: isLastBubble
              )
              .transaction {
                // Workaround for messages fading in on push
                if (!hasLoadedInitialMessages) {
                  $0.disablesAnimations = true
                }
              }
            }
            .transition(.blurReplace)
            .scrollDismissesKeyboard(.immediately)
            .defaultScrollAnchor(.bottom)
            .scrollPosition(id: $scrollPosition, anchor: .bottom)
            .onChange(of: viewModel.displayedChat.messages.count, initial: false) { _, _ in
              handleMessageCountChange()
            }
            .onAppear {
              Task {
                try await viewModel.loadThread()
                hasLoadedInitialMessages = true
              }
            }
          }
        }
        .animation(.spring(.smooth), value: isEmptyDraft)

        if viewModel.generationAttachments.isEmpty && fileManager.fileUploads.isEmpty {
          Divider()
        } else {
          let files = fileManager.fileUploads.map { file in
            Attachment(id: file.fileUrl ?? file.filename, image: file.preview, state: file.isUploading ? .uploading : file.error != nil ? .error : .ready)
          }
          AttachmentsShelf(attachments: viewModel.generationAttachments + files, onClear: {
            withAnimation(.snappy) {
              viewModel.generationAttachments.removeAll()
              fileManager.clear()
            }
          })
        }

        MessageInputView(
          isTyping: false,
          isFocused: $inputIsFocused,
          onSend: { messageString in viewModel.sendMessage(messageString) },
          photoPickerItem: $photoPickerItem
        )
      }
      .onChange(of: photoPickerItem) { _, newItem in
        if let newItem {
          Task {
            if let data = try? await newItem.loadTransferable(type: Data.self), let image = UIImage(data: data) {
              do {
                try await fileManager.handleFiles([image])
              } catch {
                print("Failed to upload file: \(error)")
              }
            }
          }
        }
      }
      .navigationBarTitleDisplayMode(.inline)
      .streamingNavigationTitle(viewModel.displayedChat.title ?? viewModel.displayedChat.summary)
      .toolbarBackground(.visible, for: .navigationBar) // Workaround for the navigation bar losing the background when transition happens
      .environment(\.onUseGeneration, handleUseGeneration)
    }
}

// ChatView Environment

private struct OnUseGenerationKey: EnvironmentKey {
  static let defaultValue: (Generation, Image) -> Void = { _, _ in
    fatalError("Non-existent environment variable OnUseGenerationKey used")
  }
}

extension EnvironmentValues {
  var onUseGeneration: (Generation, Image) -> Void {
    get { self[OnUseGenerationKey.self] }
    set { self[OnUseGenerationKey.self] = newValue }
  }
}

#Preview {
  let chat = Chat(
    clientUuid: UUID().uuidString,
    id: "mockthread",
    summary: "Summary",
    title: "Title",
    messages: [Message(serverId: "messageid", threadId: "mockthread", role: .user, content: [.text(TextContent(text: "Hello"))], clientUuid: UUID().uuidString, order: 0, contextGenerationIds: nil, contextModelIds: nil, createdAt: Date())],
    createdAt: Date(),
    updatedAt: Date()
  )

  ChatView(chat: chat, assistantManager: AssistantManager())
}
