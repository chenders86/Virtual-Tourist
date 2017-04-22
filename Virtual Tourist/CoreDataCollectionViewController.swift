//
//  CoreDataTableViewController.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 4/21/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import UIKit
import CoreData


class CoreDataCollectionViewController: UICollectionViewController, NSFetchedResultsControllerDelegate {
    
    // Fetched Results Controller
    
    var fetchedResultsController: NSFetchedResultsController<NSFetchRequestResult>? {
        didSet {
            fetchedResultsController?.delegate = self
            executeSearch()
            collectionView?.reloadData()
        }
    }
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    // minimum line spacing
    // minimum inter item spacing
    // itemSize
    
    // Initialize
    
    init(fetchedResultsController fc: NSFetchedResultsController<NSFetchRequestResult>) {
        fetchedResultsController = fc
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // CollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fc = fetchedResultsController {
            return fc.sections![section].numberOfObjects
        } else {
            return 0
        }
    }
    
    // FetchedResultsControllerDelegate
    
    // DO I EVEN NEED THIS FUNCTION SINCE I ONLY HAVE 1 SECTION???
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) { // Sets up editing of sections when a request is made
        
        let set = IndexSet(integer: sectionIndex)
        
        switch (type) {
        case .insert:
            collectionView?.insertSections(set)
        case .delete:
            collectionView?.deleteSections(set)
        default:
            break
        }
    }
    
    // NOT SURE IF THIS IS CORRECT IMPLEMENTATION FOR COLLECTION VIEW
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) { // Sets up editing of rows when a request is made
        
        switch (type) {
        case .insert:
            collectionView?.insertItems(at: [newIndexPath!])
        case .delete:
            collectionView?.deleteItems(at: [newIndexPath!])
        case .update:
            collectionView?.reloadItems(at: [newIndexPath!])
        case .move:
            collectionView?.deleteItems(at: [indexPath!])
            collectionView?.insertItems(at: [newIndexPath!])
        }
    }
    
    // WHAT DO I DO WITH THIS FUNCTION??? SHOULD ^^ BE PERFORMED IN THE BELOW FUNCTION??
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) { // NEED HELP IMPLEMENTING
        collectionView?.performBatchUpdates(<#T##updates: (() -> Void)?##(() -> Void)?##() -> Void#>, completion: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>)
    }
    
    // performFetch
    
    func executeSearch() {
        
        if let fc = fetchedResultsController {
            do {
                try fc.performFetch()
            } catch {
                let userInfo = [NSLocalizedDescriptionKey: "Error while trying to perform Fetch"]
                let error = NSError(domain: "executeSearch", code: 1, userInfo: userInfo)
                print(error.localizedDescription)
            }
        }
    }
}
