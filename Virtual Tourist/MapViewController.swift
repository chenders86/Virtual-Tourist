//
//  MapViewController.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 4/3/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
    
    let stack = CoreDataStack.sharedInstance()
    
    let context = CoreDataStack.sharedInstance().context
    
    
    @IBAction func clearPinData(_ sender: UIButton) {
        self.mapView.removeAnnotations(mapView.annotations)
        // delete pins in core data
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        addTouch()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.hidesBarsOnSwipe = true
        setMapCenter()
        displayPins()
    }
    
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    // MapView Delegate:
    
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseID = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseID) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseID)
            pinView?.canShowCallout = true
            pinView?.pinTintColor = .red
            //pinView?.isDraggable = true
            pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            
        } else {
            pinView?.annotation = annotation
        }
        return pinView
    }
    
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {

        if control == view.rightCalloutAccessoryView {
            
            // will need to implement segue
        }

    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set((self.mapView.region.center.latitude) as Double, forKey: "MapCenterLat")
        UserDefaults.standard.set((self.mapView.region.center.longitude) as Double, forKey: "MapCenterLon")
        UserDefaults.standard.set((self.mapView.region.span.latitudeDelta) as Double, forKey: "MapDeltaLat")
        UserDefaults.standard.set((self.mapView.region.span.longitudeDelta) as Double, forKey: "MapDeltaLon")
    }
    
    // Extra setup functions

    func addUserPin(gestureRecognizer: UIGestureRecognizer) {
        let touchPoint = gestureRecognizer.location(in: mapView)
        let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
        let annotation = MKPointAnnotation()
        annotation.coordinate = newCoordinates
        
        let location = CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
        
        CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
            guard error == nil else {
                print("Reverse geocoding failed" + (error?.localizedDescription)!)
                return
            }
            
            guard let placemark = placemarks?[0] else {
                print("No placemarks were returned from the Geocoder")
                return
            }
            
            // if let unwrap to set city, state, zip
            annotation.title = placemark.locality
            annotation.subtitle = placemark.administrativeArea
        }
        
        mapView.addAnnotation(annotation)
        
        //create Pin using Core Data
        let pin = Pin(title: annotation.title, subtitle: annotation.subtitle, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: context)
        
        
        FlickerClient.sharedInstance().getRandomPhotosForPin(pin: pin) { photos in
            for photo in photos {
                pin.addToPhotos(photo)
            }
        }
        
        stack.save()
    }
    
    private func addTouch() {
        let uiTouch = UILongPressGestureRecognizer(target: self, action: #selector(addUserPin))
        uiTouch.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(uiTouch)
    }
    
    private func setMapCenter() {
        
        let lat = UserDefaults.standard.value(forKey: "MapCenterLat") as! CLLocationDegrees
        let lon = UserDefaults.standard.value(forKey: "MapCenterLon") as! CLLocationDegrees
        let centerCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        let latDelta = UserDefaults.standard.value(forKey: "MapDeltaLat") as! CLLocationDegrees
        let lonDelta = UserDefaults.standard.value(forKey: "MapDeltaLon") as! CLLocationDegrees
        let coordSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        
        mapView.region.center = centerCoordinates
        mapView.region.span = coordSpan
    }
    
    private func displayPins() {
        
        // Display loading symbol
        
        do {
            let fetchedResults = try context.fetch(fetchRequest)
            
            for pin in fetchedResults {
                let annotation = MKPointAnnotation()
                annotation.coordinate.latitude = pin.latitude
                annotation.coordinate.longitude = pin.longitude
                annotation.title = pin.title
                annotation.subtitle = pin.subtitle
                mapView.addAnnotation(annotation)
            }
        } catch {
            fatalError("Could not fetch Pins for MapView")
        }
    }
}
