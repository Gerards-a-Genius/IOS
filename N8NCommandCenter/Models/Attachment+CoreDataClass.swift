//
//  Attachment+CoreDataClass.swift
//  N8NCommandCenter
//
//  Core Data class for Attachment entity
//

import Foundation
import CoreData

@objc(Attachment)
public class Attachment: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: Attachment.entity(), insertInto: context)
        self.id = UUID()
        self.uploadedAt = Date()
    }
}

// MARK: - Attachment Extensions
extension Attachment {
    
    var fileExtension: String {
        URL(string: fileName)?.pathExtension ?? ""
    }
    
    var isImage: Bool {
        let imageExtensions = ["jpg", "jpeg", "png", "gif", "webp", "heic"]
        return imageExtensions.contains(fileExtension.lowercased())
    }
    
    var isAudio: Bool {
        let audioExtensions = ["mp3", "m4a", "wav", "aac"]
        return audioExtensions.contains(fileExtension.lowercased())
    }
    
    var formattedFileSize: String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: fileSize)
    }
}