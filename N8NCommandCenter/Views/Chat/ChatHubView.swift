//
//  ChatHubView.swift
//  N8NCommandCenter
//
//  Main chat interface showing conversation list
//

import SwiftUI
import CoreData

struct ChatHubView: View {
    @EnvironmentObject var databaseService: DatabaseService
    @StateObject private var viewModel = ChatHubViewModel()
    @State private var showingNewChat = false
    @State private var selectedAgent: Agent?
    
    var body: some View {
        NavigationStack {
            List {
                if viewModel.conversations.isEmpty {
                    EmptyStateView()
                } else {
                    ForEach(viewModel.conversations) { conversation in
                        NavigationLink(destination: ChatView(conversation: conversation)) {
                            ConversationRow(conversation: conversation)
                        }
                    }
                    .onDelete(perform: deleteConversations)
                }
            }
            .listStyle(PlainListStyle())
            .navigationTitle("Chats")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingNewChat = true }) {
                        Image(systemName: "square.and.pencil")
                    }
                }
            }
            .sheet(isPresented: $showingNewChat) {
                NewChatView(selectedAgent: $selectedAgent)
            }
            .refreshable {
                await viewModel.refreshConversations()
            }
            .onAppear {
                viewModel.loadConversations()
            }
        }
    }
    
    private func deleteConversations(at offsets: IndexSet) {
        for index in offsets {
            let conversation = viewModel.conversations[index]
            databaseService.archiveConversation(conversation)
        }
        viewModel.loadConversations()
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: Conversation
    
    var body: some View {
        HStack {
            // Agent Icon
            Image(systemName: conversation.agent.iconName)
                .font(.title2)
                .foregroundColor(.primaryBlue)
                .frame(width: 50, height: 50)
                .background(Color.primaryBlue.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.agent.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if let lastMessage = conversation.lastMessage {
                        Text(lastMessage.formattedTimestamp)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Text(conversation.displayTitle)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
                
                if let lastMessage = conversation.lastMessage {
                    HStack(spacing: 4) {
                        if lastMessage.messageTypeEnum == .voice {
                            Image(systemName: "mic.fill")
                                .font(.caption)
                                .foregroundColor(.accentOrange)
                        }
                        
                        Text(lastMessage.content)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "message.circle")
                .font(.system(size: 60))
                .foregroundColor(.primaryBlue)
            
            Text("No conversations yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a new chat with your N8N agents")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

// MARK: - View Model
class ChatHubViewModel: ObservableObject {
    @Published var conversations: [Conversation] = []
    @Published var isLoading = false
    
    private let databaseService = DatabaseService.shared
    
    func loadConversations() {
        conversations = databaseService.fetchConversations()
    }
    
    @MainActor
    func refreshConversations() async {
        isLoading = true
        
        // Simulate network delay for now
        try? await Task.sleep(nanoseconds: 500_000_000)
        
        loadConversations()
        isLoading = false
    }
}

// MARK: - New Chat View
struct NewChatView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var databaseService: DatabaseService
    @Binding var selectedAgent: Agent?
    @State private var agents: [Agent] = []
    
    var body: some View {
        NavigationView {
            List(agents) { agent in
                Button(action: {
                    createNewChat(with: agent)
                }) {
                    HStack {
                        Image(systemName: agent.iconName)
                            .font(.title2)
                            .foregroundColor(.primaryBlue)
                            .frame(width: 40, height: 40)
                            .background(Color.primaryBlue.opacity(0.1))
                            .clipShape(Circle())
                        
                        VStack(alignment: .leading) {
                            Text(agent.name)
                                .font(.headline)
                            
                            if let description = agent.desc {
                                Text(description)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            }
                        }
                        
                        Spacer()
                        
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .buttonStyle(PlainButtonStyle())
            }
            .navigationTitle("Select Agent")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .onAppear {
                agents = databaseService.fetchAgents()
            }
        }
    }
    
    private func createNewChat(with agent: Agent) {
        let conversation = agent.createNewConversation(in: databaseService.viewContext)
        databaseService.save()
        selectedAgent = agent
        dismiss()
        
        // Navigate to the new conversation
        // This would be handled by the navigation system
    }
}

// MARK: - Preview
struct ChatHubView_Previews: PreviewProvider {
    static var previews: some View {
        ChatHubView()
            .environmentObject(DatabaseService.shared)
    }
}