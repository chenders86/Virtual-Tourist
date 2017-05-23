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
        newCollectionButton.isEnabled = false
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        context.delete(masterPin!)
        initialPhotoLoad()
    }
    
    @IBAction func deletePhotosFromCollection(_ sender: Any) {
        self.deleteButton.isEnabled = false
        deleteSelectedPhotos()
    }
    
    @IBOutlet weak var newCollectionButton: UIButton!
   
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    
    var annotation = MKPointAnnotation()
    
    let stack = CoreDataStack.sharedInstance()
    
    let context = CoreDataStack.sharedInstance().context
    
    let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
    
    var masterPin: Pin?
    
    var photosMO = [Photo]() // Data Source
    
    var photoIndexes = [IndexPath]() // Indexes of selected Photos
    
    override func viewDidLoad() {
        super.viewDidLoad()
        miniMapView.delegate = self
        photosView.delegate = self
        photosView.dataSource = self
        photosView.allowsMultipleSelection = true
        fetchRequestSetup()
        self.activityIndicator.hidesWhenStopped = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setMapView()
        initialPhotoLoad()
        self.deleteButton.isEnabled = false
        self.newCollectionButton.isEnabled = false
        self.activityIndicator.startAnimating()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.photosMO.removeAll()
    }
}


extension PinPhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if photosMO.isEmpty {
            return Int(Constants.FlickrParameterValues.PerPage)!
        } else {
            return photosMO.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        if photosMO.isEmpty {
            
            let cell = self.photosView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! PinImageCollectionViewCell
            cell.imageView.image = UIImage(named: "america-globe.png")!
            return cell
            
        } else {
            
            let cell = self.photosView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! PinImageCollectionViewCell
            let photo = self.photosMO[indexPath.row]
            
            let image = UIImage(data: photo.image as! Data)
            
            cell.imageView.image = image
            
            return cell
        }
    }
}


extension PinPhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        photoIndexes.append(indexPath)
        
        let cell = collectionView.cellForItem(at: indexPath)
        cell?.layer.borderWidth = 4.0
        cell?.layer.borderColor = UIColor.blue.cgColor
        
        deleteButton.isEnabled = true
        print("Number of photo indexes: \(photoIndexes.count)")
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        
        if photoIndexes.contains(indexPath) {
            let cell = collectionView.cellForItem(at: indexPath)
            cell?.layer.borderWidth = 0.0
            cell?.layer.borderColor = UIColor.clear.cgColor
            
            if let itemToRemoveIndex = photoIndexes.index(of: indexPath) {
                photoIndexes.remove(at: itemToRemoveIndex)
                print("Number of photo indexes: \(photoIndexes.count)")
            }
        }
        
        if photoIndexes.isEmpty {
            deleteButton.isEnabled = false
        }
    }
}


extension PinPhotosViewController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        let cellSize = (self.view.frame.size.width / 3.3)
        
        return CGSize(width: cellSize, height: cellSize)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let leftRightInset = self.view.frame.size.width / 47.0
        let topBottomInset = CGFloat(0)
        
        return UIEdgeInsetsMake(topBottomInset, leftRightInset, topBottomInset, leftRightInset)
        
    }
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
    
    private func performPhotoFetch() {
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            
            if fetchedResults.isEmpty{
                context.delete(fetchedResults[0])
                stack.save()
                loadPhotosFromFlickr()
                print("Re-downloading photos")
                return
            }
            
            let pin = fetchedResults[0]
            masterPin = pin
            
            if let photoSet = pin.photos {
                photosMO.removeAll()
                for photo in photoSet {
                    if let image = photo as? Photo {
                        photosMO.append(image)
                        DispatchQueue.main.async {
                            self.photosView.reloadData()
                            self.newCollectionButton.isEnabled = true
                        }
                    }
                }
                self.activityIndicator.stopAnimating()
                print("\(photosMO.count) photos loaded")
            }
        } catch {
            fatalError("Cannot perform Photo Search \(error)")
        }
    }
    
    fileprivate func initialPhotoLoad() {
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            
            if fetchedResults.isEmpty {
                loadPhotosFromFlickr()
                return
            }
            
            let pin = fetchedResults[0]
            if pin.hasBeenSelected == true {
                print("Pin has been selected before!")
                
                masterPin = pin
                
                if let photoSet = pin.photos {
                    photosMO.removeAll()
                    for photo in photoSet {
                        if let image = photo as? Photo {
                            photosMO.append(image)
                            DispatchQueue.main.async {
                                self.photosView.reloadData()
                                self.newCollectionButton.isEnabled = true
                            }
                        }
                    }
                    self.activityIndicator.stopAnimating()
                }
            }
        } catch {
            fatalError("Initial photo load failed \(error)")
        }
    }
    
    func loadPhotosFromFlickr() {
        
        let pin = Pin(title: annotation.title, subtitle: annotation.subtitle, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: context)
        
        
        FlickerClient.sharedInstance().getRandomPhotosForPin(pin: pin) { photos in
            for photo in photos {
                pin.addToPhotos(photo)
                print(photo)
            }
            pin.setValue(true, forKey: "hasBeenSelected")
            self.stack.save()
            print("Pin has been saved \(pin)")
            self.performPhotoFetch()
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
    
    fileprivate func deleteSelectedPhotos() {
        
        var photosToDelete = [Photo]()
        
        for indexPath in photoIndexes {
            let index = indexPath.row
            photosToDelete.append(photosMO[index])
            context.delete(photosMO[index]) // Note: This does not delete contents from array which is why we append to reference array above
        }
        
        for photo in photosToDelete {
           let index = photosMO.index(of: photo)
            photosMO.remove(at: index!)
        }
        
        stack.save()
        removeBorder()
        photosView.deleteItems(at: photoIndexes)
        self.photoIndexes.removeAll()
        photosView.reloadData()
    }
    
    fileprivate func removeBorder() {
        
        for photo in photoIndexes {
            let cell = photosView.cellForItem(at: photo)
            cell?.layer.borderWidth = 0.0
            cell?.layer.borderColor = UIColor.clear.cgColor
        }
    }
}

