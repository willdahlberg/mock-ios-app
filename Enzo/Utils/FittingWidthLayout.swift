//
//  FittingWidthLayout.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-28.
//

import SwiftUI

struct FittingWidthLayout: Layout {
  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) -> CGSize {
    guard let firstSubview = subviews.first else { return .zero }

    let containerWidth = proposal.width ?? .infinity
    let containerHeight = proposal.height ?? .infinity
    let subviewSize = firstSubview.sizeThatFits(.init(width: nil, height: containerHeight))

    return CGSize(
      width: min(subviewSize.width, containerWidth),
      height: min(subviewSize.height, containerHeight)
    )
  }

  public func placeSubviews(
    in bounds: CGRect,
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout ()
  ) {
    subviews.first?.place(
      at: CGPoint(x: bounds.minX, y: bounds.minY),
      proposal: .init(width: bounds.width, height: bounds.height)
    )
  }
}
