//
//  DynamicGradientModifier.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-15.
//

import SwiftUI

private struct DynamicGradientModifier: ViewModifier {
  @State private var globalPosition: CGPoint = .zero
  @State private var viewHeight: CGFloat = 0
  let primary: Color
  let secondary: Color?

  init(_ primary: Color, _ secondary: Color? = nil) {
    self.primary = primary
    self.secondary = secondary
  }

  func body(content: Content) -> some View {
    let globalY: Double = globalPosition.y
    let startProgress = globalY / (UIScreen.main.bounds.height * 25.0)
    let endProgress = (globalY + viewHeight) / (UIScreen.main.bounds.height * 25.0)

    let (hue, saturation, brightness) = primary.hsb()
    let startHue = (hue + startProgress).truncatingRemainder(dividingBy: 1.0)
    let endHue = (hue + endProgress).truncatingRemainder(dividingBy: 1.0)

    let gradient = LinearGradient(
      colors: [
        Color(hue: startHue, saturation: saturation, brightness: brightness),
        Color(hue: endHue, saturation: saturation, brightness: brightness)
      ],
      startPoint: .top,
      endPoint: .bottom
    )

    let backgroundContent = content.background(
      GeometryReader { geometry in
        Color.clear
          .onAppear {
            let frame = geometry.frame(in: .scrollView)
            globalPosition = CGPoint(x: frame.minX, y: frame.minY)
            viewHeight = frame.height
          }
          .onChange(of: geometry.frame(in: .scrollView)) { _, frame in
            globalPosition = CGPoint(x: frame.minX, y: frame.minY)
            viewHeight = frame.height
          }
      }
    )

    if let secondary = secondary {
      backgroundContent.foregroundStyle(secondary, gradient)
    } else {
      backgroundContent.foregroundStyle(gradient)
    }
  }
}

extension View {
  func dynamicGradient(_ primary: Color, _ secondary: Color? = nil) -> some View {
    modifier(DynamicGradientModifier(primary, secondary))
  }
}

extension Color {
  func hsb() -> (hue: Double, saturation: Double, brightness: Double) {
    var hue: CGFloat = 0
    var saturation: CGFloat = 0
    var brightness: CGFloat = 0
    var alpha: CGFloat = 0

    UIColor(self).getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: &alpha)

    return (Double(hue), Double(saturation), Double(brightness))
  }
}

#Preview {
  TabView {
    // Scrolling version
    ScrollView {
      LazyVStack(spacing: 0) {
        ForEach(0..<20) { _ in
          Button(action: {}) {
            Image(systemName: "arrow.up.circle.fill")
              .font(.system(size: 32))
              .dynamicGradient(.accent, .white)
          }
          Rectangle()
            .frame(height: CGFloat.random(in: 50...200))
            .dynamicGradient(.accent)
        }
      }
      .padding()
    }
    .background(Color(.systemBackground))
    .tabItem {
      Text("Scrolling")
    }

    // Full screen version
    Rectangle()
      .dynamicGradient(.accent)
      .ignoresSafeArea()
      .tabItem {
        Text("Full Screen")
      }
  }
}
