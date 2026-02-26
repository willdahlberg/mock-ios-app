//
//  ContentView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI

struct ContentView: View {
  @StateObject private var authManager = AuthenticationManager.shared
  @Environment(\.horizontalSizeClass) private var horizontalSizeClass

  var body: some View {
    ZStack {
      if authManager.isAuthenticated {
        AuthenticatedView(
          horizontalSizeClass: horizontalSizeClass ?? .compact,
          isExplicitSignIn: authManager.isExplicitSignIn
        )
        .environmentObject(authManager)
        .transition(.asymmetric(
          insertion: .moveBack,
          removal: .moveBack
        ))
      } else {
        AuthenticationView()
          .transition(.asymmetric(
            insertion: .moveForward,
            removal: .moveForward
          ))
      }
    }
    .animation(.spring(.smooth), value: authManager.isAuthenticated)
  }
}

#Preview {
  ContentView()
}
