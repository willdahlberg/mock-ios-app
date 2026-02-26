//
//  GenerationActions.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-19.
//

import SwiftUI

struct AssetActionButtons: View {
  let onUseGeneration: (() -> Void)?
  let onShare: (() -> Void)?
  let onSaveToPhotos: (() -> Void)?

  var body: some View {
    VStack(spacing: 16) {
      if let onUseGeneration = onUseGeneration {
        Button(action: onUseGeneration) {
          HStack {
            Image(systemName: "wand.and.sparkles")
            Text("Use Image")
          }
          .frame(maxWidth: .infinity)
          .padding(.vertical, 15)
          .background(.ultraThinMaterial)
          .clipShape(.rect(cornerRadius: 20))
        }
        .foregroundStyle(.primary)
      }

      HStack(spacing: 12) {
        if let onShare = onShare {
          Button(action: onShare) {
            HStack {
              Image(systemName: "square.and.arrow.up")
              Text("Share Image")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(.thinMaterial)
            .clipShape(.rect(cornerRadius: 20))
          }
        }

        if let onSaveToPhotos = onSaveToPhotos {
          Button(action: onSaveToPhotos) {
            HStack {
              Image(systemName: "arrow.down.circle")
              Text("Save to Photos")
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 15)
            .background(.thinMaterial)
            .clipShape(.rect(cornerRadius: 20))
          }
        }
      }
      .foregroundStyle(.primary)
    }
  }
}
