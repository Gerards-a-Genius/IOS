//
//  WorkflowModule+CoreDataProperties.swift
//  N8NCommandCenter
//
//  Core Data properties for WorkflowModule entity
//

import Foundation
import CoreData

extension WorkflowModule {
    
    @nonobjc public class func fetchRequest() -> NSFetchRequest<WorkflowModule> {
        return NSFetchRequest<WorkflowModule>(entityName: "WorkflowModule")
    }
    
    @NSManaged public var configuration: Data
    @NSManaged public var createdAt: Date
    @NSManaged public var id: UUID
    @NSManaged public var isActive: Bool
    @NSManaged public var name: String
    @NSManaged public var type: String
    @NSManaged public var webhookURL: String?
}

extension WorkflowModule: Identifiable {}