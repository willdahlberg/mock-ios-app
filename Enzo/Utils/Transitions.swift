//
//  Transitions.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-03.
//

import SwiftUI

extension AnyTransition {
  static var moveForward: AnyTransition {
    .modifier(
      active: DepthModifier(scale: 2.5, opacity: 0),  // Move toward viewer and fade
      identity: DepthModifier(scale: 1, opacity: 1)
    )
  }

  static var moveBack: AnyTransition {
    .modifier(
      active: DepthModifier(scale: 0.4, opacity: 0),  // Move away from viewer and fade
      identity: DepthModifier(scale: 1, opacity: 1)
    )
  }
}

struct DepthModifier: ViewModifier {
  let scale: Double
  let opacity: Double

  func body(content: Content) -> some View {
    content
      .scaleEffect(scale)
      .opacity(opacity)
      .blur(radius: scale > 1 ? (scale - 1) * 3 : (1 - scale) * 3)
  }
}
