//
//  WebhookService.swift
//  N8NCommandCenter
//
//  Service for communicating with N8N webhooks
//

import Foundation
import Combine

protocol WebhookServiceProtocol {
    func sendMessage(_ message: String, to agent: Agent) async throws -> WebhookResponse
    func testConnection(for agent: Agent) async throws -> Bool
    func validateWebhook(_ url: String) async throws -> WebhookValidation
}

class WebhookService: WebhookServiceProtocol {
    static let shared = WebhookService()
    
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        config.waitsForConnectivity = true
        
        self.session = URLSession(configuration: config)
        
        self.encoder = JSONEncoder()
        self.encoder.dateEncodingStrategy = .iso8601
        
        self.decoder = JSONDecoder()
        self.decoder.dateDecodingStrategy = .iso8601
    }
    
    // MARK: - Main Operations
    func sendMessage(_ message: String, to agent: Agent) async throws -> WebhookResponse {
        guard let url = URL(string: agent.webhookURL) else {
            throw WebhookError.invalidURL
        }
        
        let payload = WebhookPayload(
            message: message,
            timestamp: Date(),
            userId: getDeviceId(),
            agentId: agent.id.uuidString,
            metadata: createMetadata(for: agent)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("N8N-iOS-App/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add authentication if configured
        if let authHeader = try? createAuthHeader(for: agent) {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try encoder.encode(payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebhookError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw WebhookError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return try decoder.decode(WebhookResponse.self, from: data)
    }
    
    func testConnection(for agent: Agent) async throws -> Bool {
        guard let url = URL(string: agent.webhookURL) else {
            throw WebhookError.invalidURL
        }
        
        let testPayload = WebhookTestPayload(
            test: true,
            timestamp: Date(),
            agentId: agent.id.uuidString
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try encoder.encode(testPayload)
        
        let (_, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebhookError.invalidResponse
        }
        
        return 200...299 ~= httpResponse.statusCode
    }
    
    func validateWebhook(_ urlString: String) async throws -> WebhookValidation {
        guard let url = URL(string: urlString),
              url.scheme == "https" || url.scheme == "http" else {
            return WebhookValidation(isValid: false, error: "Invalid URL format")
        }
        
        // Additional validation logic
        return WebhookValidation(isValid: true, error: nil)
    }
    
    // MARK: - Helper Methods
    private func getDeviceId() -> String {
        UIDevice.current.identifierForVendor?.uuidString ?? "unknown"
    }
    
    private func createMetadata(for agent: Agent) -> [String: Any] {
        return [
            "platform": "iOS",
            "appVersion": Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0",
            "deviceModel": UIDevice.current.model,
            "osVersion": UIDevice.current.systemVersion,
            "voiceEnabled": agent.isVoiceEnabled
        ]
    }
    
    private func createAuthHeader(for agent: Agent) throws -> String? {
        // Try to load webhook secret from keychain
        if let secret = try? KeychainService.shared.loadWebhookSecret(for: agent.webhookURL) {
            return "Bearer \(secret)"
        }
        return nil
    }
}

// MARK: - Data Models
struct WebhookPayload: Codable {
    let message: String
    let timestamp: Date
    let userId: String
    let agentId: String
    let metadata: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case message, timestamp, userId, agentId, metadata
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(message, forKey: .message)
        try container.encode(timestamp, forKey: .timestamp)
        try container.encode(userId, forKey: .userId)
        try container.encode(agentId, forKey: .agentId)
        
        // Convert metadata dictionary to encodable format
        let metadataData = try JSONSerialization.data(withJSONObject: metadata)
        let metadataJSON = try JSONSerialization.jsonObject(with: metadataData)
        try container.encode(metadataJSON as? [String: String], forKey: .metadata)
    }
}

struct WebhookResponse: Codable {
    let response: String
    let timestamp: Date
    let agentId: String?
    let metadata: [String: String]?
    let attachments: [WebhookAttachment]?
}

struct WebhookAttachment: Codable {
    let type: String
    let url: String
    let name: String?
    let size: Int64?
}

struct WebhookTestPayload: Codable {
    let test: Bool
    let timestamp: Date
    let agentId: String
}

struct WebhookValidation {
    let isValid: Bool
    let error: String?
}

// MARK: - Errors
enum WebhookError: LocalizedError {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case decodingError(Error)
    case networkError(Error)
    
    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid webhook URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .httpError(let statusCode, _):
            return "HTTP error: \(statusCode)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        }
    }
}