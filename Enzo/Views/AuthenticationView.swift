//
//  AuthenticationView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI
import Combine

struct AuthenticationView: View {
  @Environment(\.colorScheme) var colorScheme

  @State private var showVerificationView = false
  @State private var email = ""
  @State private var isValidEmail = false
  @State private var isEmailFieldFocused = false
  @State private var isIpad: Bool = false

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
      Image("assistant_avatar")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: 120, height: 120)

      (Text("Hi, I'm ")
        .font(.largeTitle)
        .bold() +
      Text("Enzo")
        .font(.largeTitle)
        .bold()
        .foregroundColor(.accent))

      Text("Sign in to start creating things together")
        .font(.subheadline)
        .foregroundColor(.secondary)

      // Mock Sign in with Apple button
      Button(action: {
        AuthenticationManager.shared.handleSignInWithAppleCompletion()
      }) {
        HStack(spacing: 6) {
          Image(systemName: "apple.logo")
            .font(.system(size: 16, weight: .medium))
          Text("Sign in with Apple")
            .font(.system(size: 16, weight: .medium))
        }
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color.black)
        .cornerRadius(8)
      }
      .padding(.horizontal, 40)

      Button(action: handleGoogleSignIn, label: {
        HStack(spacing: 6) {
          Image("google")
          Text("Sign in with Google")
        }
      })
      .fontWeight(.medium)
      .foregroundStyle(Color.primary)
      .frame(height: 44)
      .frame(maxWidth: .infinity)
      .overlay(
        RoundedRectangle(cornerRadius: 8)
          .stroke(
            Color.gray.opacity(0.3),
            lineWidth: colorScheme == .light ? 1 : 0
          )
      )
      .cornerRadius(8)
      .padding(.horizontal, 40)

      HStack {
        Rectangle()
          .fill(Color.secondary.opacity(0.3))
          .frame(height: 1)
          .padding(.leading, 40)
        Text("OR")
          .font(.callout)
          .foregroundStyle(Color.secondary)
        Rectangle()
          .fill(Color.secondary.opacity(0.3))
          .frame(height: 1)
          .padding(.trailing, 40)
      }

      TextField("Sign in with Email", text: $email, prompt: Text("Sign in with Email"))
        .textContentType(.emailAddress)
        .keyboardType(.emailAddress)
        .autocapitalization(.none)
        .autocorrectionDisabled()
        .submitLabel(.go)
        .multilineTextAlignment(.center)
        .frame(height: 44)
        .padding(.horizontal, 12)
        .background(Color(.systemGray6))
        .cornerRadius(8)
        .padding(.horizontal, 40)
        .onChange(of: email) { _, _ in
          isValidEmail = isValidEmailFormat(email)
        }
        .onSubmit {
          if isValidEmail {
            initiateEmailVerification()
          }
        }

      if isValidEmail && isIpad {
        Button(action: initiateEmailVerification) {
          Text("Sign In")
            .frame(maxWidth: .infinity)
            .frame(height: 44)
        }
        .buttonStyle(.borderedProminent)
        .padding(.horizontal, 40)
      }
    }
    .padding()
    }
    .scrollDismissesKeyboard(.interactively)
    .fullScreenCover(isPresented: $showVerificationView) {
      EmailVerificationView(email: email)
    }
    .onAppear {
      isIpad = UIDevice.current.userInterfaceIdiom == .mac || UIDevice.current.userInterfaceIdiom == .pad
    }
  }

  private func isValidEmailFormat(_ email: String) -> Bool {
    let emailRegEx = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
    let emailPred = NSPredicate(format: "SELF MATCHES %@", emailRegEx)
    return emailPred.evaluate(with: email)
  }

  private func initiateEmailVerification() {
    Task {
      await AuthenticationManager.shared.initiateEmailVerification(email: email)
      showVerificationView = true
    }
  }

  func handleGoogleSignIn() {
    AuthenticationManager.shared.handleSignInWithGoogle()
  }
}

#Preview {
  AuthenticationView()
}
