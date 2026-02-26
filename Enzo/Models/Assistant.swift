import Foundation

protocol RemoteAsset: Identifiable {
  var id: String { get }
  var imageUrl: String? { get }
  var assetUrl: String? { get }
}

enum MessageRole: String, Codable {
  case user
  case assistant
}

enum ImageMimeType: String, Codable {
  case jpeg = "image/jpeg"
  case png = "image/png"
}

struct TextContent: Codable, Hashable, CustomStringConvertible {
  let type: String
  let text: String

  var description: String { text }

  init(text: String) {
    self.type = "text"
    self.text = text
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    type = try container.decode(String.self, forKey: .type)
    let rawText = try container.decode(String.self, forKey: .text)
    text = rawText.trimmingCharacters(in: .whitespacesAndNewlines)
  }
}

struct ImageContent: Codable, Hashable {
  let type: String
  let url: URL
  let mimetype: ImageMimeType
  let uploadToken: String?

  init(url: URL, mimetype: ImageMimeType, uploadToken: String? = nil) {
    self.type = "image"
    self.url = url
    self.mimetype = mimetype
    self.uploadToken = uploadToken
  }
}

struct ToolUseContent: Codable, Hashable {
  let type: String
  let id: String
  let name: String
  let input: AnyCodable

  init(id: String, name: String, input: AnyCodable) {
    self.type = "tool_use"
    self.id = id
    self.name = name
    self.input = input
  }
}

struct ToolResultContent: Codable, Hashable {
  let type: String
  let toolUseId: String
  let content: [ContentType]

  init(toolUseId: String, content: [ContentType]) {
    self.type = "tool_result"
    self.toolUseId = toolUseId
    self.content = content
  }
}

enum ContentType: Codable, Hashable {
  case text(TextContent)
  case image(ImageContent)
  case toolUse(ToolUseContent)
  case toolResult(ToolResultContent)

  // Synthesized
  case toolWork(ImageGenerationOutput)
  case generations(FetchGenerationsOutput)
  case models(FetchModelsOutput)

  private enum CodingKeys: String, CodingKey {
    case type
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    let type = try container.decode(String.self, forKey: .type)

    switch type {
    case "text":
      self = .text(try TextContent(from: decoder))
    case "image":
      self = .image(try ImageContent(from: decoder))
    case "tool_use":
      self = .toolUse(try ToolUseContent(from: decoder))
    case "tool_result":
      self = .toolResult(try ToolResultContent(from: decoder))
    default:
      throw DecodingError.dataCorruptedError(forKey: .type, in: container, debugDescription: "Invalid type")
    }
  }

  func encode(to encoder: Encoder) throws {
    switch self {
    case .text(let content):
      try content.encode(to: encoder)
    case .image(let content):
      try content.encode(to: encoder)
    case .toolUse(let content):
      try content.encode(to: encoder)
    case .toolResult(let content):
      try content.encode(to: encoder)
    default:
      throw EncodingError.invalidValue(self, EncodingError.Context(codingPath: [self.hashValue.codingKey], debugDescription: "Can't encode synthesized value \(self)"))
    }
  }
}

struct Message: Codable, Hashable, Identifiable {
  let serverId: String?
  let threadId: String?
  let role: MessageRole
  let content: [ContentType]
  let clientUuid: String
  let order: Int
  let contextGenerationIds: [String]?
  let contextModelIds: [String]?
  let createdAt: Date

  // Identifiable
  var id: String { clientUuid }

  // Extensions
  var isStreaming: Bool?

  enum CodingKeys: String, CodingKey {
    case serverId = "id"
    case threadId, role, content, clientUuid, order,
         contextGenerationIds, contextModelIds, createdAt
  }

  static func == (lhs: Message, rhs: Message) -> Bool {
    return lhs.clientUuid == rhs.clientUuid && lhs.content == rhs.content
  }
}

struct MessageDelta: Codable, Hashable {
  let messageId: String
  let threadId: String
  let textDelta: String
  let order: Int
  let clientUuid: String
  let createdAt: Date
}

struct ClientThread: Codable {
  let clientUuid: String
  let messages: [Message]
  let createdAt: Date
}

struct Chat: Codable, Hashable, Identifiable {
  let clientUuid: String
  let id: String? // nil means isn't created on the backend yet
  let summary: String
  let title: String?
  var messages: [Message]
  let createdAt: Date
  let updatedAt: Date

  static func == (lhs: Chat, rhs: Chat) -> Bool {
    return lhs.clientUuid == rhs.clientUuid && lhs.title == rhs.title && lhs.summary == rhs.summary
  }
}

enum ToolName: String, Codable {
  case externalGeneration = "external_generation"
  case imageGeneration = "image_generation"
  case videoGeneration = "video_generation"
  case fetchGenerations = "fetch_generations"
  case fetchModels = "fetch_models"
  case creativeWriting = "creative_writing"
  case modelTraining = "model_training"
  case freeformEdit = "freeform_edit"
  case upscale = "upscale"
  case outpaint = "outpaint"
  case backgroundRemoval = "background_removal"
  case backgroundRestyle = "background_restyle"
}

struct ToolResultData: Codable {
  let type: String
  let toolName: ToolName
  let data: ToolResultDataContent

  init(toolName: ToolName, data: ToolResultDataContent) {
    self.type = "tool_result_data"
    self.toolName = toolName
    self.data = data
  }
}

struct ToolResultDataContent: Codable {
  let message: String
  let result: AnyCodable
}

struct ToolResultError: Codable {
  let type: String
  let toolName: ToolName
  let data: ToolResultErrorData

  init(toolName: ToolName, data: ToolResultErrorData) {
    self.type = "tool_result_error"
    self.toolName = toolName
    self.data = data
  }
}

struct ToolResultErrorData: Codable {
  let message: String
}

enum AspectRatio: String, Codable {
  case square = "1:1"
  case portrait = "3:4"
  case landscape = "4:3"
  case vertical = "9:16"
  case horizontal = "16:9"
  case panoramic = "5:1"
  case cinematic = "1.91:1"
  case instagram = "4:5"
}

struct Generation: Codable, Hashable, Identifiable, RemoteAsset {
  let id: String
  let modelId: String?
  let imageUrl: String?
  let assetUrl: String?
  let type: GenerationType
  let status: PredictionStatus
  let createdAt: String
  let updatedAt: String
}

enum GenerationType: String, Codable {
  case txt2img
  case img2img
  case upscale
  case backgroundRemoval
  case backgroundRestyle
  case replaceElement
  case imageToVideo
  case enhanceFace
  case magicEdit
  case transform
  case replaceText
  case imageTo3d
  case mixedLora
  case videoAudioSynthesis
  case outpaint
  case videoStitch
  case txt2svg
  case adsCreation
  case upscaleGan
  case controlNet
  case freeformEdit

  var queryType: TrainedModelQueryType {
    switch self {
    case .txt2img:
      return .txt2img
    case .img2img:
      return .img2img
    case .imageToVideo:
      return .imageToVideo
    case .backgroundRestyle:
      return .backgroundRestyle
    case .backgroundRemoval:
      return .backgroundRemoval
    case .outpaint:
      return .outpaint
    case .upscale:
      return .upscale
    case .replaceElement:
      return .replaceElement
    case .enhanceFace:
      return .enhanceFace
    case .magicEdit:
      return .magicEdit
    case .transform:
      return .transform
    case .replaceText:
      return .replaceText
    case .imageTo3d:
      return .imageTo3d
    case .mixedLora:
      return .mixedLora
    case .videoAudioSynthesis:
      return .videoAudioSynthesis
    case .videoStitch:
      return .videoStitch
    case .txt2svg:
      return .txt2svg
    case .adsCreation:
      return .adsCreation
    case .upscaleGan:
      return .upscaleGan
    case .controlNet:
      return .controlNet
    case .freeformEdit:
      return .freeformEdit
    }
  }
}

struct GenerationsOutput: Codable {
  let type: Int?
  let generationIds: [String]
  let generations: [String: Generation]
}

struct FetchModelsOutput: Codable, Hashable {
  let models: [Model]
}

struct Model: Codable, Hashable {
  let id: String
  let name: String
  let description: String?
  let status: String
}

struct FetchGenerationsOutput: Codable, Hashable {
  let generations: [GenerationOutput]
}

struct GenerationOutput: Codable, Hashable {
  let id: String
  let status: String
  let url: String?
}

struct ModelTrainingOutput: Codable {
  let model: TrainingModel
}

struct TrainingModel: Codable {
  let id: String
  let name: String
}

struct ImageGenerationOutput: Codable, Hashable {
  let prompt: String?
  let imageCount: Int?
  let videoCount: Int?
  let aspectRatio: AspectRatio?
  let generationIds: [String]
  var generations: [String: Generation]?
}

struct CreativeWritingOutput: Codable {
  let creativeWritingOutput: CreativeWritingContent

  enum CodingKeys: String, CodingKey {
    case creativeWritingOutput
  }
}

struct CreativeWritingContent: Codable {
  let type: CreativeWritingType
  let value: String
  let title: String?
}

enum CreativeWritingType: String, Codable {
  case text
  case markdown
}

struct FreeformEditInput: Codable {
  let prompt: String
}

struct OutpaintInput: Codable {
  let prompt: String
  let aspectRatio: AspectRatio
}

struct BackgroundRestyleInput: Codable {
  let prompt: String
}

// Helper type to handle arbitrary JSON values
struct AnyCodable: Codable, Hashable {
  static func == (lhs: AnyCodable, rhs: AnyCodable) -> Bool {
    switch (lhs.value, rhs.value) {
    case is (NSNull, NSNull):
      return true
    case let (lhs as Bool, rhs as Bool):
      return lhs == rhs
    case let (lhs as Int, rhs as Int):
      return lhs == rhs
    case let (lhs as Double, rhs as Double):
      return lhs == rhs
    case let (lhs as String, rhs as String):
      return lhs == rhs
    case let (lhs as [Any], rhs as [Any]):
      return (lhs as NSArray).isEqual(to: rhs)
    case let (lhs as [String: Any], rhs as [String: Any]):
      return (lhs as NSDictionary).isEqual(to: rhs)
    default:
      return false
    }
  }

  func hash(into hasher: inout Hasher) {
    switch value {
    case is NSNull:
      hasher.combine(0)
    case let value as Bool:
      hasher.combine(value)
    case let value as Int:
      hasher.combine(value)
    case let value as Double:
      hasher.combine(value)
    case let value as String:
      hasher.combine(value)
    case let value as [Any]:
      hasher.combine((value as NSArray).description)
    case let value as [String: Any]:
      hasher.combine((value as NSDictionary).description)
    default:
      hasher.combine(0)
    }
  }
  let value: Any

  init(_ value: Any) {
    self.value = value
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    if container.decodeNil() {
      value = NSNull()
    } else if let bool = try? container.decode(Bool.self) {
      value = bool
    } else if let int = try? container.decode(Int.self) {
      value = int
    } else if let double = try? container.decode(Double.self) {
      value = double
    } else if let string = try? container.decode(String.self) {
      value = string
    } else if let array = try? container.decode([AnyCodable].self) {
      value = array.map { $0.value }
    } else if let dictionary = try? container.decode([String: AnyCodable].self) {
      value = dictionary.mapValues { $0.value }
    } else {
      throw DecodingError.dataCorruptedError(in: container, debugDescription: "AnyCodable value cannot be decoded")
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    switch value {
    case is NSNull:
      try container.encodeNil()
    case let bool as Bool:
      try container.encode(bool)
    case let int as Int:
      try container.encode(int)
    case let double as Double:
      try container.encode(double)
    case let string as String:
      try container.encode(string)
    case let array as [Any]:
      try container.encode(array.map { AnyCodable($0) })
    case let dictionary as [String: Any]:
      try container.encode(dictionary.mapValues { AnyCodable($0) })
    default:
      throw EncodingError.invalidValue(value, EncodingError.Context(codingPath: container.codingPath, debugDescription: "AnyCodable value cannot be encoded"))
    }
  }
}

// Tool Use types
protocol ToolUseProtocol {
  var id: String { get }
  var order: Int { get }
  var name: String { get }
}

struct ToolUse: Codable, ToolUseProtocol {
  let id: String
  let order: Int
  let name: String
  let input: AnyCodable?
}

struct ToolUsePair: Codable {
  let order: Int
  let toolUse: ToolUse
  let toolResult: ToolResult?
  let toolError: ToolResultError?
}

struct ToolResult: Codable {
  let data: ToolResultData
}

struct ContentGroup: Codable {
  let role: MessageRole
  let content: [ContentType]
}
