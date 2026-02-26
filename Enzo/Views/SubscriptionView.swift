//
//  SubscriptionView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-03-24.
//

import SwiftUI

struct SubscriptionView: View {
    @EnvironmentObject private var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                Image(systemName: "photo.stack")
                    .font(.system(size: 64))
                    .foregroundColor(.accent)
                    .padding()

                Text("Image Generation Requires Plan")
                    .font(.title2)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Text("To view and generate images with Enzo, you need an active plan.")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)

                Spacer()

                Button {
                    dismiss()
                } label: {
                    HStack {
                        Text("Subscribe at everart.ai")
                        Image(systemName: "arrow.right")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accent)
                    .cornerRadius(10)
                }
                .padding(.horizontal)

                Button("Continue without subscribing") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.secondary)
                .padding(.bottom)
            }
            .padding()
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    SubscriptionView()
        .environmentObject(AuthenticationManager.shared)
}
