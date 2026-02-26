//
//  MainContainerView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-31.
//

import SwiftUI

struct MainContainerView: View {
  let horizontalSizeClass: UserInterfaceSizeClass
  @EnvironmentObject private var assistantManager: AssistantManager

  var body: some View {
    Group {
      if horizontalSizeClass == .compact {
        ChatHistoryView(inSplitView: false)
      } else {
        NavigationSplitView {
          ChatHistoryView(inSplitView: true)
        } detail: {
          ChatContentView()
        }
      }
    }
  }
}

struct ChatContentView: View {
  @EnvironmentObject private var assistantManager: AssistantManager

  var body: some View {
    if let selectedChat = assistantManager.chats.first(where: { $0.clientUuid == assistantManager.selectedChatUuid }) {
      ChatView(chat: selectedChat, assistantManager: assistantManager)
        .id(selectedChat.clientUuid)
    } else {
      Text("Select a chat")
        .foregroundStyle(.secondary)
    }
  }
}

struct ChatDetailView: View {
  @EnvironmentObject private var assistantManager: AssistantManager

  var body: some View {
    if let selectedChat = assistantManager.chats.first(where: { $0.clientUuid == assistantManager.selectedChatUuid }) {
      ActionHistoryView(chat: Chat(
        clientUuid: selectedChat.clientUuid,
        id: selectedChat.id,
        summary: selectedChat.summary,
        title: selectedChat.title,
        messages: selectedChat.messages,
        createdAt: selectedChat.createdAt,
        updatedAt: selectedChat.updatedAt
      ))
    } else {
      Text("Select a chat to view actions")
        .foregroundStyle(.secondary)
    }
  }
}
