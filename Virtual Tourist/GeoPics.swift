//
//  GeoPics.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 4/7/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import Foundation
import UIKit


class GeoPics: NSObject {
    
    class func sharedInstance() -> GeoPics {
        
        struct Singleton {
            static var sharedInstance = GeoPics()
        }
        
        return Singleton.sharedInstance
    }
    
    var allGeoPics = [UIImage]()
}
