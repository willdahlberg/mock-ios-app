//
//  ChatHistoryView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI

struct ChatHistoryView: View {
  @EnvironmentObject private var assistantManager: AssistantManager
  @EnvironmentObject private var authManager: AuthenticationManager
  @State private var path: [Chat] = []
  @State private var showUserProfile = false
  let inSplitView: Bool

  var body: some View {
    if !inSplitView {
      NavigationStack(path: $path) {
        chatList
          .navigationDestination(for: Chat.self) { chat in
            ChatView(chat: chat, assistantManager: assistantManager)
          }
      }
      .onChange(of: path) { _, newPath in
        if newPath.isEmpty {
          assistantManager.select(chat: nil)
        }
      }
      .onChange(of: assistantManager.selectedChat, initial: true) { _, newChat in
        if let chat = newChat {
          if !path.contains(where: { $0.clientUuid == chat.clientUuid }) {
            path.append(chat)
          }
        }
      }
    } else {
      chatList
    }
  }

  private var chatList: some View {
    List(assistantManager.chats) { chat in
      if !inSplitView {
        NavigationLink(value: chat) {
          ChatRowContent(chat: chat)
        }
      } else {
        Button {
          assistantManager.select(chat: chat)
        } label: {
          ChatRowContent(chat: chat)
        }
        .buttonStyle(.plain)
      }
    }
    .navigationTitle("Enzo")
    .navigationBarBackButtonHidden(false)
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarLeading) {
        Menu {
          Button {
            showUserProfile = true
          } label: {
            Label("User Profile", systemImage: "person.circle")
          }
          
          Button(action: authManager.signOut) {
            Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
          }
        } label: {
          Image(systemName: "ellipsis")
            .fontWeight(.medium)
        }
      }
      ToolbarItem(placement: .primaryAction) {
        HStack {
          Button {
            let chat = assistantManager.startNewChat()
            if !inSplitView {
              path.append(chat)
            }
          } label: {
            Image(systemName: "plus.message.fill")
              .fontWeight(.medium)
              .dynamicGradient(.accent, .white)
          }
        }
      }
    }
    .sheet(isPresented: $showUserProfile) {
      UserProfileView()
    }
  }
}

struct ChatRowContent: View {
  let chat: Chat

  var isPending: Bool {
    chat.id == nil
  }

  var displayTitle: String {
    if isPending {
      return "New Chat"
    }
    return chat.title ?? chat.summary
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(displayTitle)
        .font(.headline)
        .foregroundColor(isPending ? .secondary : .primary)

      HStack {
        if isPending {
          Text("Draft")
            .font(.caption)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(Color.secondary.opacity(0.2))
            .cornerRadius(4)
        }

        Text(chat.updatedAt.formatted(date: .abbreviated, time: .shortened))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding(.vertical, 4)
    .opacity(isPending ? 0.8 : 1.0)
  }
}
