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
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout! // Should this be declared in a subclass? If not, is this implementation correct?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = CGSize(width: 1.0, height: 1.0)
    }
    
    // Initialize
    
    init(fetchedResultsController fc: NSFetchedResultsController<NSFetchRequestResult>) {
        fetchedResultsController = fc
        super.init(collectionViewLayout: flowLayout) // is this correct?
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
    
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        collectionView?.performBatchUpdates({self.collectionView?.reloadData()}) // is this correct?
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
