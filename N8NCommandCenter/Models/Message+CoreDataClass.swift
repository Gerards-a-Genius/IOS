//
//  Message+CoreDataClass.swift
//  N8NCommandCenter
//
//  Core Data class for Message entity
//

import Foundation
import CoreData

@objc(Message)
public class Message: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Message.entity(), insertInto: context)
        self.id = UUID()
        self.timestamp = Date()
        self.messageType = MessageType.text.rawValue
    }
    
    var metadataDecoded: MessageMetadata? {
        get {
            guard let data = metadata else { return nil }
            return try? JSONDecoder().decode(MessageMetadata.self, from: data)
        }
        set {
            metadata = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Message Metadata
struct MessageMetadata: Codable {
    var webhookResponseTime: TimeInterval?
    var voiceDuration: TimeInterval?
    var errorMessage: String?
    var retryCount: Int?
    var customData: [String: String]?
}

// MARK: - Message Extensions
extension Message {
    
    var messageTypeEnum: MessageType {
        MessageType(rawValue: messageType) ?? .text
    }
    
    var sortedAttachments: [Attachment] {
        let attachments = self.attachments?.allObjects as? [Attachment] ?? []
        return attachments.sorted { $0.uploadedAt < $1.uploadedAt }
    }
    
    var hasAttachments: Bool {
        (attachments?.count ?? 0) > 0
    }
    
    var formattedTimestamp: String {
        let formatter = DateFormatter()
        let calendar = Calendar.current
        
        if calendar.isDateInToday(timestamp) {
            formatter.dateFormat = "h:mm a"
        } else if calendar.isDateInYesterday(timestamp) {
            formatter.dateFormat = "'Yesterday' h:mm a"
        } else if calendar.isDate(timestamp, equalTo: Date(), toGranularity: .weekOfYear) {
            formatter.dateFormat = "EEEE h:mm a"
        } else {
            formatter.dateFormat = "MMM d, h:mm a"
        }
        
        return formatter.string(from: timestamp)
    }
}