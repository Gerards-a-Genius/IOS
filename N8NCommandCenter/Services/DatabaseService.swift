//
//  DatabaseService.swift
//  N8NCommandCenter
//
//  Core Data stack and database operations
//

import Foundation
import CoreData
import Combine

class DatabaseService: ObservableObject {
    static let shared = DatabaseService()
    
    // MARK: - Core Data Stack
    lazy var persistentContainer: NSPersistentContainer = {
        let container = NSPersistentContainer(name: "N8NDataModel")
        
        // Configure for performance
        if let description = container.persistentStoreDescriptions.first {
            description.shouldInferMappingModelAutomatically = true
            description.shouldMigrateStoreAutomatically = true
            description.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
            description.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        }
        
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                // In production, handle this error appropriately
                fatalError("Core Data failed to load: \(error), \(error.userInfo)")
            }
        }
        
        container.viewContext.automaticallyMergesChangesFromParent = true
        return container
    }()
    
    var viewContext: NSManagedObjectContext {
        persistentContainer.viewContext
    }
    
    // MARK: - Init
    private init() {
        setupNotifications()
    }
    
    // MARK: - Core Data Operations
    func save() {
        let context = viewContext
        
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                print("Failed to save context: \(error)")
            }
        }
    }
    
    func performBackgroundTask<T>(_ block: @escaping (NSManagedObjectContext) throws -> T) async throws -> T {
        try await persistentContainer.performBackgroundTask { context in
            try block(context)
        }
    }
    
    // MARK: - Agent Operations
    func createAgent(name: String, webhookURL: String, description: String? = nil) -> Agent {
        let agent = Agent(context: viewContext)
        agent.name = name
        agent.webhookURL = webhookURL
        agent.desc = description
        save()
        return agent
    }
    
    func fetchAgents() -> [Agent] {
        let request = Agent.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Agent.createdAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch agents: \(error)")
            return []
        }
    }
    
    func deleteAgent(_ agent: Agent) {
        viewContext.delete(agent)
        save()
    }
    
    // MARK: - Conversation Operations
    func fetchConversations(for agent: Agent? = nil, includeArchived: Bool = false) -> [Conversation] {
        let request = Conversation.fetchRequest()
        
        var predicates: [NSPredicate] = []
        
        if let agent = agent {
            predicates.append(NSPredicate(format: "agent == %@", agent))
        }
        
        if !includeArchived {
            predicates.append(NSPredicate(format: "isArchived == %@", NSNumber(value: false)))
        }
        
        if !predicates.isEmpty {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: predicates)
        }
        
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Conversation.lastMessageAt, ascending: false)]
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch conversations: \(error)")
            return []
        }
    }
    
    func archiveConversation(_ conversation: Conversation) {
        conversation.isArchived = true
        save()
    }
    
    // MARK: - Message Operations
    func addMessage(to conversation: Conversation, content: String, isFromUser: Bool, type: MessageType = .text) -> Message {
        let message = conversation.addMessage(
            content: content,
            isFromUser: isFromUser,
            type: type,
            in: viewContext
        )
        save()
        return message
    }
    
    func deleteMessage(_ message: Message) {
        viewContext.delete(message)
        save()
    }
    
    func fetchRecentMessages(limit: Int = 100) -> [Message] {
        let request = Message.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Message.timestamp, ascending: false)]
        request.fetchLimit = limit
        
        do {
            return try viewContext.fetch(request)
        } catch {
            print("Failed to fetch messages: \(error)")
            return []
        }
    }
    
    // MARK: - Cleanup Operations
    func deleteOldMessages(olderThan date: Date) async throws {
        try await performBackgroundTask { context in
            let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Message")
            request.predicate = NSPredicate(format: "timestamp < %@", date as NSDate)
            
            let batchDelete = NSBatchDeleteRequest(fetchRequest: request)
            batchDelete.resultType = .resultTypeCount
            
            let result = try context.execute(batchDelete) as? NSBatchDeleteResult
            print("Deleted \(result?.result as? Int ?? 0) old messages")
            
            try context.save()
        }
    }
    
    // MARK: - Notifications
    private func setupNotifications() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(contextDidSave),
            name: .NSManagedObjectContextDidSave,
            object: nil
        )
    }
    
    @objc private func contextDidSave(_ notification: Notification) {
        guard let context = notification.object as? NSManagedObjectContext,
              context != viewContext else { return }
        
        viewContext.perform {
            self.viewContext.mergeChanges(fromContextDidSave: notification)
        }
    }
}