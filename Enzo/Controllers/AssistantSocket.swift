//
//  AssistantSocket.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import Foundation

// MARK: - Protocol Definition

@MainActor
protocol AssistantSocketInterface: AnyObject {
  func onConnect()
  func onDisconnect()
  func onThreadUpdated(_ thread: Chat)
  func onMessageComplete(_ message: Message)
  func onAssistantMessageDelta(_ messageDelta: MessageDelta)
  func onAssistantMessageComplete()
  func onAssistantDone()
  func onError(_ message: String, requiresReAuth: Bool)
}

// MARK: - Socket Error Types

enum SocketError: LocalizedError {
  case notAuthenticated
  case unauthorized
  case serverError(String)
  case notConnected
  case missingData
  case invalidURL
  case socketError(String)

  var errorDescription: String? {
    switch self {
    case .notAuthenticated:
      return "No user"
    case .unauthorized:
      return "No socket access token"
    case .serverError(let message):
      return "Server error: \(message)"
    case .notConnected:
      return "Not connected to assistant server"
    case .missingData:
      return "Missing data from server"
    case .invalidURL:
      return "Invalid server URL"
    case .socketError(let message):
      return "Socket error: \(message)"
    }
  }
}

// MARK: - Response Types

struct SocketResponse<T: Decodable>: Decodable {
  let success: Bool
  let data: T?
  let error: String?

  private enum CodingKeys: String, CodingKey {
    case success
    case data
    case error
  }

  func unwrapData() throws -> T {
    if let error = error {
      throw SocketError.serverError(error)
    }
    guard let data = data else {
      throw SocketError.missingData
    }
    return data
  }
}

struct ThreadResponse: Decodable {
  let thread: Chat
}

struct ThreadsResponse: Decodable {
  let threads: [Chat]
}

struct MessageResponse: Decodable {
  let message: Message
}

struct MessagesResponse: Decodable {
  let messages: [Message]
}

// MARK: - Main Socket Class (Mock)

@MainActor
class AssistantSocket {
  private let interface: AssistantSocketInterface

  // In-memory store for mock data
  private var threads: [String: Chat] = [:]
  private var messageStore: [String: [Message]] = [:] // threadId -> messages

  private static let mockResponses = [
    "That's a great question! I'd be happy to help you with that. Let me think about the best approach...",
    "Here's what I suggest: start by breaking down the problem into smaller pieces, then tackle each one individually.",
    "I love creative challenges like this! Let me put together something special for you.",
    "Absolutely! I can help with that. Based on what you've described, here's my recommendation...",
    "That's an interesting perspective. Let me build on that idea and add a few suggestions of my own.",
  ]

  init(interface: AssistantSocketInterface, organizationId: String? = nil) {
    self.interface = interface
    setupMockData()

    // Simulate connection after a brief delay
    Task { @MainActor in
      try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
      self.interface.onConnect()
    }
  }

  func disconnect() {
    interface.onDisconnect()
  }

  // MARK: - Mock Data Setup

  private func setupMockData() {
    let now = Date()

    // Thread 1: Getting Started with Enzo
    let thread1Id = "mock-thread-1"
    let thread1ClientUuid = UUID().uuidString
    let msg1_1 = Message(
      serverId: "msg-1-1",
      threadId: thread1Id,
      role: .user,
      content: [.text(TextContent(text: "Hi! What can you help me with?"))],
      clientUuid: UUID().uuidString,
      order: 0,
      contextGenerationIds: nil,
      contextModelIds: nil,
      createdAt: now.addingTimeInterval(-3600)
    )
    let msg1_2 = Message(
      serverId: "msg-1-2",
      threadId: thread1Id,
      role: .assistant,
      content: [.text(TextContent(text: "Hello! I'm Enzo, your creative AI assistant. I can help you with:\n\n• **Image Generation** — Create stunning images from text descriptions\n• **Creative Writing** — Stories, poems, scripts, and more\n• **Image Editing** — Background removal, restyling, upscaling\n• **Video Generation** — Turn images into short videos\n\nJust describe what you'd like to create and I'll get started!"))],
      clientUuid: UUID().uuidString,
      order: 1,
      contextGenerationIds: nil,
      contextModelIds: nil,
      createdAt: now.addingTimeInterval(-3590)
    )

    let thread1 = Chat(
      clientUuid: thread1ClientUuid,
      id: thread1Id,
      summary: "Introduction to Enzo's capabilities",
      title: "Getting Started with Enzo",
      messages: [msg1_1, msg1_2],
      createdAt: now.addingTimeInterval(-3600),
      updatedAt: now.addingTimeInterval(-3590)
    )

    // Thread 2: Image Generation Demo
    let thread2Id = "mock-thread-2"
    let thread2ClientUuid = UUID().uuidString
    let genId1 = "mock-gen-1"
    let genId2 = "mock-gen-2"
    let msg2_1 = Message(
      serverId: "msg-2-1",
      threadId: thread2Id,
      role: .user,
      content: [.text(TextContent(text: "Generate a beautiful sunset over the ocean"))],
      clientUuid: UUID().uuidString,
      order: 0,
      contextGenerationIds: nil,
      contextModelIds: nil,
      createdAt: now.addingTimeInterval(-7200)
    )
    let msg2_2 = Message(
      serverId: "msg-2-2",
      threadId: thread2Id,
      role: .assistant,
      content: [.text(TextContent(text: "I'll create a beautiful sunset over the ocean for you!"))],
      clientUuid: UUID().uuidString,
      order: 1,
      contextGenerationIds: nil,
      contextModelIds: nil,
      createdAt: now.addingTimeInterval(-7195)
    )

    let toolResultText = """
    {"type":"tool_result_data","tool_name":"image_generation","data":{"message":"Generated 2 images","result":{"prompt":"A beautiful sunset over the ocean with golden and purple hues reflecting on calm waters","image_count":2,"video_count":null,"aspect_ratio":"16:9","generation_ids":["\(genId1)","\(genId2)"],"generations":{"\(genId1)":{"id":"\(genId1)","model_id":"mock-model-1","image_url":"https://picsum.photos/512/512?random=1","asset_url":"https://picsum.photos/512/512?random=1","type":"txt2img","status":"SUCCEEDED","created_at":"2025-01-01T00:00:00.000Z","updated_at":"2025-01-01T00:00:00.000Z"},"\(genId2)":{"id":"\(genId2)","model_id":"mock-model-1","image_url":"https://picsum.photos/512/512?random=2","asset_url":"https://picsum.photos/512/512?random=2","type":"txt2img","status":"SUCCEEDED","created_at":"2025-01-01T00:00:00.000Z","updated_at":"2025-01-01T00:00:00.000Z"}}}}}
    """

    let msg2_3 = Message(
      serverId: "msg-2-3",
      threadId: thread2Id,
      role: .user,
      content: [.toolResult(ToolResultContent(
        toolUseId: "tool-use-1",
        content: [.text(TextContent(text: toolResultText))]
      ))],
      clientUuid: UUID().uuidString,
      order: 2,
      contextGenerationIds: nil,
      contextModelIds: nil,
      createdAt: now.addingTimeInterval(-7190)
    )

    let thread2 = Chat(
      clientUuid: thread2ClientUuid,
      id: thread2Id,
      summary: "Ocean sunset image generation",
      title: "Image Generation Demo",
      messages: [msg2_1, msg2_2, msg2_3],
      createdAt: now.addingTimeInterval(-7200),
      updatedAt: now.addingTimeInterval(-7190)
    )

    // Thread 3: Creative Writing
    let thread3Id = "mock-thread-3"
    let thread3ClientUuid = UUID().uuidString
    let msg3_1 = Message(
      serverId: "msg-3-1",
      threadId: thread3Id,
      role: .user,
      content: [.text(TextContent(text: "Write me a short poem about technology and nature"))],
      clientUuid: UUID().uuidString,
      order: 0,
      contextGenerationIds: nil,
      contextModelIds: nil,
      createdAt: now.addingTimeInterval(-1800)
    )

    let creativeWritingText = """
    {"type":"tool_result_data","tool_name":"creative_writing","data":{"message":"Here's your poem","result":{"creative_writing_output":{"type":"text","value":"Silicon Dreams in Emerald Streams\\n\\nBeneath the canopy of ancient oaks,\\nWhere fiber-optic roots entwine with soil,\\nThe digital and natural worlds converge—\\nA symphony of progress meeting earth.\\n\\nThe hummingbird hovers, algorithm-precise,\\nIts wings a blur of nature's engineering,\\nWhile satellites above trace silver arcs\\nAcross the same sky painted by the dawn.\\n\\nWe build our towers reaching for the clouds,\\nYet clouds were there before we learned to code.\\nIn every circuit board, a mineral's song;\\nIn every pixel, light that stars first spoke.","title":"Silicon Dreams in Emerald Streams"}}}}
    """

    let msg3_2 = Message(
      serverId: "msg-3-2",
      threadId: thread3Id,
      role: .user,
      content: [.toolResult(ToolResultContent(
        toolUseId: "tool-use-2",
        content: [.text(TextContent(text: creativeWritingText))]
      ))],
      clientUuid: UUID().uuidString,
      order: 1,
      contextGenerationIds: nil,
      contextModelIds: nil,
      createdAt: now.addingTimeInterval(-1790)
    )

    let thread3 = Chat(
      clientUuid: thread3ClientUuid,
      id: thread3Id,
      summary: "A poem about technology and nature",
      title: "Creative Writing",
      messages: [msg3_1, msg3_2],
      createdAt: now.addingTimeInterval(-1800),
      updatedAt: now.addingTimeInterval(-1790)
    )

    // Store all threads and messages
    threads[thread1Id] = thread1
    threads[thread2Id] = thread2
    threads[thread3Id] = thread3

    messageStore[thread1Id] = [msg1_1, msg1_2]
    messageStore[thread2Id] = [msg2_1, msg2_2, msg2_3]
    messageStore[thread3Id] = [msg3_1, msg3_2]
  }

  // MARK: - Socket Emits (Mock)

  func getThread(_ threadId: String) async throws -> Chat {
    guard let thread = threads[threadId] else {
      throw SocketError.missingData
    }
    return thread
  }

  func listThreads() async throws -> [Chat] {
    return Array(threads.values).sorted { $0.updatedAt > $1.updatedAt }
  }

  func loadThread(_ threadId: String) async throws -> Chat {
    return try await getThread(threadId)
  }

  func getMessages(threadId: String) async throws -> [Message] {
    return messageStore[threadId] ?? []
  }

  func createThread(_ thread: ClientThread, bypassLLM: Bool = false) async throws -> Chat {
    let threadId = "mock-thread-\(UUID().uuidString.prefix(8))"

    let messages = thread.messages.map { msg in
      Message(
        serverId: "msg-\(UUID().uuidString.prefix(8))",
        threadId: threadId,
        role: msg.role,
        content: msg.content,
        clientUuid: msg.clientUuid,
        order: msg.order,
        contextGenerationIds: msg.contextGenerationIds,
        contextModelIds: msg.contextModelIds,
        createdAt: msg.createdAt
      )
    }

    let firstMessageText = thread.messages.first.flatMap { msg -> String? in
      if case .text(let textContent) = msg.content.first {
        return String(textContent.text.prefix(40))
      }
      return nil
    } ?? "New Chat"

    let chat = Chat(
      clientUuid: thread.clientUuid,
      id: threadId,
      summary: firstMessageText,
      title: firstMessageText,
      messages: messages,
      createdAt: thread.createdAt,
      updatedAt: Date()
    )

    threads[threadId] = chat
    messageStore[threadId] = messages

    // Simulate assistant response
    if !bypassLLM {
      let userText = thread.messages.first.flatMap { msg -> String? in
        if case .text(let t) = msg.content.first { return t.text }
        return nil
      } ?? ""
      simulateAssistantResponse(threadId: threadId, chatClientUuid: thread.clientUuid, userText: userText)
    }

    return chat
  }

  func sendMessage(
    _ message: Message,
    threadId: String,
    bypassLLM: Bool = false
  ) async throws -> Message {
    let serverMessage = Message(
      serverId: "msg-\(UUID().uuidString.prefix(8))",
      threadId: threadId,
      role: message.role,
      content: message.content,
      clientUuid: message.clientUuid,
      order: message.order,
      contextGenerationIds: message.contextGenerationIds,
      contextModelIds: message.contextModelIds,
      createdAt: message.createdAt
    )

    // Store in memory
    var messages = messageStore[threadId] ?? []
    messages.append(serverMessage)
    messageStore[threadId] = messages

    // Simulate assistant response
    if !bypassLLM {
      let chatClientUuid = threads[threadId]?.clientUuid ?? ""
      let userText: String = {
        if case .text(let t) = message.content.first { return t.text }
        return ""
      }()
      simulateAssistantResponse(threadId: threadId, chatClientUuid: chatClientUuid, userText: userText)
    }

    return serverMessage
  }

  // MARK: - Mock Streaming

  private func simulateAssistantResponse(threadId: String, chatClientUuid: String, userText: String) {
    let wantsImage = userText.range(of: "image", options: .caseInsensitive) != nil

    let responseText = wantsImage
      ? "Sure! I'll generate some images for you based on your request."
      : (Self.mockResponses.randomElement() ?? "I'm here to help!")
    let words = responseText.split(separator: " ").map(String.init)
    let messageClientUuid = UUID().uuidString
    let messageServerId = "msg-\(UUID().uuidString.prefix(8))"
    let messageOrder = (messageStore[threadId]?.last?.order ?? 0) + 1

    Task { @MainActor [weak self] in
      guard let self = self else { return }

      // Wait before starting response
      try? await Task.sleep(nanoseconds: 500_000_000) // 0.5s

      // Stream text deltas word by word
      for (i, word) in words.enumerated() {
        let deltaText = (i == 0 ? "" : " ") + word
        let delta = MessageDelta(
          messageId: messageServerId,
          threadId: threadId,
          textDelta: deltaText,
          order: messageOrder,
          clientUuid: messageClientUuid,
          createdAt: Date()
        )
        self.interface.onAssistantMessageDelta(delta)
        try? await Task.sleep(nanoseconds: 80_000_000) // 0.08s
      }

      // Store the text message
      let completeMessage = Message(
        serverId: messageServerId,
        threadId: threadId,
        role: .assistant,
        content: [.text(TextContent(text: responseText))],
        clientUuid: messageClientUuid,
        order: messageOrder,
        contextGenerationIds: nil,
        contextModelIds: nil,
        createdAt: Date()
      )

      var messages = self.messageStore[threadId] ?? []
      messages.append(completeMessage)
      self.messageStore[threadId] = messages

      // If user asked for images, send a tool result with mock generations
      if wantsImage {
        try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s

        let genId1 = "mock-gen-\(UUID().uuidString.prefix(8))"
        let genId2 = "mock-gen-\(UUID().uuidString.prefix(8))"
        let randomSeed = Int.random(in: 100...999)

        let toolResultJSON = """
        {"type":"tool_result_data","tool_name":"image_generation","data":{"message":"Generated 2 images","result":{"prompt":"\(userText.replacingOccurrences(of: "\"", with: "\\\""))","image_count":2,"video_count":null,"aspect_ratio":"1:1","generation_ids":["\(genId1)","\(genId2)"],"generations":{"\(genId1)":{"id":"\(genId1)","model_id":"mock-model-1","image_url":"https://picsum.photos/512/512?random=\(randomSeed)","asset_url":"https://picsum.photos/512/512?random=\(randomSeed)","type":"txt2img","status":"SUCCEEDED","created_at":"2025-01-01T00:00:00.000Z","updated_at":"2025-01-01T00:00:00.000Z"},"\(genId2)":{"id":"\(genId2)","model_id":"mock-model-1","image_url":"https://picsum.photos/512/512?random=\(randomSeed + 1)","asset_url":"https://picsum.photos/512/512?random=\(randomSeed + 1)","type":"txt2img","status":"SUCCEEDED","created_at":"2025-01-01T00:00:00.000Z","updated_at":"2025-01-01T00:00:00.000Z"}}}}}
        """

        let toolResultOrder = messageOrder + 1
        let toolResultMessage = Message(
          serverId: "msg-\(UUID().uuidString.prefix(8))",
          threadId: threadId,
          role: .user,
          content: [.toolResult(ToolResultContent(
            toolUseId: "tool-use-\(UUID().uuidString.prefix(8))",
            content: [.text(TextContent(text: toolResultJSON))]
          ))],
          clientUuid: UUID().uuidString,
          order: toolResultOrder,
          contextGenerationIds: nil,
          contextModelIds: nil,
          createdAt: Date()
        )

        messages = self.messageStore[threadId] ?? []
        messages.append(toolResultMessage)
        self.messageStore[threadId] = messages

        self.interface.onMessageComplete(toolResultMessage)
      }

      self.interface.onAssistantDone()

      // Send thread update
      if let thread = self.threads[threadId] {
        let updatedThread = Chat(
          clientUuid: chatClientUuid,
          id: threadId,
          summary: thread.summary,
          title: thread.title,
          messages: thread.messages,
          createdAt: thread.createdAt,
          updatedAt: Date()
        )
        self.threads[threadId] = updatedThread
        self.interface.onThreadUpdated(updatedThread)
      }
    }
  }
}
