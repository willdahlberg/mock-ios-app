//
//  ShareSheet.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-19.
//

import SwiftUI

struct ShareSheet: UIViewControllerRepresentable {
  var items: [Any]

  func makeUIViewController(context: Context) -> UIActivityViewController {
    let controller = UIActivityViewController(
      activityItems: items,
      applicationActivities: nil
    )
    return controller
  }

  func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
