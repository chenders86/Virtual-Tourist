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

class MapViewController: UIViewController {
    
    
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
            print("Pins deleted")
            print("stack saved")
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

        if segue.identifier == "PhotosView" {
            
            let newVC = segue.destination as! PinPhotosViewController
            
            newVC.annotation = selectedAnnotation
        }
    }
}
 

extension MapViewController: MKMapViewDelegate {
    
    
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
        print("\(self.mapView.region.span.latitudeDelta), \(self.mapView.region.span.longitudeDelta)")
    }
}
    

extension MapViewController: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        
        if UserDefaults.standard.bool(forKey: "HasLaunchedBefore") == false && status == .authorizedWhenInUse {
            
            getUserLocation()

            UserDefaults.standard.set(true, forKey: "HasLaunchedBefore")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let userLocation = locations[0] as CLLocation
        
        self.locationManager.stopUpdatingLocation()
        
        let coordinates = CLLocationCoordinate2D(latitude: userLocation.coordinate.latitude, longitude: userLocation.coordinate.longitude)
        
        let span = MKCoordinateSpan.init(latitudeDelta: 1.0,longitudeDelta: 1.0)
        
        let region = MKCoordinateRegion(center: coordinates, span: span)
        
        self.mapView.setRegion(region, animated: true)
    }
    
    private func getUserLocation() {
        self.locationManager.startUpdatingLocation()
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        mapView.showsUserLocation = false
    }
}

extension MapViewController {

    // Extra setup functions

    @objc func addUserPin(gestureRecognizer: UIGestureRecognizer) {
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
        }
    }
    
    fileprivate func addTouch() {
        let uiTouch = UILongPressGestureRecognizer(target: self, action: #selector(addUserPin))
        uiTouch.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(uiTouch)
    }
    
    fileprivate func setMapCenter() {
        
        let lat = UserDefaults.standard.value(forKey: "MapCenterLat") as! CLLocationDegrees
        let lon = UserDefaults.standard.value(forKey: "MapCenterLon") as! CLLocationDegrees
        let centerCoordinates = CLLocationCoordinate2D(latitude: lat, longitude: lon)
        
        let latDelta = UserDefaults.standard.value(forKey: "MapDeltaLat") as! CLLocationDegrees
        let lonDelta = UserDefaults.standard.value(forKey: "MapDeltaLon") as! CLLocationDegrees
        let coordSpan = MKCoordinateSpan(latitudeDelta: latDelta, longitudeDelta: lonDelta)
        
        mapView.region.center = centerCoordinates
        mapView.region.span = coordSpan
        print(mapView.region.span)
    }
    
    fileprivate func displayPins() {
        
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
