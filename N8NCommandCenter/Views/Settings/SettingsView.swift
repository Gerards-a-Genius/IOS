//
//  SettingsView.swift
//  N8NCommandCenter
//
//  App settings and preferences
//

import SwiftUI

struct SettingsView: View {
    @AppStorage("usesBiometricAuth") private var usesBiometricAuth = false
    @AppStorage("messageRetentionDays") private var messageRetentionDays = 30
    @AppStorage("voiceLanguage") private var voiceLanguage = "en-US"
    
    var body: some View {
        NavigationStack {
            Form {
                // Security Section
                Section("Security") {
                    Toggle("Biometric Authentication", isOn: $usesBiometricAuth)
                    
                    Button(action: {}) {
                        HStack {
                            Text("Manage API Keys")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Data & Storage
                Section("Data & Storage") {
                    HStack {
                        Text("Message Retention")
                        Spacer()
                        Text("\(messageRetentionDays) days")
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: clearCache) {
                        Text("Clear Cache")
                            .foregroundColor(.red)
                    }
                }
                
                // Voice Settings
                Section("Voice Settings") {
                    HStack {
                        Text("Language")
                        Spacer()
                        Text(voiceLanguage)
                            .foregroundColor(.secondary)
                    }
                    
                    Button(action: {}) {
                        HStack {
                            Text("Voice Preferences")
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // About
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Documentation", destination: URL(string: "https://n8n.io")!)
                    
                    Link("Privacy Policy", destination: URL(string: "https://n8n.io/privacy")!)
                }
                
                // Developer
                Section("Developer") {
                    Button(action: {}) {
                        HStack {
                            Text("Export Logs")
                            Spacer()
                            Image(systemName: "square.and.arrow.up")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Button(action: {}) {
                        Text("Reset App")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Settings")
        }
    }
    
    private func clearCache() {
        // Implement cache clearing
    }
}

// MARK: - Preview
struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView()
    }
}