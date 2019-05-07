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
    
    var feedbackGenerator: UIImpactFeedbackGenerator? = nil
    
    var touchAndHold: UILongPressGestureRecognizer? = nil
    
    var popUpImageView: UIImageView? = nil
    
    var popView: UIView? = nil
    
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
        addCellPressGesture()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        setMapView()
        initialPhotoLoad()
        deleteButton.isEnabled = false
        newCollectionButton.isEnabled = false
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        photosMO.removeAll()
        super.viewDidDisappear(true)
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
                let globeData = globeImage.pngData()
                let compareData = cell.imageView.image!.pngData()
                if globeData == compareData {
                    if let location = photo.dataLocation {
                        DispatchQueue.global(qos: .userInteractive).async {
                            let url = URL(string: location)
                            if let data = NSData(contentsOf: url!) { // This is a network request... therefore put in a background queue.
                                DispatchQueue.main.sync {
                                    cell.imageView.image = UIImage(data: data as Data)
                                    photo.image = data
                                    self.stack.save()
                                }
                            }
                        }
                    }
                }
            }
        } else {
            cell.imageView.image = UIImage(data: photo.image! as Data)
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
            
            if let itemToRemoveIndex = photoIndexes.firstIndex(of: indexPath) {
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

extension PinPhotosViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        return true
    }
    
    fileprivate func addCellPressGesture() {
            touchAndHold = UILongPressGestureRecognizer(target: self, action: #selector(enlargeImage))
            touchAndHold?.minimumPressDuration = 0.3
            touchAndHold?.numberOfTouchesRequired = 1
            touchAndHold?.numberOfTapsRequired = 0 // 0 is default, any more than this adds extra required taps.
            touchAndHold?.delegate = self
        
            photosView.addGestureRecognizer(touchAndHold!)
    }
    
    @objc func enlargeImage(gestureRecognizer: UILongPressGestureRecognizer) {
        
        feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
        
        if gestureRecognizer.state == .began {
            feedbackGenerator?.impactOccurred()
            
            let point = gestureRecognizer.location(in: photosView)
            let indexPath = photosView.indexPathForItem(at: point)
            if indexPath != nil {
                photosView.allowsSelection = false
                photosView.removeGestureRecognizer(touchAndHold!)
                let cell = photosView.cellForItem(at: indexPath!) as! PinImageCollectionViewCell
                let tap = UITapGestureRecognizer(target: self, action: #selector(dismissPopView))
                tap.delegate = self
                
                popUpImageView = UIImageView(image: cell.imageView.image)
                popUpImageView?.contentMode = .scaleAspectFit
                popUpImageView?.isUserInteractionEnabled = true
                popUpImageView?.addGestureRecognizer(tap)
                popView = UIView(frame: photosView.bounds)
                popView?.backgroundColor = UIColor.white
                popUpImageView?.frame = (popView?.bounds)!
                popView?.addSubview(popUpImageView!)
                photosView.isScrollEnabled = false
                newCollectionButton.isEnabled = false
                
                UIView.transition(with: photosView, duration: 0.3, options: .transitionCrossDissolve, animations: {
                    self.photosView.addSubview(self.popView!)
                }, completion: { (finished) in
                    self.removeBorder()
                    self.deleteButton.isEnabled = false
                    self.photoIndexes.removeAll()
                })
            }
        }
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
                }
                pin.setValue(true, forKey: "hasBeenSelected")
                self.stack.save()
                print("[Photos Saved]")
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
        
        let span = MKCoordinateSpan.init(latitudeDelta: 0.5, longitudeDelta: 0.5)
        let region = MKCoordinateRegion(center: annotation.coordinate, span: span)
        
        miniMapView.setRegion(region, animated: true)
        miniMapView.isRotateEnabled = false
        miniMapView.isZoomEnabled = false
        miniMapView.isScrollEnabled = false
    }
    
    fileprivate func deleteSelectedPhotos() {
        
        var photosToDelete = [Photo]()
        
        for indexPath in photoIndexes { // Index paths from selected photos in collectionView
            let index = indexPath.row // Grabs index of photo as this is different from the "indexPath"
            photosToDelete.append(photosMO[index]) // Appends actual photo to array
            context.delete(photosMO[index]) // Deletes photo from stored memory. Note: This does not delete contents from array which is why we
        }                                   // append to reference array above
        
        for photo in photosToDelete {
           let index = photosMO.firstIndex(of: photo)
            photosMO.remove(at: index!) // Removes items from array so they stop appearing in collectionView
        }
        
        stack.save()
        removeBorder()
        photosView.deleteItems(at: photoIndexes) // Removes currently displayed CELLS from collectionView
        self.photoIndexes.removeAll() // Removes index pointers
        photosView.reloadData()
    }
    
    fileprivate func removeBorder() {
        for photo in photoIndexes {
            let cell = photosView.cellForItem(at: photo)
            cell?.layer.borderWidth = 0.0
            cell?.layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    @objc fileprivate func dismissPopView() {
        UIView.transition(with: photosView, duration: 0.3, options: .transitionCrossDissolve, animations: {
            self.popView?.removeFromSuperview()
        }) { (finished) in
            self.photosView.isScrollEnabled = true
            self.photosView.allowsMultipleSelection = true
            self.newCollectionButton.isEnabled = true
            self.addCellPressGesture()
        }
    }
}

