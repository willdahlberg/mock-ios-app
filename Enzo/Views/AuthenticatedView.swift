//
//  AuthenticatedView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-01.
//

import SwiftUI

struct AuthenticatedView: View {
  let horizontalSizeClass: UserInterfaceSizeClass
  let isExplicitSignIn: Bool
  @StateObject private var assistantManager = AssistantManager()
  @EnvironmentObject private var authManager: AuthenticationManager
  
  var body: some View {
    MainContainerView(horizontalSizeClass: horizontalSizeClass)
      .environmentObject(assistantManager)
      .onAppear {
        if isExplicitSignIn {
          assistantManager.startNewChat()
        }
      }
      .sheet(isPresented: $authManager.showSubscriptionView) {
        SubscriptionView()
      }
  }
}