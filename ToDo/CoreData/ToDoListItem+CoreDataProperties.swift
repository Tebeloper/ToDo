//
//  ToDoListItem+CoreDataProperties.swift
//  ToDo
//
//  Created by Dimitrios Gkarlemos on 03/04/2023.
//
//

import Foundation
import CoreData


extension ToDoListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoListItem> {
        return NSFetchRequest<ToDoListItem>(entityName: "ToDoListItem")
    }

    @NSManaged public var done: Bool
    @NSManaged public var name: String?
    @NSManaged public var items: NSSet?

}

// MARK: Generated accessors for items
extension ToDoListItem {

    @objc(addItemsObject:)
    @NSManaged public func addToItems(_ value: Items)

    @objc(removeItemsObject:)
    @NSManaged public func removeFromItems(_ value: Items)

    @objc(addItems:)
    @NSManaged public func addToItems(_ values: NSSet)

    @objc(removeItems:)
    @NSManaged public func removeFromItems(_ values: NSSet)

}

extension ToDoListItem : Identifiable {

}
