# N8N iOS App: Technical Specifications & Architecture

## 🏗️ System Architecture Overview

### High-Level Architecture
```
┌─────────────────────────────────────────────────────────┐
│                    iOS Application                      │
├─────────────────────────────────────────────────────────┤
│  Presentation Layer (SwiftUI)                          │
│  ├── Chat Interface                                    │
│  ├── Voice Interface                                   │
│  ├── Module Builder                                    │
│  └── Settings & Configuration                          │
├─────────────────────────────────────────────────────────┤
│  Business Logic Layer                                  │
│  ├── Agent Manager                                     │
│  ├── Webhook Service                                   │
│  ├── Voice Processing                                  │
│  └── Module Engine                                     │
├─────────────────────────────────────────────────────────┤
│  Data Layer                                            │
│  ├── Core Data (Local Storage)                        │
│  ├── Keychain (Secure Storage)                        │
│  ├── Network Layer                                     │
│  └── File System                                       │
├─────────────────────────────────────────────────────────┤
│  External Integrations                                 │
│  ├── N8N Webhook APIs                                 │
│  ├── Speech Recognition                                │
│  ├── Text-to-Speech                                   │
│  └── Push Notifications                               │
└─────────────────────────────────────────────────────────┘
```

---

## 📱 Technical Stack Recommendations

### Core Technologies
- **Framework:** SwiftUI + UIKit (for advanced features)
- **Architecture:** MVVM + Coordinator Pattern
- **Reactive Programming:** Combine Framework
- **Local Storage:** Core Data + SQLite
- **Secure Storage:** Keychain Services
- **Networking:** URLSession + Alamofire
- **Voice Processing:** AVFoundation + Speech Framework

### Third-Party Dependencies
```swift
// Package.swift dependencies
dependencies: [
    .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
    .package(url: "https://github.com/apple/swift-markdown.git", from: "0.3.0"),
    .package(url: "https://github.com/krzyzanowskim/CryptoSwift.git", from: "1.8.0"),
    .package(url: "https://github.com/realm/realm-swift.git", from: "10.45.0"), // Alternative to Core Data
    .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.0"), // Image caching
]
```

---

## 🗄️ Data Architecture

### Core Data Model
```swift
// Agent Entity
@objc(Agent)
public class Agent: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var description: String?
    @NSManaged public var webhookURL: String
    @NSManaged public var iconName: String
    @NSManaged public var isVoiceEnabled: Bool
    @NSManaged public var voiceSettings: Data? // JSON encoded
    @NSManaged public var createdAt: Date
    @NSManaged public var updatedAt: Date
    @NSManaged public var conversations: NSSet?
}

// Conversation Entity
@objc(Conversation)
public class Conversation: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var title: String?
    @NSManaged public var lastMessageAt: Date
    @NSManaged public var isArchived: Bool
    @NSManaged public var agent: Agent
    @NSManaged public var messages: NSSet?
}

// Message Entity
@objc(Message)
public class Message: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var content: String
    @NSManaged public var isFromUser: Bool
    @NSManaged public var timestamp: Date
    @NSManaged public var messageType: String // text, voice, image, file
    @NSManaged public var metadata: Data? // JSON encoded
    @NSManaged public var conversation: Conversation
    @NSManaged public var attachments: NSSet?
}

// WorkflowModule Entity
@objc(WorkflowModule)
public class WorkflowModule: NSManagedObject {
    @NSManaged public var id: UUID
    @NSManaged public var name: String
    @NSManaged public var type: String // input, display, action
    @NSManaged public var configuration: Data // JSON encoded
    @NSManaged public var webhookURL: String?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdAt: Date
}
```

### Keychain Storage Structure
```swift
// Secure storage for sensitive data
struct KeychainKeys {
    static let apiKeys = "n8n_api_keys"
    static let webhookSecrets = "webhook_secrets"
    static let encryptionKey = "local_encryption_key"
    static let biometricSettings = "biometric_settings"
}

// API Key storage format
struct APIKeyStorage: Codable {
    let agentId: UUID
    let keyType: String // openai, claude, custom
    let encryptedKey: String
    let createdAt: Date
    let expiresAt: Date?
}
```

---

## 🌐 Network Architecture

### Webhook Service Implementation
```swift
protocol WebhookServiceProtocol {
    func sendMessage(_ message: String, to agent: Agent) async throws -> WebhookResponse
    func testConnection(for agent: Agent) async throws -> Bool
    func validateWebhook(_ url: String) async throws -> WebhookValidation
}

class WebhookService: WebhookServiceProtocol {
    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder
    
    init() {
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 30
        config.timeoutIntervalForResource = 60
        self.session = URLSession(configuration: config)
        self.encoder = JSONEncoder()
        self.decoder = JSONDecoder()
    }
    
    func sendMessage(_ message: String, to agent: Agent) async throws -> WebhookResponse {
        guard let url = URL(string: agent.webhookURL) else {
            throw WebhookError.invalidURL
        }
        
        let payload = WebhookPayload(
            message: message,
            timestamp: Date(),
            userId: UIDevice.current.identifierForVendor?.uuidString ?? "unknown",
            metadata: createMetadata(for: agent)
        )
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("N8N-iOS-App/1.0", forHTTPHeaderField: "User-Agent")
        
        // Add authentication if configured
        if let authHeader = createAuthHeader(for: agent) {
            request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        }
        
        request.httpBody = try encoder.encode(payload)
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw WebhookError.invalidResponse
        }
        
        guard 200...299 ~= httpResponse.statusCode else {
            throw WebhookError.httpError(httpResponse.statusCode)
        }
        
        return try decoder.decode(WebhookResponse.self, from: data)
    }
}

// Webhook payload structure
struct WebhookPayload: Codable {
    let message: String
    let timestamp: Date
    let userId: String
    let metadata: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case message, timestamp, userId, metadata
    }
}

// Webhook response structure
struct WebhookResponse: Codable {
    let response: String
    let timestamp: Date
    let agentId: String?
    let metadata: [String: Any]?
    let attachments: [WebhookAttachment]?
}
```

### Network Monitoring & Retry Logic
```swift
class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .wifi
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    enum ConnectionType {
        case wifi, cellular, ethernet, none
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .none
            }
        }
        monitor.start(queue: queue)
    }
}

class RetryManager {
    static func executeWithRetry<T>(
        maxAttempts: Int = 3,
        delay: TimeInterval = 1.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                if attempt < maxAttempts {
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        throw lastError ?? RetryError.maxAttemptsReached
    }
}
```

---

## 🎤 Voice Processing Architecture

### Speech Recognition Implementation
```swift
class VoiceManager: NSObject, ObservableObject {
    @Published var isListening = false
    @Published var recognizedText = ""
    @Published var audioLevel: Float = 0.0
    
    private let speechRecognizer: SFSpeechRecognizer?
    private let audioEngine = AVAudioEngine()
    private var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    private var recognitionTask: SFSpeechRecognitionTask?
    
    override init() {
        speechRecognizer = SFSpeechRecognizer(locale: Locale.current)
        super.init()
        setupAudioSession()
    }
    
    func startListening() async throws {
        guard let speechRecognizer = speechRecognizer,
              speechRecognizer.isAvailable else {
            throw VoiceError.speechRecognitionUnavailable
        }
        
        try await requestPermissions()
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        guard let recognitionRequest = recognitionRequest else {
            throw VoiceError.unableToCreateRequest
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { buffer, _ in
            recognitionRequest.append(buffer)
            
            // Calculate audio level for visualization
            let level = self.calculateAudioLevel(from: buffer)
            DispatchQueue.main.async {
                self.audioLevel = level
            }
        }
        
        audioEngine.prepare()
        try audioEngine.start()
        
        isListening = true
        
        recognitionTask = speechRecognizer.recognitionTask(with: recognitionRequest) { result, error in
            if let result = result {
                DispatchQueue.main.async {
                    self.recognizedText = result.bestTranscription.formattedString
                }
            }
            
            if error != nil || result?.isFinal == true {
                self.stopListening()
            }
        }
    }
    
    func stopListening() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        recognitionRequest?.endAudio()
        recognitionTask?.cancel()
        
        recognitionRequest = nil
        recognitionTask = nil
        isListening = false
    }
}

// Text-to-Speech Implementation
class TextToSpeechManager: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isSpeaking = false
    
    func speak(_ text: String, voice: VoiceSettings) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: voice.language)
        utterance.rate = voice.rate
        utterance.pitchMultiplier = voice.pitch
        utterance.volume = voice.volume
        
        synthesizer.speak(utterance)
        isSpeaking = true
    }
    
    func stopSpeaking() {
        synthesizer.stopSpeaking(at: .immediate)
        isSpeaking = false
    }
}
```

---

## 🔒 Security Architecture

### Encryption & Secure Storage
```swift
class SecurityManager {
    private let keychain = Keychain(service: "com.yourapp.n8n-command-center")
    
    // Generate and store encryption key
    func generateEncryptionKey() throws -> Data {
        let key = Data((0..<32).map { _ in UInt8.random(in: 0...255) })
        try keychain.set(key, key: KeychainKeys.encryptionKey)
        return key
    }
    
    // Encrypt sensitive data
    func encrypt(_ data: Data) throws -> Data {
        guard let key = try keychain.getData(KeychainKeys.encryptionKey) else {
            throw SecurityError.encryptionKeyNotFound
        }
        
        return try AES(key: key.bytes, blockMode: GCM(), variant: .aes256)
            .encrypt(data.bytes)
            .data
    }
    
    // Store API key securely
    func storeAPIKey(_ key: String, for agentId: UUID, type: String) throws {
        let apiKeyData = APIKeyStorage(
            agentId: agentId,
            keyType: type,
            encryptedKey: try encrypt(key.data(using: .utf8)!).base64EncodedString(),
            createdAt: Date(),
            expiresAt: nil
        )
        
        let encodedData = try JSONEncoder().encode(apiKeyData)
        try keychain.set(encodedData, key: "\(KeychainKeys.apiKeys)_\(agentId)")
    }
}

// Biometric Authentication
class BiometricAuthManager {
    func authenticateUser() async throws -> Bool {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            throw BiometricError.biometricUnavailable
        }
        
        let reason = "Authenticate to access your N8N agents"
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: reason
            )
            return success
        } catch {
            throw BiometricError.authenticationFailed
        }
    }
}
```

---

## 🧩 Modular System Architecture

### Dynamic Module Engine
```swift
protocol WorkflowModule {
    var id: UUID { get }
    var name: String { get }
    var type: ModuleType { get }
    var configuration: ModuleConfiguration { get set }
    
    func render() -> AnyView
    func execute(with input: [String: Any]) async throws -> ModuleResult
    func validate() throws
}

enum ModuleType: String, CaseIterable {
    case inputForm = "input_form"
    case displayWidget = "display_widget"
    case actionButton = "action_button"
    case dataVisualization = "data_viz"
    case customComponent = "custom"
}

struct ModuleConfiguration: Codable {
    let webhookURL: String?
    let inputFields: [InputField]
    let displaySettings: DisplaySettings
    let actionSettings: ActionSettings?
}

// Input Form Module Implementation
class InputFormModule: WorkflowModule {
    let id = UUID()
    let name: String
    let type = ModuleType.inputForm
    var configuration: ModuleConfiguration
    
    @State private var formData: [String: Any] = [:]
    
    func render() -> AnyView {
        AnyView(
            VStack(spacing: 16) {
                Text(name)
                    .font(.headline)
                
                ForEach(configuration.inputFields, id: \.id) { field in
                    DynamicInputField(field: field) { value in
                        formData[field.name] = value
                    }
                }
                
                Button("Submit") {
                    Task {
                        try await execute(with: formData)
                    }
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        )
    }
    
    func execute(with input: [String: Any]) async throws -> ModuleResult {
        guard let webhookURL = configuration.webhookURL,
              let url = URL(string: webhookURL) else {
            throw ModuleError.invalidConfiguration
        }
        
        // Send data to webhook
        let payload = ModulePayload(
            moduleId: id,
            data: input,
            timestamp: Date()
        )
        
        // Implementation of webhook call
        // ...
        
        return ModuleResult(success: true, data: [:])
    }
}

// Module Builder Interface
class ModuleBuilder: ObservableObject {
    @Published var modules: [WorkflowModule] = []
    @Published var selectedModule: WorkflowModule?
    
    func createModule(type: ModuleType, configuration: ModuleConfiguration) -> WorkflowModule {
        switch type {
        case .inputForm:
            return InputFormModule(name: "New Form", configuration: configuration)
        case .displayWidget:
            return DisplayWidgetModule(name: "New Widget", configuration: configuration)
        case .actionButton:
            return ActionButtonModule(name: "New Action", configuration: configuration)
        case .dataVisualization:
            return DataVisualizationModule(name: "New Chart", configuration: configuration)
        case .customComponent:
            return CustomModule(name: "Custom Module", configuration: configuration)
        }
    }
}
```

---

## 📊 Performance Optimization

### Memory Management
```swift
class MemoryManager {
    static let shared = MemoryManager()
    
    private var imageCache = NSCache<NSString, UIImage>()
    private var conversationCache = NSCache<NSString, Conversation>()
    
    init() {
        setupCacheConfiguration()
        observeMemoryWarnings()
    }
    
    private func setupCacheConfiguration() {
        imageCache.countLimit = 100
        imageCache.totalCostLimit = 50 * 1024 * 1024 // 50MB
        
        conversationCache.countLimit = 50
        conversationCache.totalCostLimit = 10 * 1024 * 1024 // 10MB
    }
    
    private func observeMemoryWarnings() {
        NotificationCenter.default.addObserver(
            forName: UIApplication.didReceiveMemoryWarningNotification,
            object: nil,
            queue: .main
        ) { _ in
            self.clearCaches()
        }
    }
    
    func clearCaches() {
        imageCache.removeAllObjects()
        conversationCache.removeAllObjects()
    }
}

// Background Task Management
class BackgroundTaskManager {
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    func beginBackgroundTask() {
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
    }
    
    func endBackgroundTask() {
        if backgroundTask != .invalid {
            UIApplication.shared.endBackgroundTask(backgroundTask)
            backgroundTask = .invalid
        }
    }
}
```

### Database Optimization
```swift
class DatabaseManager {
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "N8NApp")
        
        // Configure for performance
        let description = container.persistentStoreDescriptions.first
        description?.shouldInferMappingModelAutomatically = true
        description?.shouldMigrateStoreAutomatically = true
        description?.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        description?.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        
        container.loadPersistentStores { _, error in
            if let error = error {
                fatalError("Core Data error: \(error)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    func saveContext() {
        let context = persistentContainer.viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Save error: \(error)")
            }
        }
    }
    
    // Batch operations for performance
    func batchDeleteOldMessages(olderThan date: Date) async throws {
        let request = NSBatchDeleteRequest(fetchRequest: Message.fetchRequest())
        request.predicate = NSPredicate(format: "timestamp < %@", date as NSDate)
        
        try await persistentContainer.performBackgroundTask { context in
            try context.execute(request)
            try context.save()
        }
    }
}
```

---

## 🔧 Configuration Management

### App Configuration
```swift
struct AppConfiguration {
    // Network settings
    static let defaultTimeout: TimeInterval = 30
    static let maxRetryAttempts = 3
    static let maxConcurrentRequests = 5
    
    // Voice settings
    static let defaultVoiceLanguage = "en-US"
    static let voiceRecognitionTimeout: TimeInterval = 5
    static let maxRecordingDuration: TimeInterval = 60
    
    // Storage settings
    static let maxConversationHistory = 1000
    static let maxFileSize: Int64 = 10 * 1024 * 1024 // 10MB
    static let cacheExpirationDays = 30
    
    // Security settings
    static let biometricTimeout: TimeInterval = 300 // 5 minutes
    static let maxFailedAttempts = 5
    static let keyRotationInterval: TimeInterval = 30 * 24 * 60 * 60 // 30 days
}

// Environment Configuration
enum Environment {
    case development
    case staging
    case production
    
    var baseURL: String {
        switch self {
        case .development:
            return "https://dev.n8n.yourcompany.com"
        case .staging:
            return "https://staging.n8n.yourcompany.com"
        case .production:
            return "https://n8n.yourcompany.com"
        }
    }
}
```

---

This comprehensive technical specification provides a solid foundation for implementing your N8N iOS app with enterprise-grade architecture, security, and performance considerations.

