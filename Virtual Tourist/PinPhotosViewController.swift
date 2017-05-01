//
//  PinPhotosViewController.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 4/27/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import Foundation
import MapKit
import CoreData

class PinPhotosViewController: UICollectionViewController {
    
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    let annotation = MKPointAnnotation()
    
    let stack = CoreDataStack.sharedInstance()
    
    let context = CoreDataStack.sharedInstance().context
    
    override func viewDidLoad() {
        super.viewDidLoad()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = CGSize(width: 1.0, height: 1.0)
        // display images with FR
    }
    
}
