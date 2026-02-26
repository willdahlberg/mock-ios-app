//
//  APIClient.swift
//  Enzo
//
//  Created by William Dahlberg on 2025-02-04.
//

import Foundation

// MARK: - API Configuration

struct APIConfig {
  static let baseURL = URL(string: ProcessInfo.processInfo.environment["API_URL"] ?? "https://api.everart.ai")!
  static let defaultTimeout: TimeInterval = 10
}

// MARK: - API Errors

enum APIError: LocalizedError {
  case invalidURL
  case invalidResponse
  case authenticationRequired
  case serverError(String)
  case networkError(Error)
  case decodingError(Error)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "Invalid URL"
    case .invalidResponse:
      return "Invalid server response"
    case .authenticationRequired:
      return "Authentication required"
    case .serverError(let message):
      return "Server error: \(message)"
    case .networkError(let error):
      return "Network error: \(error.localizedDescription)"
    case .decodingError(let error):
      return "Decoding error: \(error.localizedDescription)"
    }
  }
}

// MARK: - HTTP Endpoints

enum HTTPEndpoint {
  case authApple
  case authGoogle
  case authSocket
  case authEmailVerification
  case authEmail
  case getPrediction(predictionId: String)
  case getUploadURL(filename: String, organizationId: String?)
  case getMe
  case deleteMe

  var path: String {
    switch self {
    case .authApple:
      return "/auth/apple"
    case .authGoogle:
      return "/auth/google"
    case .authSocket:
      return "/auth/tokens"
    case .authEmailVerification:
      return "auth/login/email/verification"
    case .authEmail:
      return "/auth/email"
    case .getPrediction(let predictionId):
      return "/predict/models/123/prediction/\(predictionId)"
    case .getUploadURL(_, let organizationId):
      if let orgId = organizationId {
        return "/organizations/\(orgId)/assets/upload-url"
      } else {
        return "/users/me/assets/upload-url"
      }
    case .getMe, .deleteMe:
      return "users/everart/me"
    }
  }

  var method: String {
    switch self {
    case .authApple, .authGoogle, .authEmailVerification, .authEmail:
      return "POST"
    case .authSocket,
        .getPrediction,
        .getUploadURL,
        .getMe:
      return "GET"
    case .deleteMe:
      return "DELETE"
    }
  }
}

// MARK: - Responses

// .authEmailInit
struct EmailVerificationResponse: Codable {
}

// .signInWithApple
struct AuthResponse: Codable {
  let accessToken: String
  let accessTokenExpiration: Int
  let refreshToken: String
  let refreshTokenExpiration: Int
}

// .socketAuth
struct SocketAuthResponse: Decodable {
  let accessToken: String
  let refreshToken: String
}

// .getPrediction
struct GetPredictionResponse: Codable {
  let trainedModelPrediction: TrainedModelPrediction
}

// .getUploadURL
struct UploadURLResponse: Codable {
  let uploadUrl: String
  let fileUrl: String
  let uploadToken: String
}

// .getMe
struct MeResponse: Codable {
  let user: User
}

struct User: Codable {
  let id: String
  let displayName: String
  let email: String
  let avatar: String?
  let roles: [String]
  let subscription: Subscription?
  let status: String?
}

// MARK: - API Client

final class APIClient {
  private let session: URLSession
  private let decoder: JSONDecoder
  private let encoder: JSONEncoder

  init(session: URLSession = .shared,
       decoder: JSONDecoder = SocketJSONDecoder(),
       encoder: JSONEncoder = JSONEncoder()) {
    self.session = session
    self.decoder = decoder
    self.encoder = encoder

    self.decoder.keyDecodingStrategy = .convertFromSnakeCase
    self.encoder.keyEncodingStrategy = .convertToSnakeCase
  }

  func perform<T: Decodable>(_ endpoint: HTTPEndpoint) async throws -> T {
    try await perform(endpoint, body: nil as String?, queryParameters: nil)
  }

  func perform<T: Decodable>(_ endpoint: HTTPEndpoint, body: Encodable?) async throws -> T {
    try await perform(endpoint, body: body, queryParameters: nil)
  }

  func perform<T: Decodable>(_ endpoint: HTTPEndpoint,
                             body: Encodable?,
                             queryParameters: [String: String]?) async throws -> T {

    guard var urlComponents = URLComponents(
      url: APIConfig.baseURL.appendingPathComponent(endpoint.path),
      resolvingAgainstBaseURL: true
    ) else {
      throw APIError.invalidURL
    }

    if let queryParameters = queryParameters {
      urlComponents.queryItems = queryParameters.map {
        URLQueryItem(name: $0.key, value: $0.value)
      }
    }

    guard let url = urlComponents.url else {
      throw APIError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    request.setValue("2", forHTTPHeaderField: "Api-Version")

    if let accessToken = AuthenticationManager.shared.getAccessToken() {
      request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
    }

    if let body = body {
      request.httpBody = try encoder.encode(body)
    }

    do {
      let (data, response) = try await session.data(for: request)

      do {
        guard let httpResponse = response as? HTTPURLResponse else {
          throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
          throw APIError.authenticationRequired
        }

        guard (200...299).contains(httpResponse.statusCode) else {
          if let errorResponse = try? decoder.decode(ErrorResponse.self, from: data) {
            throw APIError.serverError(errorResponse.message)
          }
          throw APIError.serverError("Server returned status code \(httpResponse.statusCode)")
        }

        print("JSON", String(data: data, encoding: .utf8))
        return try decoder.decode(T.self, from: data)
      } catch {
        print("API Error: \(error), response: \(data.json)")
        throw error
      }
    } catch let error as APIError {
      throw error
    } catch let error as DecodingError {
      throw APIError.decodingError(error)
    } catch {
      throw APIError.networkError(error)
    }
  }

  // Convenience calls to API

  func appleAuth(identityToken: String, authorizationCode: String) async throws -> AuthResponse {
    let body = [
      "identityToken": identityToken,
      "authorizationCode": authorizationCode
    ]

    return try await perform(.authApple, body: body)
  }
  
  func googleAuth(idToken: String, app: String = "enzo") async throws -> AuthResponse {
    let body = [
      "idToken": idToken,
      "app": app
    ]
    
    return try await perform(.authGoogle, body: body)
  }

  func socketAuth() async throws -> SocketAuthResponse {
    print("API", APIConfig.baseURL)
    return try await perform(.authSocket)
  }

  func getPrediction(predictionId: String) async throws -> GetPredictionResponse {
    return try await perform(.getPrediction(predictionId: predictionId))
  }

  func getUploadURL(filename: String, organizationId: String? = nil) async throws -> UploadURLResponse {
    return try await perform(
      HTTPEndpoint.getUploadURL(filename: filename, organizationId: organizationId),
      body: nil,
      queryParameters: ["filename": filename])
  }

  func getMe() async throws -> MeResponse {
    return try await perform(.getMe)
  }

  func deleteMe() async throws -> MeResponse {
    return try await perform(.deleteMe)
  }

  func initiateEmailVerification(email: String, app: String = "enzo") async throws -> EmailVerificationResponse {
    let body = [
      "email": email,
      "service": "enzo"
    ]
    
    return try await perform(.authEmailVerification, body: body)
  }
  
  func verifyEmailCode(email: String, code: String, app: String = "enzo") async throws -> AuthResponse {
    let body = [
      "email": email,
      "verificationCode": code,
      "service": "enzo"
    ]
    
    return try await perform(.authEmail, body: body)
  }
}

struct ErrorResponse: Codable {
  let success: Bool
  let message: String
}
