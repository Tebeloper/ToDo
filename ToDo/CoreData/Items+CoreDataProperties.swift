//
//  Items+CoreDataProperties.swift
//  ToDo
//
//  Created by Dimitrios Gkarlemos on 03/04/2023.
//
//

import Foundation
import CoreData


extension Items {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Items> {
        return NSFetchRequest<Items>(entityName: "Items")
    }

    @NSManaged public var done: Bool
    @NSManaged public var name: String?
    @NSManaged public var parentCategory: ToDoListItem?

}

extension Items : Identifiable {

}
