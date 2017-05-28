//
//  Photo+CoreDataProperties.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 5/27/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo");
    }

    @NSManaged public var image: NSData?
    @NSManaged public var dataLocation: String?
    @NSManaged public var pin: Pin?

}
