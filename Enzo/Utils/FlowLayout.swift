//
//  FlowLayout.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-03.
//

import UIKit
import SwiftUI

struct FlowLayout: Layout {
  var spacing: CGFloat = 12

  func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
    let result = FlowResult(
      in: proposal.width ?? 0,
      subviews: subviews,
      spacing: spacing
    )
    return result.size
  }

  func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
    let result = FlowResult(
      in: bounds.width,
      subviews: subviews,
      spacing: spacing
    )

    for (index, line) in result.lines.enumerated() {
      let y = bounds.minY + result.lineY(at: index)

      for item in line.items {
        let x = bounds.minX + item.x
        subviews[item.index].place(
          at: CGPoint(x: x, y: y),
          proposal: ProposedViewSize(item.size)
        )
      }
    }
  }

  struct FlowResult {
    struct Item {
      var index: Int
      var size: CGSize
      var x: CGFloat
    }

    struct Line {
      var items: [Item]
      var height: CGFloat
      var spacing: CGFloat
    }

    var lines: [Line]
    var size: CGSize

    init(in width: CGFloat, subviews: Subviews, spacing: CGFloat) {
      var lines: [Line] = []
      var currentLine = Line(items: [], height: 0, spacing: spacing)
      var currentX: CGFloat = 0
      var totalHeight: CGFloat = 0
      var maxWidth: CGFloat = 0

      for (index, subview) in subviews.enumerated() {
        let size = subview.sizeThatFits(.unspecified)

        if currentX + size.width > width && !currentLine.items.isEmpty {
          // Start new line
          lines.append(currentLine)
          totalHeight += currentLine.height + spacing
          currentLine = Line(items: [], height: 0, spacing: spacing)
          currentX = 0
        }

        currentLine.items.append(Item(index: index, size: size, x: currentX))
        currentLine.height = max(currentLine.height, size.height)
        currentX += size.width + spacing
        maxWidth = max(maxWidth, currentX)
      }

      if !currentLine.items.isEmpty {
        lines.append(currentLine)
        totalHeight += currentLine.height
      }

      self.lines = lines
      self.size = CGSize(width: maxWidth - spacing, height: totalHeight - spacing)
    }

    func lineY(at index: Int) -> CGFloat {
      var y: CGFloat = 0
      for i in 0..<index {
        y += lines[i].height + lines[i].spacing
      }
      return y
    }
  }
}
