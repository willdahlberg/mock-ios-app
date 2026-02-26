import Foundation

@MainActor
class AssistantManager: ObservableObject {
  @Published private(set) var isConnected = false
  @Published private(set) var selectedChatUuid: String?
  @Published private(set) var chats: [Chat] = []
  @Published private(set) var isLoading = true

  private var socket: AssistantSocket?

  init(organizationId: String? = nil) {
    socket = AssistantSocket(interface: self, organizationId: organizationId)
  }

  // MARK: - Public Methods

  var selectedChat: Chat? {
    chats.first { $0.clientUuid == selectedChatUuid }
  }

  func select(chat: Chat?) {
    selectedChatUuid = chat?.clientUuid
  }

  func sendMessage(input: String, contextGenerationIds: [String]? = nil, contextModelIds: [String]? = nil, in clientId: String) async throws {
    guard let socket = socket else { throw ChatError.notConnected }
    if !chats.contains(where: { $0.clientUuid == clientId }) {
      startNewChat(clientId: UUID(uuidString: clientId))
    }

    guard let chatIndex = chats.firstIndex(where: { $0.clientUuid == clientId }) else {
      throw ChatError.noChatFound
    }
    
    guard !input.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw ChatError.emptyMessage
    }

    var chat = chats[chatIndex]

    let fileManager = FileUploadManager.shared
    try fileManager.validateUploads()

    let fileAttachments = fileManager.fileUploads.map { f in ContentType.image(ImageContent(url: URL(string: f.fileUrl!)!, mimetype: .jpeg, uploadToken: f.uploadToken)) }

    let messageOrder = (chat.messages.last?.order ?? -1) + 1

    let content = [.text(TextContent(text: input))] + fileAttachments

    let message = Message(
      serverId: nil,
      threadId: nil,
      role: .user,
      content: content,
      clientUuid: UUID().uuidString,
      order: messageOrder,
      contextGenerationIds: contextGenerationIds,
      contextModelIds: contextModelIds,
      createdAt: Date()
    )

    fileManager.clear()

    if let threadId = chat.id {
      // Add the local message right away
      chat.messages.append(message)
      chats[chatIndex] = chat

      // Normal message in existing chat
      let message = try await socket.sendMessage(message, threadId: threadId)

      // Now swap out with the server message
      var updatedMessages = chats[chatIndex].messages
      if let messageIndex = updatedMessages.firstIndex(where: { $0.clientUuid == message.clientUuid }) {
        updatedMessages[messageIndex] = message
      }

      chat.messages = updatedMessages
      chats[chatIndex] = chat
    } else {
      let clientThread = ClientThread(
        clientUuid: chat.clientUuid,
        messages: [message],
        createdAt: chat.createdAt
      )

      let createdChat = try await socket.createThread(clientThread)
      chats[chatIndex] = createdChat
    }
  }

  func loadChatHistory() async throws {
    print("load chat history")
    guard let socket = socket else { throw ChatError.notConnected }
    chats = try await socket.listThreads()
  }

  @discardableResult
  func startNewChat(clientId: UUID? = nil) -> Chat {
    if let pendingChat = chats.first(where: { $0.id == nil }) {
      return pendingChat
    }
    
    let clientUuid = clientId?.uuidString ?? UUID().uuidString

    let pendingChat = Chat(
      clientUuid: clientUuid,
      id: nil,
      summary: "New Chat",
      title: nil,
      messages: [],
      createdAt: Date(),
      updatedAt: Date()
    )

    chats.insert(pendingChat, at: 0)
    selectedChatUuid = clientUuid

    return pendingChat
  }

  func loadThread(_ id: String) async throws {
    guard let socket = socket else { throw ChatError.notConnected }

    let messages = try await socket.getMessages(threadId: id)

    if let index = chats.firstIndex(where: { $0.id == id }) {
      let oldChat = chats[index]
      chats[index] = Chat(
        clientUuid: oldChat.clientUuid,
        id: oldChat.id,
        summary: oldChat.summary,
        title: oldChat.title,
        messages: messages,
        createdAt: oldChat.createdAt,
        updatedAt: oldChat.updatedAt
      )
    }
  }

  // MARK: - Private Methods

  private func appendMessageDelta(_ delta: MessageDelta) {
    guard let chatIndex = chats.firstIndex(where: { $0.id == delta.threadId }) else { return }
    let chat = chats[chatIndex]
    var newMessages = chat.messages

    if let messageIndex = newMessages.firstIndex(where: { $0.clientUuid == delta.clientUuid }) {
      // Existing message case - append to it
      let message = newMessages[messageIndex]
      guard case .text(let content) = message.content.first else { return }

      var newMessage = Message(
        serverId: delta.messageId,
        threadId: delta.threadId,
        role: message.role,
        content: [.text(TextContent(text: content.text + delta.textDelta))],
        clientUuid: delta.clientUuid,
        order: delta.order,
        contextGenerationIds: message.contextGenerationIds,
        contextModelIds: message.contextModelIds,
        createdAt: delta.createdAt
      )

      newMessage.isStreaming = true

      newMessages[messageIndex] = newMessage
    } else {
      // New message case - create it
      var newMessage = Message(
        serverId: delta.messageId,
        threadId: delta.threadId,
        role: .assistant,
        content: [.text(TextContent(text: delta.textDelta))],
        clientUuid: delta.clientUuid,
        order: delta.order,
        contextGenerationIds: [],
        contextModelIds: [],
        createdAt: delta.createdAt
      )

      newMessage.isStreaming = true

      newMessages.append(newMessage)
    }

    chats[chatIndex] = Chat(
      clientUuid: chat.clientUuid,
      id: chat.id,
      summary: chat.summary,
      title: chat.title,
      messages: newMessages,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt
    )
  }

  private func sortChatsByDate() {
    chats.sort { $0.updatedAt > $1.updatedAt }
  }
}

// MARK: - ChatSocketInterface

extension AssistantManager: AssistantSocketInterface {
  func onConnect() {
    print("Chat socket connected.")
    isConnected = true
    isLoading = false

    Task {
      do {
        try await loadChatHistory()
      } catch {
        print("Failed to load chat history:", error)
      }
    }
  }

  func onDisconnect() {
    print("Chat socket disconnected")
    isConnected = false
  }

  func onAssistantMessageDelta(_ delta: MessageDelta) {
    print("onAssistantMessageDelta")
    appendMessageDelta(delta)
  }

  func onMessageComplete(_ message: Message) {
    var message = message
    if (message.role == .assistant) {
      message.isStreaming = true
    }

    print("onMessageComplete")
    guard let chatIndex = chats.firstIndex(where: { $0.id == message.threadId }) else { return }
    let chat = chats[chatIndex]

    var newMessages = chat.messages
    if let messageIndex = newMessages.firstIndex(where: { $0.clientUuid == message.clientUuid }) {
      newMessages[messageIndex] = message
    } else {
      newMessages.append(message)
    }

    chats[chatIndex] = Chat(
      clientUuid: chat.clientUuid,
      id: chat.id,
      summary: chat.summary,
      title: chat.title,
      messages: newMessages,
      createdAt: chat.createdAt,
      updatedAt: chat.updatedAt
    )
  }

  func onAssistantDone() {
  }

  func onThreadUpdated(_ thread: Chat) {
    print("onThreadUpdated", thread)
    if let index = chats.firstIndex(where: { $0.clientUuid == thread.clientUuid }) {
      chats[index] = Chat(
        clientUuid: thread.clientUuid,
        id: thread.id,
        summary: thread.summary,
        title: thread.title,
        messages: chats[index].messages.map({ m in  // Reset isStreaming
          var m = m
          m.isStreaming = false
          return m
        }),
        createdAt: thread.createdAt,
        updatedAt: thread.updatedAt
      )

      sortChatsByDate()
    }
  }

  func onAssistantMessageComplete() {
    print("onAssistantMessageComplete")
  }

  func onError(_ message: String, requiresReAuth: Bool = false) {
    print("Socket error:", message)
    if (requiresReAuth) {
      AuthenticationManager.shared.signOut()
    }
  }
}

enum ChatError: Error {
  case notConnected
  case emptyMessage
  case noChatFound
  case failedToLoadHistory
}
