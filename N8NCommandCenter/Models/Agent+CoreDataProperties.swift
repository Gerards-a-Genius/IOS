//
//  Agent+CoreDataProperties.swift
//  N8NCommandCenter
//
//  Core Data properties for Agent entity
//

import Foundation
import CoreData

extension Agent {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Agent> {
        return NSFetchRequest<Agent>(entityName: "Agent")
    }
    
    @NSManaged public var createdAt: Date
    @NSManaged public var desc: String?
    @NSManaged public var iconName: String
    @NSManaged public var id: UUID
    @NSManaged public var isVoiceEnabled: Bool
    @NSManaged public var name: String
    @NSManaged public var updatedAt: Date
    @NSManaged public var voiceSettings: Data?
    @NSManaged public var webhookURL: String
    @NSManaged public var conversations: NSSet?
}

// MARK: Generated accessors for conversations
extension Agent {
    
    @objc(addConversationsObject:)
    @NSManaged public func addToConversations(_ value: Conversation)
    
    @objc(removeConversationsObject:)
    @NSManaged public func removeFromConversations(_ value: Conversation)
    
    @objc(addConversations:)
    @NSManaged public func addToConversations(_ values: NSSet)
    
    @objc(removeConversations:)
    @NSManaged public func removeFromConversations(_ values: NSSet)
}

extension Agent: Identifiable {}