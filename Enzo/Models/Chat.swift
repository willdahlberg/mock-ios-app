//
//  Chat.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//
/*
import Foundation

struct Chat: Identifiable, Codable, Hashable {
  let id: String
  let summary: String?
  var title: String?
  var messages: [Message]
  let createdAt: Date
  let updatedAt: Date
  let clientUuid: String

  init(id: String = generateBigIntId(),
       summary: String?,
       title: String?,
       messages: [Message],
       createdAt: Date,
       updatedAt: Date,
       clientUuid: String = UUID().uuidString) {
    self.id = id
    self.summary = summary
    self.title = title
    self.messages = messages
    self.createdAt = createdAt
    self.updatedAt = updatedAt
    self.clientUuid = clientUuid
  }

  static func == (lhs: Chat, rhs: Chat) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

struct Message: Identifiable, Codable, Hashable {
  let id: String
  var content: [MessageContent]
  let role: MessageRole
  let order: Int
  let createdAt: Date
  let clientUuid: String
  // New API fields as optional
  let contextGenerationIds: [String]?
  let contextModelIds: [String]?
  let threadId: String?

  init(id: String = generateBigIntId(),
       content: [MessageContent],
       role: MessageRole,
       order: Int,
       createdAt: Date,
       clientUuid: String = UUID().uuidString,
       contextGenerationIds: [String]? = nil,
       contextModelIds: [String]? = nil,
       threadId: String? = nil) {
    self.id = id
    self.content = content
    self.role = role
    self.order = order
    self.createdAt = createdAt
    self.clientUuid = clientUuid
    self.contextGenerationIds = contextGenerationIds
    self.contextModelIds = contextModelIds
    self.threadId = threadId
  }

  static func == (lhs: Message, rhs: Message) -> Bool {
    lhs.id == rhs.id
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }
}

enum MessageContent: Codable {
  case text(String)
  case image(url: URL, mimeType: String)
  case toolUse(id: String, name: String, input: [String: CustomStringConvertible])
  case toolResult(toolUseId: String, content: [MessageContent])

  private enum CodingKeys: String, CodingKey {
    case type, text, url, mimeType, id, name, input, toolUseId = "tool_use_id", content
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch self {
    case .text(let content):
      try container.encode("text", forKey: .type)
      try container.encode(content, forKey: .text)

    case .image(let url, let mimeType):
      try container.encode("image", forKey: .type)
      try container.encode(url, forKey: .url)
      try container.encode(mimeType, forKey: .mimeType)

    case .toolUse(let id, let name, let input):
      try container.encode("tool_use", forKey: .type)
      try container.encode(id, forKey: .id)
      try container.encode(name, forKey: .name)

      // Encode input dictionary by converting values to their string representation
      let stringInput = input.mapValues { value in
        String(describing: value)
      }
      try container.encode(stringInput, forKey: .input)

    case .toolResult(let toolUseId, let content):
      try container.encode("tool_result", forKey: .type)
      try container.encode(toolUseId, forKey: .toolUseId)
      try container.encode(content, forKey: .content)
    }
  }

  init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: CodingKeys.self)
      let type = try container.decode(String.self, forKey: .type)
      print("Decoding content type:", type) // Debug print

      switch type {
      case "text":
          let text = try container.decode(String.self, forKey: .text)
          self = .text(text)

      case "image":
          let url = try container.decode(URL.self, forKey: .url)
          let mimeType = try container.decode(String.self, forKey: .mimeType)
          self = .image(url: url, mimeType: mimeType)

      case "tool_use":
          let id = try container.decode(String.self, forKey: .id)
          let name = try container.decode(String.self, forKey: .name)
          print("Decoding tool use with id:", id) // Debug print
          let inputContainer = try container.decode([String: CustomStringConvertibleValue].self, forKey: .input)
          let input = inputContainer.mapValues { $0.value }
          self = .toolUse(id: id, name: name, input: input)

      case "tool_result":
          print("Attempting to decode tool_result")
          // Just decode as text and dump everything else
          if let content = try? container.decode([MessageContent].self, forKey: .content),
             let firstContent = content.first,
             case let .text(text) = firstContent {
              print("Found text content in tool result:", text)
              self = .text("Tool Result: " + text)
          } else {
              // Fallback - create a dummy text content
              self = .text("Failed to decode tool result")
          }

      default:
          throw DecodingError.dataCorruptedError(
              forKey: .type,
              in: container,
              debugDescription: "Unknown message content type: \(type)"
          )
      }
  }
}

// Helper type to decode values that conform to CustomStringConvertible
struct CustomStringConvertibleValue: Codable {
  let value: CustomStringConvertible

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let stringValue = try? container.decode(String.self) {
      value = stringValue
    } else if let intValue = try? container.decode(Int.self) {
      value = intValue
    } else if let doubleValue = try? container.decode(Double.self) {
      value = doubleValue
    } else if let boolValue = try? container.decode(Bool.self) {
      value = boolValue
    } else {
      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Value is not a supported CustomStringConvertible type"
      )
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()

    switch value {
    case let stringValue as String:
      try container.encode(stringValue)
    case let intValue as Int:
      try container.encode(intValue)
    case let doubleValue as Double:
      try container.encode(doubleValue)
    case let boolValue as Bool:
      try container.encode(boolValue)
    default:
      try container.encode(String(describing: value))
    }
  }
}

enum MessageRole: String, Codable {
  case user
  case assistant
}

struct MessageDelta {
  let messageId: String
  let text: String
  let order: Int
  let threadId: String
  //    let clientUuid: String
  let createdAt: Date
}
*/
