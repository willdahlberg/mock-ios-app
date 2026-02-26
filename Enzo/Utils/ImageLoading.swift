//
//  ImageProcessors.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-18.
//

import SwiftUI
import UIKit
import Nuke
import NukeUI

func configureImagePipeline() {
  ImagePipeline.shared = ImagePipeline {
    $0.dataCache = try! DataCache(name: "ai.newcompute.enzo")
    $0.dataLoader = DataLoader(configuration: {
      // Disable disk caching built into URLSession
      let conf = DataLoader.defaultConfiguration
      conf.urlCache = nil
      return conf
    }())
  }
}

extension ImageProcessors.Resize {
  static let thumbnail = ImageProcessors.Resize(
    size: CGSize(width: 150, height: 150),
    contentMode: .aspectFill
  )

  static let fullWidth = ImageProcessors.Resize(
    size: CGSize(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height),
    contentMode: .aspectFill
  )

  static let highQuality = ImageProcessors.Resize(
    size: CGSize(width: 2048, height: 2048),
    unit: .pixels,
    contentMode: .aspectFit
  )
}

extension ImageRequest {
  var cachedOriginal: UIImage {
    ImagePipeline.shared.cache.cachedImage(for: ImageRequest(url: self.url))!.image
  }
}
