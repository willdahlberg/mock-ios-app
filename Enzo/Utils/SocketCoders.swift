//
//  SocketCoders.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-03.
//

import Foundation

class SocketJSONEncoder: JSONEncoder, @unchecked Sendable {
  override init() {
    super.init()
    self.keyEncodingStrategy = .convertToSnakeCase
    self.dateEncodingStrategy = .iso8601
  }
}

class SocketJSONDecoder: JSONDecoder, @unchecked Sendable {
  private let dateFormatter: DateFormatter

  override init() {
    self.dateFormatter = DateFormatter()
    self.dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
    self.dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
    self.dateFormatter.locale = Locale(identifier: "en_US_POSIX")

    super.init()
    self.keyDecodingStrategy = .convertFromSnakeCase
    self.setupDateDecodingStrategy()
  }

  private func setupDateDecodingStrategy() {
    self.dateDecodingStrategy = .custom { [dateFormatter] decoder in
      let container = try decoder.singleValueContainer()
      let dateStr = try container.decode(String.self)

      if let date = dateFormatter.date(from: dateStr) {
        return date
      }

      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot decode date string \(dateStr)"
      )
    }
  }
}
