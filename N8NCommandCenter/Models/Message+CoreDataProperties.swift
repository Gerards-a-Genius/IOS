//
//  Message+CoreDataProperties.swift
//  N8NCommandCenter
//
//  Core Data properties for Message entity
//

import Foundation
import CoreData

extension Message {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Message> {
        return NSFetchRequest<Message>(entityName: "Message")
    }
    
    @NSManaged public var content: String
    @NSManaged public var id: UUID
    @NSManaged public var isFromUser: Bool
    @NSManaged public var messageType: String
    @NSManaged public var metadata: Data?
    @NSManaged public var timestamp: Date
    @NSManaged public var attachments: NSSet?
    @NSManaged public var conversation: Conversation
}

// MARK: Generated accessors for attachments
extension Message {
    
    @objc(addAttachmentsObject:)
    @NSManaged public func addToAttachments(_ value: Attachment)
    
    @objc(removeAttachmentsObject:)
    @NSManaged public func removeFromAttachments(_ value: Attachment)
    
    @objc(addAttachments:)
    @NSManaged public func addToAttachments(_ values: NSSet)
    
    @objc(removeAttachments:)
    @NSManaged public func removeFromAttachments(_ values: NSSet)
}

extension Message: Identifiable {}