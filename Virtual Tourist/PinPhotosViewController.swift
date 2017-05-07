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

class PinPhotosViewController: UIViewController, MKMapViewDelegate, UICollectionViewDelegate, UICollectionViewDataSource {
    
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var MiniMapView: MKMapView!
    
    @IBOutlet weak var PhotosView: UICollectionView!
    
    @IBAction func newCollectionButton(_ sender: Any) {
    }
    
    var annotation = MKPointAnnotation()
    
    let stack = CoreDataStack.sharedInstance()
    
    let context = CoreDataStack.sharedInstance().context
    
    let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
    
    var photos = [UIImage]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        flowLayout.minimumInteritemSpacing = 0
        flowLayout.minimumLineSpacing = 0
        flowLayout.itemSize = CGSize(width: 1.0, height: 1.0)
        MiniMapView.delegate = self
        PhotosView.delegate = self
        fetchRequestSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        MiniMapView.addAnnotation(annotation)
        performPhotoSearch()
    }
    
    // PhotosView DataSource
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = self.PhotosView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! PinImageCollectionViewCell
        let photo = self.photos[indexPath.row]
        
        cell.imageView.image = photo
        
        return cell
    }
    
    // PhotosView Delegate
    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//
//    }
    
    
    
    // MiniMapView Delegate
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = false
            pinView?.pinTintColor = .green
            
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    private func performPhotoSearch() {
        
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            print(fetchedResults)
            
            let pin = fetchedResults[0]
            
            if let photoSet = pin.photos {
                for photo in photoSet {
                    if let image = photo as? Photo {
                        if let convertedImage = UIImage(data: image.image as! Data) {
                            photos.append(convertedImage)
                            print(convertedImage)
                        }
                    }
                }
            }
        } catch {
            fatalError("Cannot perform Photo Search")
        }
    }
    
    private func fetchRequestSetup() {
        
        let p1 = NSPredicate(format: "latitude = %@", annotation.coordinate.latitude)
        let p2 = NSPredicate(format: "longitude = %@", annotation.coordinate.longitude)
        let predicates = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        
        fetchRequest.predicate = predicates
    }

}
