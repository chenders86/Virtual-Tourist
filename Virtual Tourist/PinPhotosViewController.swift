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
    
    fileprivate let sectionInsets = UIEdgeInsets(top: 5.0, left: 12.0, bottom: 5.0, right: 12.0)
    
    fileprivate let itemsPerRow: CGFloat = 3
    
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    @IBOutlet weak var miniMapView: MKMapView!
    
    @IBOutlet weak var photosView: UICollectionView!
    
    @IBAction func newCollectionButton(_ sender: Any) {
        newCollectionButton.isEnabled = false
        if let _ = masterPin {
        context.delete(masterPin!)
        stack.save()
        }
        initialPhotoLoad()
    }
    
    @IBAction func deletePhotosFromCollection(_ sender: Any) {
        self.deleteButton.isEnabled = false
        deleteSelectedPhotos()
    }
    
    @IBOutlet weak var newCollectionButton: UIButton!
   
    @IBOutlet weak var deleteButton: UIBarButtonItem!
    
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
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setMapView()
        initialPhotoLoad()
        self.deleteButton.isEnabled = false
        self.newCollectionButton.isEnabled = false
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.photosMO.removeAll()
    }
}


extension PinPhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
            return photosMO.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = self.photosView.dequeueReusableCell(withReuseIdentifier: "ImageCell", for: indexPath) as! PinImageCollectionViewCell
        let photo = self.photosMO[indexPath.row]
        
        if photo.image == nil {
            cell.imageView.image = UIImage(named: "america-globe.png")
            
            if let globeImage = UIImage(named: "america-globe.png") {
                let globeData = UIImagePNGRepresentation(globeImage)
                let compareData = UIImagePNGRepresentation(cell.imageView.image!)
                if globeData == compareData {
                    DispatchQueue.global(qos: .userInteractive).async {
                        if let location = photo.dataLocation {
                            let url = URL(string: location)
                            if let data = NSData(contentsOf: url!) {
                                photo.image = data
                                self.stack.save()
                                DispatchQueue.main.sync {
                                    cell.imageView.image = UIImage(data: data as Data)
                                }
                            }
                        }
                    }
                }
            }
        } else {
            cell.imageView.image = UIImage(data: photo.image as! Data)
        }

        return cell
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
        
        let paddingSpace = sectionInsets.left * (itemsPerRow + 1)
        let availableWidth = view.frame.width - paddingSpace
        let widthPerItem = availableWidth / itemsPerRow
        
        return CGSize(width: widthPerItem, height: widthPerItem)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        
        return sectionInsets
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
                        
            let pin = fetchedResults[0]
            masterPin = pin
            
            if let photoSet = pin.photos {
                photosMO.removeAll()
                for photo in photoSet {
                    if let image = photo as? Photo {
                        photosMO.append(image)
                    }
                }
                DispatchQueue.main.async {
                    self.photosView.reloadData()
                    self.newCollectionButton.isEnabled = true
                }

                print("\(photosMO.count) photos loaded")
            }
        } catch {
            fatalError("Cannot perform Photo Search \(error)")
        }
    }
    
    fileprivate func initialPhotoLoad() {
        
        do {
            var fetchedResults = try context.fetch(fetchRequest)
            
            if fetchedResults.isEmpty {
                loadPhotosFromFlickr()
                print("loading...")
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
                        }
                    }
                    DispatchQueue.main.async {
                        self.photosView.reloadData()
                        self.newCollectionButton.isEnabled = true
                    }

                }
            }
        } catch {
            fatalError("Initial photo load failed \(error)")
        }
    }
    
    func loadPhotosFromFlickr() {
        
        let pin = Pin(title: annotation.title, subtitle: annotation.subtitle, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: context)
        
        
        FlickerClient.sharedInstance().getRandomPhotosForPin(pin: pin) { photos in
            
            if photos.isEmpty {
                
                let alertController = UIAlertController(title: "No Photos", message: "No photos to display, please choose another location or try again.", preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action: UIAlertAction) in
                    self.dismiss(animated: true, completion: nil)
                    self.newCollectionButton.isEnabled = true
                    self.context.delete(pin)
                    self.stack.save()
                })
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
                
            } else {
                
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

