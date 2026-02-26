//
//  ImageDetailView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI

struct ImageDetailView: View {
  let message: ChatMessage

  var body: some View {
    VStack(alignment: .leading, spacing: 16) {
      if let images = message.images {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            Text("Images")
              .font(.headline)

            LazyVGrid(columns: [
              GridItem(.adaptive(minimum: 250), spacing: 16)
            ], spacing: 16) {
              ForEach(images, id: \.self) { image in
                Image(image)
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .clipShape(RoundedRectangle(cornerRadius: 12))
              }
            }
          }
          .padding()
        }
      }
    }
    .navigationTitle("Image Details")
  }
}
