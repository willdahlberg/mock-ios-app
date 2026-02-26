//
//  MessageRow.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI
import Nuke
import NukeUI
import NukeVideo

struct MessageRow: View {
  let message: Message

  var body: some View {
    HStack {
      if message.role == .user {
        Spacer()
      }

      MessageContent(message: message)

      if message.role != .user {
        Spacer()
      }
    }
    .padding(.horizontal)
    .padding(.vertical, 4)
  }
}

struct MessageContent: View {
  let message: Message

  var body: some View {
    VStack(alignment: message.role == .user ? .trailing : .leading, spacing: 4) {
        ForEach(Array(message.content.enumerated()), id: \.offset) { _, content in
          MessageContentView(content: content, role: message.role, isStreaming: message.isStreaming ?? false)
        }
    }
  }
}

struct MessageContentView: View {
  let content: ContentType
  let role: MessageRole
  let isStreaming: Bool

  var body: some View {
    Group {
      switch content {
      case .text(let textContent):
        TextContentView(text: textContent.text, role: role, isStreaming: isStreaming)
      case .image(let imageContent):
        ImageContentView(imageContent: imageContent)
      case .toolUse(let toolContent):
        EmptyView()
        //ToolUseContentView(toolContent: toolContent)
      case .toolResult(let resultContent):
        ToolResultContentView(resultContent: resultContent)
      case .toolWork(let imageGenOutput):
        ToolWorkContentView(imageGenOutput: imageGenOutput)
      case .generations(let generationsOutput):
        GenerationsContentView(generationsOutput: generationsOutput)
      case .models(_):
        ZStack {
          HStack(spacing: 4) {
            Text("Gathered Models")
              .font(.callout)
              .italic()
            Image(systemName: "wrench.adjustable.fill")
          }
          .foregroundColor(.secondary)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
  }
}

struct TextContentView: View {
  let text: String
  let role: MessageRole
  let isStreaming: Bool
  
  var body: some View {
    if isStreaming {
      // Use regular streaming for streaming text
      streamingText(text, mode: .character)
        .textSelection(.enabled)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
          if role == .user {
            RoundedRectangle(cornerRadius: 16)
              .dynamicGradient(.accent)
          } else {
            RoundedRectangle(cornerRadius: 16)
              .fill(Color(.secondarySystemBackground))
          }
        }
        .foregroundColor(role == .user ? .white : .primary)
    } else {
      // Use Text with AttributedString for non-streaming text
      Text(makeAttributedString())
        .textSelection(.enabled)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background {
          if role == .user {
            RoundedRectangle(cornerRadius: 16)
              .dynamicGradient(.accent)
          } else {
            RoundedRectangle(cornerRadius: 16)
              .fill(Color(.secondarySystemBackground))
          }
        }
        .foregroundColor(role == .user ? .white : .primary)
    }
  }
  
  private func makeAttributedString() -> AttributedString {
    var attributedString = AttributedString(text)
    
    // Match URLs in the text
    do {
      let detector = try NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
      let matches = detector.matches(in: text, options: [], range: NSRange(location: 0, length: text.utf16.count))
      
      for match in matches {
        if let url = match.url, let range = Range(match.range, in: text) {
          let stringToReplace = String(text[range])
          if let rangeInAttributed = attributedString.range(of: stringToReplace) {
            attributedString[rangeInAttributed].link = url
            attributedString[rangeInAttributed].underlineStyle = .single
            // Keep the foreground color consistent with the role
            if role != .user {
              attributedString[rangeInAttributed].foregroundColor = .accent
            }
          }
        }
      }
    } catch {
      print("Error detecting URLs: \(error)")
    }
    
    return attributedString
  }
}

struct ImageContentView: View {
  let imageContent: ImageContent
  
  var body: some View {
    LazyImage(url: imageContent.url) { state in
      if let image = state.image {
        image
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: 150, height: 150)
          .clipShape(RoundedRectangle(cornerRadius: 16))
      } else if state.isLoading {
        ProgressView()
          .frame(width: 150, height: 150)
      }
    }
  }
}

struct ToolUseContentView: View {
  let toolContent: ToolUseContent

  var body: some View {
    VStack(alignment: .leading, spacing: 4) {
      HStack {
        //        RotatingCog()
        Text(toolContent.name)
          .font(.caption)
          .foregroundColor(.gray)
      }

      if let inputDict = toolContent.input.value as? [String: Any] {
        ToolInputView(inputDict: inputDict)
      }
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 8)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

struct ToolInputView: View {
  let inputDict: [String: Any]

  var body: some View {
    VStack(alignment: .leading, spacing: 2) {
      ForEach(Array(inputDict.keys.sorted()), id: \.self) { key in
        if let value = inputDict[key] {
          Text("\(key): \(String(describing: value))")
            .font(.caption2)
            .foregroundColor(.secondary)
        }
      }
    }
  }
}

struct ToolWorkContentView: View {
  let imageGenOutput: ImageGenerationOutput

  var body: some View {
    ZStack {
      if let generations = imageGenOutput.generations, generations.values.allSatisfy({ $0.status == .failed }) {
        HStack(spacing: 4) {
          Text("Generation Failed")
            .font(.callout)
            .italic()
          Image(systemName: "exclamationmark.triangle.fill")
        }
        .foregroundColor(.secondary)
      } else {
        FullscreenViewerContainer { state in
          FittingWidthLayout {
            ScrollView(.horizontal, showsIndicators: false) {
              HStack {
                ForEach(Array(imageGenOutput.generationIds), id: \.self) { generationId in
                  if let generation = imageGenOutput.generations?[generationId] {
                    if let imageUrl = generation.imageUrl, let url = URL(string: imageUrl) {
                      GenerationImageView(
                        generation: generation,
                        url: url,
                        viewerState: state,
                        processors: [ImageProcessors.Resize.thumbnail]
                      )
                    }
                  } else {
                    ProgressView()
                      .frame(width: 150, height: 150)
                      .background(Color(.secondarySystemFill))
                      .clipShape(RoundedRectangle(cornerRadius: 8))
                  }
                }
              }
            }
            .scrollClipDisabled(true)
          }
        }
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 10)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

struct GenerationImageView: View {
  let generation: Generation
  let url: URL
  let viewerState: FullscreenViewerState
  let request: ImageRequest

  init(
    generation: Generation,
    url: URL,
    viewerState: FullscreenViewerState,
    processors: [any ImageProcessing] = []
  ) {
    self.generation = generation
    self.url = url
    self.viewerState = viewerState
    request = ImageRequest(url: url, processors: processors)
  }

  var body: some View {
    ZStack {
      if url.pathExtension == "mp4" {
        VideoPlayer(url: url)
          .frame(width: 150, height: 150)
          .clipShape(RoundedRectangle(cornerRadius: 8))
          .zoomable(
            asset: generation,
            state: viewerState
          )
      } else {
        LazyImage(request: request) { state in
          if let image = state.image {
            image
              .resizable()
              .aspectRatio(contentMode: .fill)
              .clipShape(RoundedRectangle(cornerRadius: 8))
              .zoomable(
                asset: generation,
                state: viewerState
              )
              .contextMenu {
                ImageContextMenu(generation: generation, image: image, originalImage: request.cachedOriginal)
              }
          } else if state.error != nil {
            Image(systemName: "photo")
          } else {
            ProgressView()
          }
        }
        .frame(width: 150, height: 150)
        .background(Color(.secondarySystemFill))
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
  }
}

struct ImageContextMenu: View {
  let generation: Generation
  let image: Image
  let originalImage: UIImage
  @Environment(\.onUseGeneration) var onUseGeneration: (Generation, Image) -> Void

  var body: some View {
    Button {
      onUseGeneration(generation, image)
    } label: {
      Label("Use Image", systemImage: "apple.image.playground")
    }

//    Button {
//    } label: {
//      Label("Upscale", systemImage: "rectangle.expand.diagonal")
//    }

    Divider()

    Button {
      let activityVC = UIActivityViewController(
        activityItems: [originalImage],
        applicationActivities: nil
      )
      if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
         let window = windowScene.windows.first {
        window.rootViewController?.present(activityVC, animated: true)
      }
    } label: {
      Label("Share", systemImage: "square.and.arrow.up")
    }

    Button {
      UIImageWriteToSavedPhotosAlbum(originalImage, nil, nil, nil)
    } label: {
      Label("Save to Photos", systemImage: "square.and.arrow.down")
    }

    Button {
      UIPasteboard.general.image = originalImage
    } label: {
      Label("Copy", systemImage: "doc.on.doc")
    }
  }
}

struct GenerationsContentView: View {
  let generationsOutput: FetchGenerationsOutput

  var body: some View {
    FittingWidthLayout {
      ScrollView(.horizontal, showsIndicators: false) {
        HStack {
          ForEach(generationsOutput.generations, id: \.self) { generation in
            if let imageUrl = generation.url {
              AsyncImage(url: URL(string: imageUrl)) { phase in
                switch phase {
                case .success(let image):
                  image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                case .failure(_):
                  Image(systemName: "photo")
                case .empty:
                  ProgressView()
                @unknown default:
                  EmptyView()
                }
              }
              .frame(width: 150, height: 150)
              .background(Color(.secondarySystemFill))
              .clipShape(RoundedRectangle(cornerRadius: 8))
            }
          }
        }
      }
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 10)
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}

struct ToolResultContentView: View {
  let resultContent: ToolResultContent

  var body: some View {
    ForEach(resultContent.content.indices, id: \.self) { index in
      if case .text(let textContent) = resultContent.content[index] {
        Text(textContent.text)
          .textSelection(.enabled)
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }
    }
  }
}

struct RotatingCog: View {
  var body: some View {
    TimelineView(.animation(minimumInterval: 1/60, paused: false)) { timeline in
      Image(systemName: "gear")
        .foregroundColor(.gray)
        .rotationEffect(Angle(degrees: timeline.date.timeIntervalSinceReferenceDate * 180))
    }
  }
}

#Preview {
  // Create mock data for each message type
  ScrollView {
    VStack {
      // Regular text messages (user and assistant)
      MessageRow(message: Message(
        serverId: "1",
        threadId: "thread123",
        role: .user,
        content: [
          .text(TextContent(text: "Hello, can you help me with something?"))
        ],
        clientUuid: "client123",
        order: 1,
        contextGenerationIds: nil,
        contextModelIds: nil,
        createdAt: Date()
      ))

      MessageRow(message: Message(
        serverId: "2",
        threadId: "thread123",
        role: .assistant,
        content: [
          .text(TextContent(text: "Of course! What can I help you with today?"))
        ],
        clientUuid: "client123",
        order: 2,
        contextGenerationIds: nil,
        contextModelIds: nil,
        createdAt: Date()
      ))

      // Streaming text message
      MessageRow(message: Message(
        serverId: "3",
        threadId: "thread123",
        role: .assistant,
        content: [
          .text(TextContent(text: "I'm generating a response..."))
        ],
        clientUuid: "client123",
        order: 3,
        contextGenerationIds: nil,
        contextModelIds: nil,
        createdAt: Date(),
        isStreaming: true
      ))

      // Message with image
      MessageRow(message: Message(
        serverId: "4",
        threadId: "thread123",
        role: .user,
        content: [
          .text(TextContent(text: "What do you think of this image?")),
          .image(ImageContent(
            url: URL(string: "https://picsum.photos/id/237/200/300")!,
            mimetype: .jpeg,
            uploadToken: nil
          ))
        ],
        clientUuid: "client123",
        order: 4,
        contextGenerationIds: nil,
        contextModelIds: nil,
        createdAt: Date()
      ))

      // Message with tool result
      MessageRow(message: Message(
        serverId: "5",
        threadId: "thread123",
        role: .assistant,
        content: [
          .text(TextContent(text: "I've analyzed the data:")),
          .toolResult(ToolResultContent(
            toolUseId: "tool-1",
            content: [
              .text(TextContent(text: "Analysis complete. Found 3 anomalies in the dataset."))
            ]
          ))
        ],
        clientUuid: "client123",
        order: 5,
        contextGenerationIds: nil,
        contextModelIds: nil,
        createdAt: Date()
      ))

      // Message with tool work (image generation)
      MessageRow(message: Message(
        serverId: "6",
        threadId: "thread123",
        role: .assistant,
        content: [
          .text(TextContent(text: "Here are some generated images based on your request:")),
          .toolWork(ImageGenerationOutput(
            prompt: "Nature scenes",
            imageCount: 2,
            videoCount: 0,
            aspectRatio: .landscape,
            generationIds: ["gen1", "gen2", "gen3"],
            generations: [
              "gen1": Generation(
                id: "gen1",
                modelId: "model-xyz",
                imageUrl: "https://picsum.photos/id/29/200/300",
                assetUrl: "https://picsum.photos/id/29/200/300",
                type: .txt2img,
                status: .succeeded,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
              ),
              "gen2": Generation(
                id: "gen2",
                modelId: "model-xyz",
                imageUrl: "https://picsum.photos/id/37/200/300",
                assetUrl: "https://picsum.photos/id/37/200/300",
                type: .txt2img,
                status: .succeeded,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
              ),
              "gen3": Generation(
                id: "gen3",
                modelId: "model-xyz",
                imageUrl: "https://picsum.photos/id/37/200/300",
                assetUrl: "https://picsum.photos/id/37/200/300",
                type: .txt2img,
                status: .succeeded,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
              )
            ]
          ))
        ],
        clientUuid: "client123",
        order: 6,
        contextGenerationIds: ["gen1", "gen2"],
        contextModelIds: ["model-xyz"],
        createdAt: Date()
      ))

      // Failed tool work (image generation)
      MessageRow(message: Message(
        serverId: "9",
        threadId: "thread123",
        role: .assistant,
        content: [
          .text(TextContent(text: "These ones failed:")),
          .toolWork(ImageGenerationOutput(
            prompt: "Nature scenes",
            imageCount: 1,
            videoCount: 0,
            aspectRatio: .landscape,
            generationIds: ["gen1"],
            generations: [
              "gen1": Generation(
                id: "gen1",
                modelId: "model-xyz",
                imageUrl: "https://picsum.photos/id/29/200/300",
                assetUrl: "https://picsum.photos/id/29/200/300",
                type: .txt2img,
                status: .failed,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
              )
            ]
          ))
        ],
        clientUuid: "client123",
        order: 6,
        contextGenerationIds: ["gen1"],
        contextModelIds: ["model-xyz"],
        createdAt: Date()
      ))

      // Message with generations output
      MessageRow(message: Message(
        serverId: "7",
        threadId: "thread123",
        role: .assistant,
        content: [
          .text(TextContent(text: "Here are your saved generations:")),
          .generations(FetchGenerationsOutput(generations: [
            GenerationOutput(
              id: "saved1",
              status: "completed",
              url: "https://picsum.photos/id/40/200/300"
            ),
            GenerationOutput(
              id: "saved2",
              status: "completed",
              url: "https://picsum.photos/id/42/200/300"
            )
          ]))
        ],
        clientUuid: "client123",
        order: 7,
        contextGenerationIds: ["saved1", "saved2"],
        contextModelIds: nil,
        createdAt: Date()
      ))

      // Complex multi-part message
      MessageRow(message: Message(
        serverId: "8",
        threadId: "thread123",
        role: .assistant,
        content: [
          .text(TextContent(text: "I've prepared a comprehensive response with multiple elements.")),
          .text(TextContent(text: "Here's the analysis of your question:")),
          .toolWork(ImageGenerationOutput(
            prompt: "Nature scenes",
            imageCount: 1,
            videoCount: 0,
            aspectRatio: .landscape,
            generationIds: ["gen1"],
            generations: nil
          )),
          .text(TextContent(text: "And here are some visual examples:")),
          .toolWork(ImageGenerationOutput(
            prompt: "Technology innovation diagram",
            imageCount: 1,
            videoCount: 0,
            aspectRatio: .square,
            generationIds: ["vis1"],
            generations: [
              "vis1": Generation(
                id: "vis1",
                modelId: "model-stable",
                imageUrl: "https://picsum.photos/id/60/200/300",
                assetUrl: "https://picsum.photos/id/60/200/300",
                type: .txt2img,
                status: .succeeded,
                createdAt: ISO8601DateFormatter().string(from: Date()),
                updatedAt: ISO8601DateFormatter().string(from: Date())
              )
            ]
          ))
        ],
        clientUuid: "client123",
        order: 8,
        contextGenerationIds: ["vis1"],
        contextModelIds: ["model-stable"],
        createdAt: Date()
      ))
    }
    .background(Color(.systemBackground))
    //  .environmentObject(FullscreenViewerState())
    .environment(\.onUseGeneration, { generation, image in
      print("Using generation: \(generation.id)")
    })
  }
}
