//
//  Annotations.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 4/3/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import MapKit

class Annotations: NSObject {
    
    class func sharedInstance() -> Annotations {
    
        struct Singleton {
            static var sharedInstance = Annotations()
        }
        return Singleton.sharedInstance
    }
    
    var allAnnotations = [MKPointAnnotation]()
}

