//
//  NetworkMonitor.swift
//  N8NCommandCenter
//
//  Network connectivity monitoring
//

import Foundation
import Network
import Combine

class NetworkMonitor: ObservableObject {
    @Published var isConnected = true
    @Published var connectionType: ConnectionType = .unknown
    @Published var isExpensive = false
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor", qos: .background)
    
    enum ConnectionType {
        case wifi
        case cellular
        case ethernet
        case unknown
        case none
        
        var displayName: String {
            switch self {
            case .wifi: return "Wi-Fi"
            case .cellular: return "Cellular"
            case .ethernet: return "Ethernet"
            case .unknown: return "Unknown"
            case .none: return "No Connection"
            }
        }
        
        var systemImage: String {
            switch self {
            case .wifi: return "wifi"
            case .cellular: return "antenna.radiowaves.left.and.right"
            case .ethernet: return "cable.connector"
            case .unknown: return "questionmark.circle"
            case .none: return "wifi.slash"
            }
        }
    }
    
    init() {
        startMonitoring()
    }
    
    deinit {
        stopMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
                self?.connectionType = self?.getConnectionType(from: path) ?? .none
                self?.isExpensive = path.isExpensive
            }
        }
        
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
    
    private func getConnectionType(from path: NWPath) -> ConnectionType {
        if path.status == .satisfied {
            if path.usesInterfaceType(.wifi) {
                return .wifi
            } else if path.usesInterfaceType(.cellular) {
                return .cellular
            } else if path.usesInterfaceType(.wiredEthernet) {
                return .ethernet
            } else {
                return .unknown
            }
        } else {
            return .none
        }
    }
    
    // MARK: - Convenience Methods
    var shouldUseReducedData: Bool {
        connectionType == .cellular || isExpensive
    }
    
    var canPerformBackgroundTasks: Bool {
        isConnected && !isExpensive
    }
}

// MARK: - Network Retry Manager
class RetryManager {
    enum RetryError: Error {
        case maxAttemptsReached
        case cancelled
    }
    
    static func executeWithRetry<T>(
        maxAttempts: Int = 3,
        initialDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        backoffMultiplier: Double = 2.0,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        var delay = initialDelay
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                
                // Don't retry on certain errors
                if error is CancellationError {
                    throw RetryError.cancelled
                }
                
                if attempt < maxAttempts {
                    // Exponential backoff with jitter
                    let jitter = Double.random(in: 0.8...1.2)
                    let actualDelay = min(delay * jitter, maxDelay)
                    
                    try await Task.sleep(nanoseconds: UInt64(actualDelay * 1_000_000_000))
                    
                    delay = min(delay * backoffMultiplier, maxDelay)
                }
            }
        }
        
        throw lastError ?? RetryError.maxAttemptsReached
    }
}