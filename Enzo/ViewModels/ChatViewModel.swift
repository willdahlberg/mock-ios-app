//
//  ChatViewModel.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import Foundation

@MainActor
class ChatViewModel: ObservableObject {
  private let assistantManager: AssistantManager
  private var pollingManager: GenerationPollingManager?

  // Source of truth from assistantManager
  private var sourceChat: Chat

  @Published private(set) var displayedChat: Chat

  @Published var generationAttachments: [Attachment] = []

  init(chat: Chat, assistantManager: AssistantManager) {
    self.sourceChat = chat
    self.displayedChat = Chat(
      clientUuid: chat.clientUuid,
      id: chat.id,
      summary: chat.summary,
      title: chat.title,
      messages: [],
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt
    )
    self.assistantManager = assistantManager

    setupBindings()
    setupImageGenerationPolling()
    checkForIncompleteGenerations()
  }

  deinit {
    Task.detached { [pollingManager] in
      await pollingManager?.stopAllPolling()
    }
  }

  private func setupBindings() {
    assistantManager.$chats
      .map { [weak self] chats -> Chat? in
        guard let self = self else { return nil }
        guard let newSourceChat = chats.first(where: { $0.clientUuid == self.displayedChat.clientUuid }) else { return nil }

        // Create dictionary of current displayed messages by ID
        let displayedMessages = Dictionary(
          uniqueKeysWithValues: self.displayedChat.messages.map { ($0.serverId, $0) }
        )

        let transformedMessages = newSourceChat.messages.map { sourceMessage in
          if let displayedMessage = displayedMessages[sourceMessage.serverId] {
            // If source hasn't changed, keep our displayed version
            if sourceMessage == self.sourceChat.messages.first(where: { $0.serverId == sourceMessage.serverId }) {
              return displayedMessage
            }
          }
          // If message is new or source has changed, apply transformation
          return self.transformMessage(sourceMessage)
        }

        // Update source chat
        self.sourceChat = newSourceChat

        return Chat(
          clientUuid: newSourceChat.clientUuid,
          id: newSourceChat.id,
          summary: newSourceChat.summary,
          title: newSourceChat.title,
          messages: transformedMessages,
          createdAt: newSourceChat.createdAt,
          updatedAt: newSourceChat.updatedAt
        )
      }
      .compactMap { $0 }
      .assign(to: &$displayedChat)
  }

  private func transformMessage(_ message: Message) -> Message {
    // Only transform tool result messages
    guard case let .toolResult(toolResult) = message.content.first else {
      return message
    }

    // Only transform text content
    guard case let .text(textContent) = toolResult.content.first else {
      return message
    }

    // Try to decode the tool result data
    guard let jsonData = textContent.text.data(using: .utf8),
          let toolResultData = try? SocketJSONDecoder().decode(ToolResultData.self, from: jsonData) else {
      return message
    }

    guard let resultData = try? SocketJSONEncoder().encode(toolResultData.data.result) else {
      return message
    }

    switch toolResultData.toolName {
    case .creativeWriting:
      if let creativeWritingOutput = try? SocketJSONDecoder().decode(CreativeWritingOutput.self, from: resultData) {
        return Message(
          serverId: message.serverId,
          threadId: message.threadId,
          role: .assistant,
          content: [.text(TextContent(text: creativeWritingOutput.creativeWritingOutput.value))],
          clientUuid: message.clientUuid,
          order: message.order,
          contextGenerationIds: message.contextGenerationIds,
          contextModelIds: message.contextModelIds,
          createdAt: message.createdAt
        )
      }
    case
        .imageGeneration,
        .videoGeneration,
        .externalGeneration,
        .backgroundRestyle,
        .backgroundRemoval,
        .freeformEdit,
        .upscale,
        .outpaint:
      if let imageGenerationOutput = try? SocketJSONDecoder().decode(ImageGenerationOutput.self, from: resultData) {

        let transformedMessage = Message(
          serverId: message.serverId,
          threadId: message.threadId,
          role: .assistant,
          content: [.toolWork(imageGenerationOutput)],
          clientUuid: message.clientUuid,
          order: message.order,
          contextGenerationIds: message.contextGenerationIds,
          contextModelIds: message.contextModelIds,
          createdAt: message.createdAt
        )

        Task {
          await pollingManager?.startPolling(output: imageGenerationOutput)
        }

        return transformedMessage
      }
    case .fetchGenerations:
      if let generationsOutput = try? SocketJSONDecoder().decode(FetchGenerationsOutput.self, from: resultData) {

        return Message(
          serverId: message.serverId,
          threadId: message.threadId,
          role: .assistant,
          content: [.generations(generationsOutput)],
          clientUuid: message.clientUuid,
          order: message.order,
          contextGenerationIds: message.contextGenerationIds,
          contextModelIds: message.contextModelIds,
          createdAt: message.createdAt
        )
      }
    case .fetchModels:
      if let modelsOutput = try? SocketJSONDecoder().decode(FetchModelsOutput.self, from: resultData) {
        return Message(
          serverId: message.serverId,
          threadId: message.threadId,
          role: .assistant,
          content: [.models(modelsOutput)],
          clientUuid: message.clientUuid,
          order: message.order,
          contextGenerationIds: message.contextGenerationIds,
          contextModelIds: message.contextModelIds,
          createdAt: message.createdAt
        )
      }
    default:
      print("unsupported tool: \(toolResultData.toolName)")
      return message
    }

    return message
  }

  func sendMessage(_ content: String) {
    guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

    Task {
      do {
        try await assistantManager.sendMessage(
          input: content,
          contextGenerationIds: generationAttachments.map(\.id),
          in: displayedChat.clientUuid
        )
        await MainActor.run {
          self.generationAttachments.removeAll()
        }
      } catch {
        print("Failed to send message:", error)
      }
    }
  }

  func loadThread() async throws {
    if let chatId = displayedChat.id {
      try await assistantManager.loadThread(chatId)
    }
  }

  var isPendingChat: Bool {
    displayedChat.id == nil
  }
}

// MARK: - Image Generation Polling
extension ChatViewModel {
  func setupImageGenerationPolling() {
    self.pollingManager = GenerationPollingManager { [weak self] generationId, generation in
      guard let self = self else { return }

      let updatedMessage = self.displayedChat.messages.first { message in
        if case let .toolWork(output) = message.content.first,
           output.generationIds.contains(generationId) {
          return true
        }
        return false
      }?.transformedWithGeneration(generationId: generationId, generation: generation)

      if let updatedMessage = updatedMessage {
        self.displayedChat = Chat(
          clientUuid: self.displayedChat.clientUuid,
          id: self.displayedChat.id,
          summary: self.displayedChat.summary,
          title: self.displayedChat.title,
          messages: self.displayedChat.messages.map { msg in
            msg.serverId == updatedMessage.serverId ? updatedMessage : msg
          },
          createdAt: self.displayedChat.createdAt,
          updatedAt: self.displayedChat.updatedAt
        )
      }
    }
  }

  func checkForIncompleteGenerations() {
    for message in displayedChat.messages {
      if case let .toolWork(output) = message.content.first {
        Task {
          await pollingManager?.startPolling(output: output)
        }
      }
    }
  }
}
