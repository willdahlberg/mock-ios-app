//
//  FileUploadManager.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-13.
//

import Foundation
import SwiftUI
import UIKit
import Combine

// MARK: - File Upload Models

struct FileUpload {
  let file: Data
  let filename: String
  let mimeType: String
  var fileUrl: String?
  var uploadToken: String?
  var isUploading: Bool
  var error: String?
  let preview: Image
}

enum FileUploadError: LocalizedError {
  case invalidFileType
  case uploadInProgress
  case uploadFailed(String)
  case maxImagesExceeded

  var errorDescription: String? {
    switch self {
    case .invalidFileType:
      return "Only JPEG and PNG images are supported"
    case .uploadInProgress:
      return "Please wait for images to finish uploading"
    case .uploadFailed(let message):
      return "Upload failed: \(message)"
    case .maxImagesExceeded:
      return "Maximum 10 images allowed"
    }
  }
}

// MARK: - File Upload Manager

// TODO: Clean up management of uploads per chat

@MainActor
final class FileUploadManager: ObservableObject {
  static let shared = FileUploadManager()
  private let apiClient = APIClient()

  @Published private(set) var fileUploads: [FileUpload] = []

  // MARK: - Public Methods

  func handleFiles(_ images: [UIImage]) async throws {
    let imageFiles = try images.map { image -> FileUpload in
      guard let imageData = image.resizeToMaxDimension(2048).jpegDataWithMaxFileSize(4 * 1024 * 1024) else {
        throw FileUploadError.invalidFileType
      }

      return FileUpload(
        file: imageData,
        filename: UUID().uuidString + ".jpg",
        mimeType: "image/jpeg",
        isUploading: true,
        preview: Image(uiImage: image)
      )
    }

    if imageFiles.count + fileUploads.count > 10 {
      throw FileUploadError.maxImagesExceeded
    }

    // Add new uploads to the array
    withAnimation(.snappy) {
      fileUploads.append(contentsOf: imageFiles)
    }

    // Start uploading each file
    for upload in imageFiles {
      await uploadFile(upload)
    }
  }

  func remove(at index: Int) {
    fileUploads.remove(at: index)
  }

  func clear() {
    fileUploads.removeAll()
  }

  func validateUploads() throws {
    // Check for any ongoing uploads
    if fileUploads.contains(where: { $0.isUploading }) {
      throw FileUploadError.uploadInProgress
    }

    // Check for any upload errors
    if let failedUpload = fileUploads.first(where: { $0.error != nil }) {
      throw FileUploadError.uploadFailed(failedUpload.error ?? "Unknown error")
    }
  }

  // MARK: - Private Methods

  private func uploadFile(_ upload: FileUpload) async {
    // Mock upload: wait briefly, then save to local temp file so Nuke can load it
    try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s

    if let index = fileUploads.firstIndex(where: { $0.filename == upload.filename }) {
      var updatedUpload = upload

      // Write image data to a temp file so LazyImage can load it via file URL
      let tempDir = FileManager.default.temporaryDirectory
      let fileURL = tempDir.appendingPathComponent(upload.filename)
      try? upload.file.write(to: fileURL)

      updatedUpload.fileUrl = fileURL.absoluteString
      updatedUpload.uploadToken = "mock-upload-token-\(UUID().uuidString.prefix(8))"
      updatedUpload.isUploading = false
      fileUploads[index] = updatedUpload
    }
  }
}

// MARK: - Convenience Extensions

extension FileUploadManager {
  var hasUploadsInProgress: Bool {
    fileUploads.contains(where: { $0.isUploading })
  }

  var hasUploadErrors: Bool {
    fileUploads.contains(where: { $0.error != nil })
  }

  var uploadedFileUrls: [String] {
    fileUploads.compactMap { $0.fileUrl }
  }

  var uploadTokens: [String] {
    fileUploads.compactMap { $0.uploadToken }
  }
}

extension UIImage {
  func resizeToMaxDimension(_ maxDimension: CGFloat) -> UIImage {
    let originalWidth = size.width
    let originalHeight = size.height
    let aspectRatio = originalWidth / originalHeight

    var newWidth: CGFloat
    var newHeight: CGFloat

    if originalWidth > originalHeight {
      // Landscape or square
      newWidth = min(originalWidth, maxDimension)
      newHeight = newWidth / aspectRatio
    } else {
      // Portrait
      newHeight = min(originalHeight, maxDimension)
      newWidth = newHeight * aspectRatio
    }

    let newSize = CGSize(width: newWidth, height: newHeight)

    UIGraphicsBeginImageContextWithOptions(newSize, false, scale)
    draw(in: CGRect(origin: .zero, size: newSize))
    let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()

    return resizedImage ?? self
  }

  func jpegDataWithMaxFileSize(_ maxSizeInBytes: Int, startQuality: CGFloat = 1.0) -> Data? {
    // Start with the specified quality (default 0.8)
    var quality = startQuality
    let minQuality: CGFloat = 0.0
    let qualityStep: CGFloat = 0.05

    // First try with starting quality
    guard var data = jpegData(compressionQuality: quality) else {
      return nil
    }

    // If already under max size, return immediately
    if data.count <= maxSizeInBytes {
      return data
    }

    // Binary search approach for optimal quality
    var maxQuality = startQuality
    var minCurrentQuality = minQuality

    while quality >= minQuality {
      quality = (maxQuality + minCurrentQuality) / 2

      guard let newData = jpegData(compressionQuality: quality) else {
        return nil
      }

      let newDataCount = newData.count

      // If we're within 10KB of the max size or the quality steps are very small, we're done
      if abs(newDataCount - maxSizeInBytes) < 10_000 || (maxQuality - minCurrentQuality) < qualityStep {
        return newData
      }

      if newDataCount > maxSizeInBytes {
        maxQuality = quality - qualityStep
      } else {
        data = newData
        minCurrentQuality = quality + qualityStep
      }
    }

    return data
  }
}
