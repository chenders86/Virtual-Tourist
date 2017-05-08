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

class MapViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    
    @IBOutlet weak var mapView: MKMapView!
    
    
    let fetchRequest = NSFetchRequest<Pin>(entityName: "Pin")
    
    let stack = CoreDataStack.sharedInstance()
    
    let context = CoreDataStack.sharedInstance().context
    
    var selectedAnnotation = MKPointAnnotation()
    
    var locationManager = CLLocationManager()
    
    
    @IBAction func clearPinData(_ sender: UIButton) {
        self.mapView.removeAnnotations(mapView.annotations)
        do {
            try stack.dropAllData()
        } catch {
            print("Error droping all objects in Database")
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        mapView.delegate = self
        addTouch()
        self.locationManager.delegate = self
        self.locationManager.requestWhenInUseAuthorization()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.hidesBarsOnSwipe = true
        setMapCenter()
        displayPins()
    }
    
    

    
    // Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "PhotosView" {
            
            let newVC = segue.destination as! PinPhotosViewController
            
            newVC.annotation = selectedAnnotation
        }
        
    }
 
    
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
            
            selectedAnnotation = view.annotation as! MKPointAnnotation
            
            self.performSegue(withIdentifier: "PhotosView", sender: view)
        }

    }
    
    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        UserDefaults.standard.set((self.mapView.region.center.latitude) as Double, forKey: "MapCenterLat")
        UserDefaults.standard.set((self.mapView.region.center.longitude) as Double, forKey: "MapCenterLon")
        UserDefaults.standard.set((self.mapView.region.span.latitudeDelta) as Double, forKey: "MapDeltaLat")
        UserDefaults.standard.set((self.mapView.region.span.longitudeDelta) as Double, forKey: "MapDeltaLon")
    }
    
    // LocationManager Delegate
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if status == .authorizedWhenInUse {
            getUserLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations[0] as CLLocation
        
        self.locationManager.stopUpdatingLocation()
        
        let coordinates = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        let span = MKCoordinateSpanMake(1.0,1.0)
        
        let region = MKCoordinateRegion(center: coordinates, span: span)
        
        self.mapView.setRegion(region, animated: true)
        
        print("User location initialized")
        
    }
    
    private func getUserLocation() {
        self.locationManager.startUpdatingLocation()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        mapView.showsUserLocation = false
    }

    
    // Extra setup functions

    func addUserPin(gestureRecognizer: UIGestureRecognizer) {
        if gestureRecognizer.state == .began {
            
            let touchPoint = gestureRecognizer.location(in: mapView)
            let newCoordinates = mapView.convert(touchPoint, toCoordinateFrom: mapView)
            let annotation = MKPointAnnotation()
            annotation.coordinate = newCoordinates
            
            let location = CLLocation(latitude: newCoordinates.latitude, longitude: newCoordinates.longitude)
            
            CLGeocoder().reverseGeocodeLocation(location) { (placemarks, error) in
                guard error == nil else {
                    print("Reverse geocoding failed" + "" + (error?.localizedDescription)!)
                    return
                }
                
                guard let placemark = placemarks?[0] else {
                    print("No placemarks were returned from the Geocoder")
                    return
                }
                
                if placemark.locality != nil && placemark.administrativeArea != nil {
                    annotation.title = (placemark.locality! + ", " + placemark.administrativeArea!)
                } else {
                    annotation.title = placemark.locality
                }
                annotation.subtitle = placemark.postalCode
            }
            
            mapView.addAnnotation(annotation)
            
            let pin = Pin(title: annotation.title, subtitle: annotation.subtitle, latitude: annotation.coordinate.latitude, longitude: annotation.coordinate.longitude, context: context)
            
            
            FlickerClient.sharedInstance().getRandomPhotosForPin(pin: pin) { photos in
                for photo in photos {
                    pin.addToPhotos(photo)
                    print(photo)
                }
                self.stack.save()
            }
        }
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
