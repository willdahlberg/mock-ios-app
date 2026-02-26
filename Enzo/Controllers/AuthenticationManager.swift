//
//  AuthenticationManager.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI

class AuthenticationManager: ObservableObject {
  static let shared = AuthenticationManager()
  @Published var isAuthenticated = false {
    didSet {
      if isAuthenticated && !oldValue {
        Task {
          await fetchUserData()
        }
      }
    }
  }
  @Published private(set) var isExplicitSignIn = false
  @Published var showSubscriptionView = false
  var user: User?

  // Email verification state
  @Published var isEmailVerificationInProgress = false

  private init() {
    // Start unauthenticated so the user sees the sign-in screen
  }

  func getAccessToken() -> String? {
    return isAuthenticated ? "mock-access-token" : nil
  }

  func getRefreshToken() -> String? {
    return isAuthenticated ? "mock-refresh-token" : nil
  }

  @MainActor
  func fetchUserData() async {
    user = User(
      id: "mock-user-1",
      displayName: "Demo User",
      email: "demo@enzo.ai",
      avatar: nil,
      roles: ["user"],
      subscription: Subscription(
        subscriptionType: .PRO,
        intent: nil,
        active: true,
        expiresAt: Date().addingTimeInterval(365 * 24 * 60 * 60)
      ),
      status: "ACTIVE"
    )
    showSubscriptionView = false
  }

  @MainActor
  func handleSignInWithAppleCompletion() {
    isAuthenticated = true
    isExplicitSignIn = true
  }

  @MainActor
  func handleSignInWithGoogle() {
    isAuthenticated = true
    isExplicitSignIn = true
  }

  func signOut() {
    isAuthenticated = false
    isExplicitSignIn = false
  }

  @MainActor
  func initiateEmailVerification(email: String) async {
    isEmailVerificationInProgress = true
  }

  @MainActor
  func verifyEmailCode(email: String, code: String) async throws {
    isAuthenticated = true
    isExplicitSignIn = true
    isEmailVerificationInProgress = false
  }
}
