//
//  Agent+CoreDataClass.swift
//  N8NCommandCenter
//
//  Core Data class for Agent entity
//

import Foundation
import CoreData

@objc(Agent)
public class Agent: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Agent.entity(), insertInto: context)
        self.id = UUID()
        self.createdAt = Date()
        self.updatedAt = Date()
        self.iconName = "person.circle.fill"
        self.isVoiceEnabled = true
    }
    
    var voiceSettingsDecoded: VoiceSettings? {
        get {
            guard let data = voiceSettings else { return nil }
            return try? JSONDecoder().decode(VoiceSettings.self, from: data)
        }
        set {
            voiceSettings = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Voice Settings
struct VoiceSettings: Codable {
    var language: String = "en-US"
    var rate: Float = 0.5
    var pitch: Float = 1.0
    var volume: Float = 1.0
    var voiceIdentifier: String?
}

// MARK: - Agent Extensions
extension Agent {
    
    var activeConversations: [Conversation] {
        let conversations = self.conversations?.allObjects as? [Conversation] ?? []
        return conversations.filter { !$0.isArchived }
            .sorted { $0.lastMessageAt > $1.lastMessageAt }
    }
    
    var latestConversation: Conversation? {
        activeConversations.first
    }
    
    func createNewConversation(in context: NSManagedObjectContext) -> Conversation {
        let conversation = Conversation(context: context)
        conversation.agent = self
        conversation.title = "New Conversation"
        return conversation
    }
}