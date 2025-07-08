//
//  Conversation+CoreDataClass.swift
//  N8NCommandCenter
//
//  Core Data class for Conversation entity
//

import Foundation
import CoreData

@objc(Conversation)
public class Conversation: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Conversation.entity(), insertInto: context)
        self.id = UUID()
        self.createdAt = Date()
        self.lastMessageAt = Date()
        self.isArchived = false
    }
}

// MARK: - Conversation Extensions
extension Conversation {
    
    var sortedMessages: [Message] {
        let messages = self.messages?.allObjects as? [Message] ?? []
        return messages.sorted { $0.timestamp < $1.timestamp }
    }
    
    var lastMessage: Message? {
        sortedMessages.last
    }
    
    var unreadCount: Int {
        // This could be enhanced with actual read/unread tracking
        return 0
    }
    
    func addMessage(content: String, isFromUser: Bool, type: MessageType = .text, in context: NSManagedObjectContext) -> Message {
        let message = Message(context: context)
        message.content = content
        message.isFromUser = isFromUser
        message.messageType = type.rawValue
        message.conversation = self
        self.lastMessageAt = message.timestamp
        return message
    }
    
    var displayTitle: String {
        if let title = title, !title.isEmpty {
            return title
        } else if let firstMessage = sortedMessages.first {
            return String(firstMessage.content.prefix(50))
        } else {
            return "New Conversation"
        }
    }
}

// MARK: - Message Type
enum MessageType: String, CaseIterable {
    case text = "text"
    case voice = "voice"
    case image = "image"
    case file = "file"
    
    var systemImage: String {
        switch self {
        case .text: return "text.bubble"
        case .voice: return "mic.fill"
        case .image: return "photo"
        case .file: return "doc"
        }
    }
}