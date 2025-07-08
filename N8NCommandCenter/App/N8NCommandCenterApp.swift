//
//  N8NCommandCenterApp.swift
//  N8NCommandCenter
//
//  Main app entry point for N8N Command Center
//

import SwiftUI
import CoreData

@main
struct N8NCommandCenterApp: App {
    @StateObject private var databaseService = DatabaseService.shared
    @StateObject private var networkMonitor = NetworkMonitor()
    @State private var showingOnboarding = false
    
    init() {
        setupAppearance()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(databaseService)
                .environmentObject(networkMonitor)
                .environment(\.managedObjectContext, databaseService.viewContext)
                .onAppear {
                    checkFirstLaunch()
                }
        }
    }
    
    private func setupAppearance() {
        // Configure global app appearance
        UINavigationBar.appearance().largeTitleTextAttributes = [
            .foregroundColor: UIColor(Color.primary)
        ]
        
        // Set tint color for the entire app
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = UIColor(Color.accentColor)
    }
    
    private func checkFirstLaunch() {
        let hasLaunchedBefore = UserDefaults.standard.bool(forKey: "hasLaunchedBefore")
        if !hasLaunchedBefore {
            showingOnboarding = true
            UserDefaults.standard.set(true, forKey: "hasLaunchedBefore")
        }
    }
}

// MARK: - Color Extensions
extension Color {
    static let primaryBlue = Color(hex: "007AFF")
    static let successGreen = Color(hex: "34C759")
    static let accentOrange = Color(hex: "FF9500")
    static let backgroundGray = Color(hex: "F2F2F7")
    static let surfaceWhite = Color.white
    static let textPrimary = Color.black
    
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}