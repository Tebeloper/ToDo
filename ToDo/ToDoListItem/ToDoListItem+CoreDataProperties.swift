//
//  ToDoListItem+CoreDataProperties.swift
//  ToDo
//
//  Created by Dimitrios Gkarlemos on 28/03/2023.
//
//

import Foundation
import CoreData


extension ToDoListItem {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ToDoListItem> {
        return NSFetchRequest<ToDoListItem>(entityName: "ToDoListItem")
    }

    @NSManaged public var name: String?
    @NSManaged public var createdAt: Date?
    
}

extension ToDoListItem : Identifiable {

}
