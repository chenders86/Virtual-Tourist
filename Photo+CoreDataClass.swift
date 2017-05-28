//
//  Photo+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 5/27/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import Foundation
import CoreData

@objc(Photo)
public class Photo: NSManagedObject {
    
    convenience init(dataLocation: String?, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Photo", in: context) {
            self.init(entity: ent, insertInto: context)
            self.dataLocation = dataLocation
        } else {
            fatalError("Unable to find Photo entity")
        }
    }
}
