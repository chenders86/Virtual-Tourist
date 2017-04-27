//
//  Pin+CoreDataClass.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 4/26/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import Foundation
import CoreData

@objc(Pin)
public class Pin: NSManagedObject {
    
    convenience init(title: String?, subtitle: String?, latitude: Double, longitude: Double, context: NSManagedObjectContext) {
        
        if let ent = NSEntityDescription.entity(forEntityName: "Pin", in: context) {
            self.init(entity: ent, insertInto: context)
            self.title = title
            self.subtitle = subtitle
            self.latitude = latitude
            self.longitude = longitude
        } else {
            fatalError("Unable to find Pin entity")
        }
    }
}
