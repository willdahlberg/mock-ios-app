//
//  ActionItem.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-28.
//

import Foundation

struct ActionItem: Identifiable {
  let id: UUID
  let description: String
  let timestamp: Date
  let icon: String
  var images: [String]?
}
