//
//  Glow.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-03-18.
//

import SwiftUI

extension View {
  func glow(color: Color = .white, radius: CGFloat = 10) -> some View {
    self
      .shadow(color: color.opacity(0.7), radius: radius, x: 0, y: 0)
      .shadow(color: color.opacity(0.5), radius: radius / 2, x: 0, y: 0)
  }
}

// Usage examples:

struct GlowButtonExample: View {
  @State private var isGlowing = false

  var body: some View {
    VStack(spacing: 30) {
      // Example 1: Basic button with glow
      Button("Glowing Button") {}
        .font(.headline)
        .foregroundColor(.white)
        .padding()
        .background(Color.blue)
        .cornerRadius(10)
        .glow(color: .blue, radius: isGlowing ? 15 : 5)
//        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)

      // Example 2: Icon with glow
      Image(systemName: "bolt.fill")
        .font(.system(size: 50))
        .foregroundColor(.yellow)
        .glow(color: .yellow, radius: isGlowing ? 15 : 5)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)

      // Example 3: Text with glow
      Text("Glowing Text")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.purple)
        .glow(color: .purple, radius: isGlowing ? 12 : 4)
        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: isGlowing)

      // Example 4: SF Symbol with pulsing glow
      ZStack {
        Image(systemName: "heart.fill")
          .font(.system(size: 80))
          .foregroundColor(.red)
          .glow(color: .red, radius: isGlowing ? 20 : 5)
          .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: isGlowing)
      }
    }
    .padding()
    .onAppear {
      isGlowing = true
    }
  }
}

#Preview {
  GlowButtonExample()
    .preferredColorScheme(.dark)
}

#Preview {
  GlowButtonExample()
    .preferredColorScheme(.light)
}
