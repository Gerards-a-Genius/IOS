//
//  KeychainService.swift
//  N8NCommandCenter
//
//  Secure storage using iOS Keychain
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let service = "com.n8ncommandcenter.keychain"
    
    enum KeychainError: Error {
        case duplicateItem
        case itemNotFound
        case invalidData
        case unhandledError(status: OSStatus)
    }
    
    private init() {}
    
    // MARK: - Generic Operations
    func save<T: Codable>(_ item: T, for key: String) throws {
        let data = try JSONEncoder().encode(item)
        try save(data, for: key)
    }
    
    func load<T: Codable>(_ type: T.Type, for key: String) throws -> T {
        let data = try load(for: key)
        return try JSONDecoder().decode(type, from: data)
    }
    
    // MARK: - Data Operations
    func save(_ data: Data, for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Try to delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        guard status == errSecSuccess else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    func load(for key: String) throws -> Data {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess else {
            if status == errSecItemNotFound {
                throw KeychainError.itemNotFound
            }
            throw KeychainError.unhandledError(status: status)
        }
        
        guard let data = dataTypeRef as? Data else {
            throw KeychainError.invalidData
        }
        
        return data
    }
    
    func delete(for key: String) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: key
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError.unhandledError(status: status)
        }
    }
    
    // MARK: - Convenience Methods
    func saveAPIKey(_ key: String, for agentId: UUID) throws {
        let data = key.data(using: .utf8)!
        try save(data, for: "apikey_\(agentId.uuidString)")
    }
    
    func loadAPIKey(for agentId: UUID) throws -> String {
        let data = try load(for: "apikey_\(agentId.uuidString)")
        guard let key = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return key
    }
    
    func saveWebhookSecret(_ secret: String, for webhookURL: String) throws {
        let data = secret.data(using: .utf8)!
        let key = webhookURL.data(using: .utf8)!.base64EncodedString()
        try save(data, for: "webhook_\(key)")
    }
    
    func loadWebhookSecret(for webhookURL: String) throws -> String {
        let key = webhookURL.data(using: .utf8)!.base64EncodedString()
        let data = try load(for: "webhook_\(key)")
        guard let secret = String(data: data, encoding: .utf8) else {
            throw KeychainError.invalidData
        }
        return secret
    }
    
    // MARK: - Encryption Key Management
    private let encryptionKeyAccount = "local_encryption_key"
    
    func getOrCreateEncryptionKey() throws -> Data {
        do {
            return try load(for: encryptionKeyAccount)
        } catch KeychainError.itemNotFound {
            // Generate new key
            var keyData = Data(count: 32)
            let result = keyData.withUnsafeMutableBytes { bytes in
                SecRandomCopyBytes(kSecRandomDefault, 32, bytes.baseAddress!)
            }
            
            guard result == errSecSuccess else {
                throw KeychainError.unhandledError(status: result)
            }
            
            try save(keyData, for: encryptionKeyAccount)
            return keyData
        }
    }
}

// MARK: - Keychain Keys
struct KeychainKeys {
    static let apiKeys = "n8n_api_keys"
    static let webhookSecrets = "webhook_secrets"
    static let encryptionKey = "local_encryption_key"
    static let biometricSettings = "biometric_settings"
}

// MARK: - API Key Storage Model
struct APIKeyStorage: Codable {
    let agentId: UUID
    let keyType: String
    let encryptedKey: String
    let createdAt: Date
    let expiresAt: Date?
}