//
//  GenerationPollingManager.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-04.
//

import Foundation
import SwiftUI

struct BucketImage: Codable {
  let id: String
  let url: String
}

struct StoredImage: Codable {
  let id: String
  let url: String
  let favorited: Bool
  let createdAt: String
  let updatedAt: String
  let thumbnail: String?

  struct Metadata: Codable {
    let width: Int?
    let height: Int?
    let duration: Int?
  }
  let metadata: Metadata?
  let trainedModelPrediction: TrainedModelPrediction?
}

// Enum for query types
enum TrainedModelQueryType: Int, Codable {
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

  var generationType: GenerationType {
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
    case .upscaleGan:
      return .upscaleGan
    case .adsCreation:
      return .adsCreation
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
    case .controlNet:
      return .controlNet
    case .freeformEdit:
      return .freeformEdit
    }
  }
}

// Prediction status enum
enum PredictionStatus: String, Codable {
  case starting = "STARTING"
  case processing = "PROCESSING"
  case succeeded = "SUCCEEDED"
  case failed = "FAILED"
  case canceled = "CANCELED"
}

// Feedback entity type enum
enum FeedbackEntityType: String, Codable {
  case trainedModel = "TRAINED_MODEL"
  // Add other cases as needed
}

// Feedback type
struct Feedback: Codable {
  let id: String
  let isPositive: Bool
  let entityType: FeedbackEntityType
  let entityId: String
  let userId: String
  let createdAt: String
}

enum PredictionAspectRatio: String, Codable {
  case square = "SQUARE"
  case portrait = "PORTRAIT"
  case landscape = "LANDSCAPE"
  case vertical = "VERTICAL"
  case wide = "WIDE"
  case ultrawide = "ULTRAWIDE"
  case photo = "PHOTO"
  case ad = "AD"
}

class TrainedModelPrediction: Codable, Identifiable {
  let id: String
  let image: StoredImage?
  let parent: TrainedModelPrediction?
  let parentTrainingImage: BucketImage?
  let trainedModelId: String?
  let type: TrainedModelQueryType
  let status: PredictionStatus?
  let advancedSettings: [String: AnyCodable]?
  let feedback: Feedback?
  let aspectRatio: PredictionAspectRatio?
  let createdAt: String
  let updatedAt: String
  let treeParents: [TrainedModelPrediction]?
}

actor GenerationPollingManager: ObservableObject {
  private var pollingTasks: [String: Task<Void, Never>] = [:]
  private let pollingInterval: TimeInterval = 5.0
  private var onGenerationComplete: ((String, Generation) -> Void)?

  init(onGenerationComplete: @escaping (String, Generation) -> Void) {
    self.onGenerationComplete = onGenerationComplete
  }

  func startPolling(output: ImageGenerationOutput) {
    // Only poll for generations that don't have results yet
    let incompletedIds = output.generationIds.filter { id in
      output.generations?[id] == nil
    }

    for generationId in incompletedIds {
      guard pollingTasks[generationId] == nil else { continue }

      let task = Task<Void, Never> { [weak self] in
        await self?.pollGeneration(generationId: generationId)
        return
      }
      pollingTasks[generationId] = task
    }
  }

  private func pollGeneration(generationId: String) async {
    while !Task.isCancelled {
      do {
        let generation = try await fetchGenerationStatus(generationId)

        if generation.status == .succeeded {
          Task { @MainActor in
            await onGenerationComplete?(generationId, generation)
          }

          await stopPolling(generationId: generationId)
          break
        }

        try await Task.sleep(nanoseconds: UInt64(pollingInterval * 1_000_000_000))
      } catch is CancellationError {
        break
      } catch {
        print("Error polling generation \(generationId):", error)
        try? await Task.sleep(nanoseconds: UInt64(pollingInterval * 2 * 1_000_000_000))
      }
    }
  }

  func stopPolling(generationId: String) async {
    pollingTasks[generationId]?.cancel()
    pollingTasks[generationId] = nil
  }

  func stopAllPolling() async {
    for (generationId, _) in pollingTasks {
      await stopPolling(generationId: generationId)
    }
  }

  private func fetchGenerationStatus(_ generationId: String) async throws -> Generation {
    // Mock: wait 1-2 seconds then return succeeded generation with placeholder image
    let delay = Double.random(in: 1.0...2.0)
    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))

    let randomSeed = abs(generationId.hashValue % 1000)
    return Generation(
      id: generationId,
      modelId: "mock-model-1",
      imageUrl: "https://picsum.photos/512/512?random=\(randomSeed)",
      assetUrl: "https://picsum.photos/512/512?random=\(randomSeed)",
      type: .txt2img,
      status: .succeeded,
      createdAt: ISO8601DateFormatter().string(from: Date()),
      updatedAt: ISO8601DateFormatter().string(from: Date())
    )
  }
}

// Message extension for transformation
extension Message {
  func transformedWithGeneration(generationId: String, generation: Generation) -> Message? {
    guard case var .toolWork(output) = content.first else {
      return nil
    }

    var updatedGenerations = output.generations ?? [:]
    updatedGenerations[generationId] = generation
    output.generations = updatedGenerations

    return Message(
      serverId: serverId,
      threadId: threadId,
      role: role,
      content: [.toolWork(output)],
      clientUuid: clientUuid,
      order: order,
      contextGenerationIds: contextGenerationIds,
      contextModelIds: contextModelIds,
      createdAt: createdAt
    )
  }
}
