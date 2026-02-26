//
//  EnzoApp.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI
import Nuke

@main
struct Main {
  static func main() {
    configureImagePipeline()
    EnzoApp.main()
  }
}

struct EnzoApp: App {
  var body: some Scene {
    WindowGroup {
      ContentView()
    }
  }
}

extension UINavigationController {
  open override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    navigationBar.topItem?.backButtonDisplayMode = .minimal
  }
}
