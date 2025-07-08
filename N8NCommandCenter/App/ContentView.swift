//
//  ContentView.swift
//  N8NCommandCenter
//
//  Main navigation structure for the app
//

import SwiftUI

struct ContentView: View {
    @StateObject private var navigationState = NavigationState()
    @State private var selectedTab = TabItem.chat
    
    enum TabItem: String, CaseIterable {
        case chat = "Chat"
        case agents = "Agents"
        case modules = "Modules"
        case settings = "Settings"
        
        var systemImage: String {
            switch self {
            case .chat: return "message.fill"
            case .agents: return "person.2.fill"
            case .modules: return "square.grid.2x2.fill"
            case .settings: return "gearshape.fill"
            }
        }
    }
    
    var body: some View {
        TabView(selection: $selectedTab) {
            ChatHubView()
                .tabItem {
                    Label(TabItem.chat.rawValue, systemImage: TabItem.chat.systemImage)
                }
                .tag(TabItem.chat)
            
            AgentListView()
                .tabItem {
                    Label(TabItem.agents.rawValue, systemImage: TabItem.agents.systemImage)
                }
                .tag(TabItem.agents)
            
            ModulesView()
                .tabItem {
                    Label(TabItem.modules.rawValue, systemImage: TabItem.modules.systemImage)
                }
                .tag(TabItem.modules)
            
            SettingsView()
                .tabItem {
                    Label(TabItem.settings.rawValue, systemImage: TabItem.settings.systemImage)
                }
                .tag(TabItem.settings)
        }
        .accentColor(.primaryBlue)
        .environmentObject(navigationState)
    }
}

// MARK: - Navigation State
class NavigationState: ObservableObject {
    @Published var selectedAgent: Agent?
    @Published var selectedConversation: Conversation?
    @Published var isShowingNewAgent = false
    @Published var isShowingNewModule = false
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(DatabaseService.shared)
            .environment(\.managedObjectContext, DatabaseService.shared.viewContext)
    }
}