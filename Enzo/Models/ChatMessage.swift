//
//  ChatMessage.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import Foundation

struct ChatMessage: Identifiable {
  let id: UUID
  let content: String
  let isUser: Bool
  var images: [String]?
}
