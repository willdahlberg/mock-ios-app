//
//  DebuggingDecoder.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-01-31.
//

import Foundation

class DebuggingDecoder: JSONDecoder, @unchecked Sendable {
  override func decode<T>(_ type: T.Type, from data: Data) throws -> T where T : Decodable {
    do {
      return try super.decode(type, from: data)
    } catch let DecodingError.keyNotFound(key, context) {
      print("⚠️ Key '\(key.stringValue)' not found at path: \(context.codingPath.map { $0.stringValue })")
      print("🔍 Debugging context:", context.debugDescription)
      print("⚡️ Coding path:", context.codingPath)
      throw DecodingError.keyNotFound(key, context)
    } catch let DecodingError.typeMismatch(type, context) {
      print("❌ Type mismatch: expected \(type) at path: \(context.codingPath.map { $0.stringValue })")
      print("🔍 Debugging context:", context.debugDescription)
      print("⚡️ Coding path:", context.codingPath)
      throw DecodingError.typeMismatch(type, context)
    } catch {
      print("💥 Other decoding error:", error)
      throw error
    }
  }
}

extension Data {
  var json: Any {
    if let json = try? JSONSerialization.jsonObject(with: self) {
      return json
    } else {
      return "Invalid JSON"
    }
  }
}

func inspectJSON(_ json: Any, path: [String]) -> Any? {
  var current: Any = json
  
  for key in path {
    if let dict = current as? [String: Any] {
      guard let value = dict[key] else {
        print("❌ Key '\(key)' not found in dictionary")
        print("📍 Available keys:", dict.keys.sorted())
        return nil
      }
      current = value
    } else if let array = current as? [Any], let index = Int(key) {
      guard index < array.count else {
        print("❌ Array index \(index) out of bounds (count: \(array.count))")
        return nil
      }
      current = array[index]
    } else {
      print("❌ Cannot navigate through \(type(of: current))")
      return nil
    }
  }
  return current
}
