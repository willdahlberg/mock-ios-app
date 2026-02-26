//
//  TypingIndicator.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI

struct TypingIndicator: View {
  var body: some View {
    TimelineView(.animation(minimumInterval: 1/60)) { timeline in
      HStack(spacing: 4) {
        ForEach(0..<3) { index in
          Circle()
            .fill(Color(.tertiaryLabel))
            .frame(width: 8, height: 8)
            .offset(y: sin(timeline.date.timeIntervalSinceReferenceDate * 6 + Double(index) * .pi * 0.5) * 2)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 18)
      .background(Color(.secondarySystemBackground))
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
  }
}

#Preview {
  TypingIndicator()
}
