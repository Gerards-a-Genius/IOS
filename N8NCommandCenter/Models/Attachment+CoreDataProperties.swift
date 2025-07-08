//
//  Attachment+CoreDataProperties.swift
//  N8NCommandCenter
//
//  Core Data properties for Attachment entity
//

import Foundation
import CoreData

extension Attachment {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Attachment> {
        return NSFetchRequest<Attachment>(entityName: "Attachment")
    }
    
    @NSManaged public var fileName: String
    @NSManaged public var fileSize: Int64
    @NSManaged public var fileType: String
    @NSManaged public var id: UUID
    @NSManaged public var localPath: String?
    @NSManaged public var remoteURL: String?
    @NSManaged public var uploadedAt: Date
    @NSManaged public var message: Message?
}

extension Attachment: Identifiable {}