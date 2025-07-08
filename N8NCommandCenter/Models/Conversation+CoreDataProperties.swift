//
//  Conversation+CoreDataProperties.swift
//  N8NCommandCenter
//
//  Core Data properties for Conversation entity
//

import Foundation
import CoreData

extension Conversation {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Conversation> {
        return NSFetchRequest<Conversation>(entityName: "Conversation")
    }
    
    @NSManaged public var createdAt: Date
    @NSManaged public var id: UUID
    @NSManaged public var isArchived: Bool
    @NSManaged public var lastMessageAt: Date
    @NSManaged public var title: String?
    @NSManaged public var agent: Agent
    @NSManaged public var messages: NSSet?
}

// MARK: Generated accessors for messages
extension Conversation {
    
    @objc(addMessagesObject:)
    @NSManaged public func addToMessages(_ value: Message)
    
    @objc(removeMessagesObject:)
    @NSManaged public func removeFromMessages(_ value: Message)
    
    @objc(addMessages:)
    @NSManaged public func addToMessages(_ values: NSSet)
    
    @objc(removeMessages:)
    @NSManaged public func removeFromMessages(_ values: NSSet)
}

extension Conversation: Identifiable {}