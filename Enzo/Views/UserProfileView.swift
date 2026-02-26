//
//  UserProfileView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-03-24.
//

import SwiftUI

struct UserProfileView: View {
  @EnvironmentObject private var authManager: AuthenticationManager
  @Environment(\.dismiss) private var dismiss
  @State private var showDeleteConfirmation = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 20) {
        if let user = authManager.user {
          if let avatarUrl = user.avatar, !avatarUrl.isEmpty {
            AsyncImage(url: URL(string: avatarUrl)) { phase in
              switch phase {
              case .empty:
                ProgressView()
                  .frame(width: 100, height: 100)
              case .success(let image):
                image
                  .resizable()
                  .aspectRatio(contentMode: .fill)
                  .frame(width: 100, height: 100)
                  .clipShape(Circle())
              case .failure:
                Image(systemName: "person.circle.fill")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 100, height: 100)
                  .foregroundColor(.gray)
              @unknown default:
                EmptyView()
              }
            }
            .frame(width: 100, height: 100)
          } else {
            Image(systemName: "person.circle.fill")
              .resizable()
              .aspectRatio(contentMode: .fit)
              .frame(width: 100, height: 100)
              .foregroundColor(.gray)
          }

          Text(user.displayName)
            .font(.title2)
            .fontWeight(.bold)

          Text(user.email)
            .font(.body)
            .foregroundColor(.secondary)

          if let subscription = user.subscription {
            Text("Subscription: \(subscription)")
              .font(.subheadline)
              .padding(.vertical, 4)
              .padding(.horizontal, 8)
              .background(Color.blue.opacity(0.2))
              .cornerRadius(4)
          }

          Spacer()

          Button {
            showDeleteConfirmation = true
          } label: {
            Text("Delete Account")
              .foregroundColor(.white)
              .frame(maxWidth: .infinity)
              .padding()
              .background(Color.red)
              .cornerRadius(10)
          }
          .padding(.horizontal)
          .alert("Delete Account", isPresented: $showDeleteConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
              authManager.signOut()
              dismiss()
            }
          } message: {
            Text("Are you sure you want to delete your account? This action cannot be undone.")
          }
        } else {
          Text("User information not available")
            .foregroundColor(.secondary)
          Spacer()
        }
      }
      .padding()
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            dismiss()
          } label: {
            Text("Done")
          }
        }
      }
    }
  }
}
