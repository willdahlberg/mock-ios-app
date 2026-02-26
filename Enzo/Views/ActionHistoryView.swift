//
//  ActionHistoryView.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import SwiftUI

struct ActionHistoryView: View {
  let chat: Chat

  var body: some View {
    List {
//      ForEach(chat.actions) { action in
//        VStack(alignment: .leading, spacing: 8) {
//          HStack {
//            Image(systemName: action.icon)
//              .foregroundStyle(.secondary)
//            Text(action.timestamp.formatted(date: .omitted, time: .shortened))
//              .foregroundStyle(.secondary)
//              .font(.caption)
//          }
//
//          Text(action.description)
//            .font(.headline)
//
//          if let images = action.images {
//            ScrollView(.horizontal) {
//              HStack {
//                ForEach(images, id: \.self) { image in
//                  Image(image)
//                    .resizable()
//                    .aspectRatio(contentMode: .fill)
//                    .frame(width: 150, height: 150)
//                    .clipShape(RoundedRectangle(cornerRadius: 8))
//                }
//              }
//            }
//          }
//        }
//        .padding(.vertical, 4)
//      }
    }
    .navigationTitle("Actions")
  }
}
