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

class PinPhotosViewController: UIViewController {
    
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var miniMapView: MKMapView!
    
    @IBOutlet weak var photosView: UICollectionView!
    
    @IBAction func newCollectionButton(_ sender: Any) {
        
    }
    
    @IBAction func deletePhotos(_ sender: Any) {
        
        photosView.deleteItems(at: photoIndexes)
        // remove deleted photos from data source... collectionView.indexPathForSelectedItems()...? if i also use sort method will it permanently change photos array below?
        self.deleteButton.isEnabled = false
        self.photoIndexes.removeAll()
        deletePhotos()
    }
    
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    var annotation = MKPointAnnotation()
    
    let stack = CoreDataStack.sharedInstance()
    
    let context = CoreDataStack.sharedInstance().context
    
    let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
    
    var photosMO = [Photo]()
    
    var photos = [UIImage]()
    
    var photoIndexes = [IndexPath]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        miniMapView.delegate = self
        photosView.delegate = self
        photosView.dataSource = self
        photosView.allowsMultipleSelection = true
        fetchRequestSetup()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setMapView()
        loadPhotos() // CUrrently returning the same page over and over
        self.deleteButton.isEnabled = false
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
    }
}


extension PinPhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = self.photosView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! PinImageCollectionViewCell
        let photo = self.photos[indexPath.row]
        
        cell.imageView.image = photo
        
        return cell
    }
}


extension PinPhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        photoIndexes.append(indexPath)
        deleteButton.isEnabled = true
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        while photoIndexes.contains(indexPath) {
            if let itemToRemoveIndex = photoIndexes.index(of: indexPath) {
                photoIndexes.remove(at: itemToRemoveIndex)
            }
        }
        
        if photoIndexes.isEmpty {
            deleteButton.isEnabled = false
        }
    }
}


extension PinPhotosViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellSize = (self.view.frame.size.width / 4)
        
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let leftRightInset = self.view.frame.size.width / 10.0
        let topBottomInset = CGFloat(0)
        
        return UIEdgeInsetsMake(topBottomInset, leftRightInset, topBottomInset, leftRightInset)
        
    }
    
        //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        //        <#code#>
        //    }
        
        //    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        //        <#code#>
        //    }
        
}


extension PinPhotosViewController: MKMapViewDelegate {
    
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
}


extension PinPhotosViewController {
    
    // Setup Functions
    
    private func performPhotoSearch() {
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            
            let pin = fetchedResults[0]
            
            if let photoSet = pin.photos {
                for photo in photoSet {
                    if let image = photo as? Photo {
                        photosMO.append(image)
                        if let convertedImage = UIImage(data: image.image as! Data) {
                            photos.append(convertedImage)
                            print(" converted image: \(convertedImage)")
                            DispatchQueue.main.async {
                                self.photosView.reloadData()
                            }
                        }
                    }
                }
            }
        } catch {
            fatalError("Cannot perform Photo Search")
        }
    }
    
    fileprivate func loadPhotos() {
        
        let pin = Pin(title: annotation.title, subtitle: annotation.subtitle, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: context)
        
        
        FlickerClient.sharedInstance().getRandomPhotosForPin(pin: pin) { photos in
            for photo in photos {
                pin.addToPhotos(photo)
                print(photo)
            }
            self.stack.save()
            self.performPhotoSearch()
        }
    }
    
    fileprivate func fetchRequestSetup() {
        
        let p1 = NSPredicate(format: "latitude = %lf", annotation.coordinate.latitude)
        let p2 = NSPredicate(format: "longitude = %lf", annotation.coordinate.longitude)
        let predicates = NSCompoundPredicate(andPredicateWithSubpredicates: [p1, p2])
        
        fetchRequest.predicate = predicates
    }
    
    fileprivate func setMapView() {
        
        miniMapView.addAnnotation(annotation)
        
        let span = MKCoordinateSpanMake(0.5, 0.5)
        
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        
        miniMapView.setRegion(region, animated: true)
        
        miniMapView.isRotateEnabled = false
        miniMapView.isZoomEnabled = false
        miniMapView.isScrollEnabled = false
    }
    
    fileprivate func deletePhotos() {
        
        // how do I search for the correct photos to delete/use the images to compare data for Photo entity
        
        print("Photos deleted")
        stack.save()
    }
}

