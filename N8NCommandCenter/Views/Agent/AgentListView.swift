//
//  AgentListView.swift
//  N8NCommandCenter
//
//  Agent management view
//

import SwiftUI

struct AgentListView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @State private var agents: [Agent] = []
    @State private var showingNewAgent = false
    @State private var selectedAgent: Agent?
    
    var body: some View {
        NavigationStack {
            List {
                if agents.isEmpty {
                    AgentEmptyStateView()
                } else {
                    ForEach(agents) { agent in
                        NavigationLink(destination: AgentDetailView(agent: agent)) {
                            AgentRow(agent: agent)
                        }
                    }
                    .onDelete(perform: deleteAgents)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Agents")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewAgent = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNewAgent) {
                AgentConfigurationView(agent: nil)
            }
            .onAppear {
                loadAgents()
            }
        }
    }
    
    private func loadAgents() {
        agents = databaseService.fetchAgents()
    }
    
    private func deleteAgents(at offsets: IndexSet) {
        for index in offsets {
            databaseService.deleteAgent(agents[index])
        }
        loadAgents()
    }
}

// MARK: - Agent Row
struct AgentRow: View {
    let agent: Agent
    
    var body: some View {
        HStack {
            Image(systemName: agent.iconName)
                .font(.title2)
                .foregroundColor(.primaryBlue)
                .frame(width: 50, height: 50)
                .background(Color.primaryBlue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                Text(agent.name)
                    .font(.headline)
                
                if let description = agent.desc {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(2)
                }
                
                HStack {
                    if agent.isVoiceEnabled {
                        Label("Voice", systemImage: "mic.fill")
                            .font(.caption)
                            .foregroundColor(.accentOrange)
                    }
                    
                    Label("\(agent.activeConversations.count) chats", systemImage: "message")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State
struct AgentEmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "person.2.circle")
                .font(.system(size: 60))
                .foregroundColor(.primaryBlue)
            
            Text("No agents configured")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Add your first N8N agent to start chatting")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - Agent Detail View
struct AgentDetailView: View {
    let agent: Agent
    @State private var showingEditAgent = false
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Agent Header
                HStack {
                    Image(systemName: agent.iconName)
                        .font(.system(size: 50))
                        .foregroundColor(.primaryBlue)
                        .frame(width: 80, height: 80)
                        .background(Color.primaryBlue.opacity(0.1))
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading) {
                        Text(agent.name)
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        if let description = agent.desc {
                            Text(description)
                                .font(.body)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(12)
                
                // Webhook Info
                VStack(alignment: .leading, spacing: 12) {
                    Label("Webhook URL", systemImage: "link")
                        .font(.headline)
                    
                    Text(agent.webhookURL)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(.secondary)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(8)
                }
                
                // Settings
                VStack(alignment: .leading, spacing: 16) {
                    Label("Settings", systemImage: "gearshape")
                        .font(.headline)
                    
                    Toggle("Voice Enabled", isOn: .constant(agent.isVoiceEnabled))
                        .disabled(true)
                    
                    if agent.isVoiceEnabled {
                        // Voice settings preview
                        HStack {
                            Text("Voice Settings")
                            Spacer()
                            Text("Default")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                // Statistics
                VStack(alignment: .leading, spacing: 16) {
                    Label("Statistics", systemImage: "chart.bar")
                        .font(.headline)
                    
                    HStack {
                        StatCard(title: "Conversations", value: "\(agent.activeConversations.count)", systemImage: "message")
                        StatCard(title: "Created", value: agent.createdAt.formatted(date: .abbreviated, time: .omitted), systemImage: "calendar")
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Agent Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Edit") {
                    showingEditAgent = true
                }
            }
        }
        .sheet(isPresented: $showingEditAgent) {
            AgentConfigurationView(agent: agent)
        }
    }
}

// MARK: - Stat Card
struct StatCard: View {
    let title: String
    let value: String
    let systemImage: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: systemImage)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.title3)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

// MARK: - Agent Configuration View
struct AgentConfigurationView: View {
    let agent: Agent?
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    
    @State private var name = ""
    @State private var description = ""
    @State private var webhookURL = ""
    @State private var iconName = "person.circle.fill"
    @State private var isVoiceEnabled = true
    @State private var isTesting = false
    @State private var testResult: Bool?
    
    var isEditing: Bool { agent != nil }
    
    var body: some View {
        NavigationView {
            Form {
                Section("Basic Information") {
                    TextField("Agent Name", text: $name)
                    TextField("Description (optional)", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                }
                
                Section("Webhook Configuration") {
                    TextField("Webhook URL", text: $webhookURL)
                        .keyboardType(.URL)
                        .autocapitalization(.none)
                    
                    Button(action: testWebhook) {
                        HStack {
                            if isTesting {
                                ProgressView()
                                    .scaleEffect(0.8)
                            } else {
                                Image(systemName: "network")
                            }
                            Text("Test Connection")
                            Spacer()
                            if let result = testResult {
                                Image(systemName: result ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .foregroundColor(result ? .green : .red)
                            }
                        }
                    }
                    .disabled(webhookURL.isEmpty || isTesting)
                }
                
                Section("Voice Settings") {
                    Toggle("Enable Voice", isOn: $isVoiceEnabled)
                }
                
                Section("Appearance") {
                    // Icon picker would go here
                    HStack {
                        Text("Icon")
                        Spacer()
                        Image(systemName: iconName)
                            .foregroundColor(.primaryBlue)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Agent" : "New Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveAgent()
                    }
                    .disabled(name.isEmpty || webhookURL.isEmpty)
                }
            }
            .onAppear {
                if let agent = agent {
                    name = agent.name
                    description = agent.desc ?? ""
                    webhookURL = agent.webhookURL
                    iconName = agent.iconName
                    isVoiceEnabled = agent.isVoiceEnabled
                }
            }
        }
    }
    
    private func testWebhook() {
        isTesting = true
        testResult = nil
        
        Task {
            do {
                let tempAgent = Agent(context: databaseService.viewContext)
                tempAgent.webhookURL = webhookURL
                
                let result = try await WebhookService.shared.testConnection(for: tempAgent)
                
                await MainActor.run {
                    testResult = result
                    isTesting = false
                }
                
                // Don't save the temp agent
                databaseService.viewContext.rollback()
            } catch {
                await MainActor.run {
                    testResult = false
                    isTesting = false
                }
            }
        }
    }
    
    private func saveAgent() {
        if let agent = agent {
            // Update existing
            agent.name = name
            agent.desc = description.isEmpty ? nil : description
            agent.webhookURL = webhookURL
            agent.iconName = iconName
            agent.isVoiceEnabled = isVoiceEnabled
            agent.updatedAt = Date()
        } else {
            // Create new
            _ = databaseService.createAgent(
                name: name,
                webhookURL: webhookURL,
                description: description.isEmpty ? nil : description
            )
        }
        
        databaseService.save()
        dismiss()
    }
}

// MARK: - Preview
struct AgentListView_Previews: PreviewProvider {
    static var previews: some View {
        AgentListView()
            .environmentObject(DatabaseService.shared)
    }
}