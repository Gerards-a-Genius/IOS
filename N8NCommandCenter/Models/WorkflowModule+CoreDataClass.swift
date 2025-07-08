//
//  WorkflowModule+CoreDataClass.swift
//  N8NCommandCenter
//
//  Core Data class for WorkflowModule entity
//

import Foundation
import CoreData

@objc(WorkflowModule)
public class WorkflowModule: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext) {
        self.init(entity: WorkflowModule.entity(), insertInto: context)
        self.id = UUID()
        self.createdAt = Date()
        self.isActive = true
    }
    
    var configurationDecoded: ModuleConfiguration? {
        get {
            guard let data = configuration else { return nil }
            return try? JSONDecoder().decode(ModuleConfiguration.self, from: data)
        }
        set {
            configuration = try? JSONEncoder().encode(newValue)
        }
    }
}

// MARK: - Module Configuration
struct ModuleConfiguration: Codable {
    let webhookURL: String?
    let inputFields: [InputField]
    let displaySettings: DisplaySettings
    let actionSettings: ActionSettings?
    let customProperties: [String: String]?
}

struct InputField: Codable, Identifiable {
    let id: UUID
    let name: String
    let type: FieldType
    let label: String
    let placeholder: String?
    let isRequired: Bool
    let validation: ValidationRule?
}

enum FieldType: String, Codable, CaseIterable {
    case text, number, email, password, date, toggle, picker, slider
}

struct ValidationRule: Codable {
    let type: ValidationType
    let value: String?
    let message: String?
}

enum ValidationType: String, Codable {
    case required, minLength, maxLength, regex, email, number
}

struct DisplaySettings: Codable {
    let widgetType: WidgetType
    let layout: LayoutType
    let colors: [String: String]?
}

enum WidgetType: String, Codable {
    case chart, table, metric, custom
}

enum LayoutType: String, Codable {
    case vertical, horizontal, grid
}

struct ActionSettings: Codable {
    let triggerType: TriggerType
    let confirmationRequired: Bool
    let successMessage: String?
    let errorMessage: String?
}

enum TriggerType: String, Codable {
    case button, automatic, scheduled
}