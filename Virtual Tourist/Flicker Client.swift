//
//  Flicker Client.swift
//  Virtual Tourist
//
//  Created by Casey Henderson on 4/3/17.
//  Copyright © 2017 Casey Henderson. All rights reserved.
//

import UIKit
import MapKit


class FlickerClient: NSObject {
    
    class func sharedInstance() -> FlickerClient {
        
        struct Singleton {
            
            static var sharedInstance = FlickerClient()
        }
        
        return Singleton.sharedInstance
    }
    
    var pageCount = 0
    var randomPage = 0
    
    
    func getRandomPhotosForPin(annotationView view: MKAnnotationView) { // Will probably have to chance input from MKAnnotationView to plain coordinates
        
        // gets number of pages returned from flikr
        
        let lat = view.annotation?.coordinate.latitude
        let lon = view.annotation?.coordinate.longitude
        let latString = String(describing: lat)
        let lonString = String(describing: lon)
        print(latString, lonString)
        
        let session = URLSession.shared
        
        var url = URLComponents()
        url.scheme = Constants.Flickr.APIScheme
        url.host = Constants.Flickr.APIHost
        url.path = Constants.Flickr.APIPath
        
        let request = NSMutableURLRequest(url: url.url!)
        request.addValue(Constants.FlickrParameterKeys.Method, forHTTPHeaderField: Constants.FlickrParameterValues.SearchMethod)
        request.addValue(Constants.FlickrParameterKeys.APIKey, forHTTPHeaderField: Constants.FlickrParameterValues.APIKey)
        request.addValue(Constants.FlickrParameterKeys.MediaType, forHTTPHeaderField: Constants.FlickrParameterValues.MediaType)
        request.addValue(Constants.FlickrParameterKeys.Extras, forHTTPHeaderField: Constants.FlickrParameterValues.MediumURL)
        request.addValue(Constants.FlickrParameterKeys.Format, forHTTPHeaderField: Constants.FlickrParameterValues.ResponseFormat)
        request.addValue(Constants.FlickrParameterKeys.NoJSONCallback, forHTTPHeaderField: Constants.FlickrParameterValues.DisableJSONCallback)
        request.addValue(Constants.FlickrParameterKeys.Radius, forHTTPHeaderField: Constants.FlickrParameterValues.Radius)
        request.addValue(Constants.FlickrParameterKeys.RadiusUnits, forHTTPHeaderField: Constants.FlickrParameterKeys.RadiusUnits)
        request.addValue(Constants.FlickrParameterKeys.Latitude, forHTTPHeaderField: latString)
        request.addValue(Constants.FlickrParameterKeys.Longitude, forHTTPHeaderField: lonString)
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            guard error == nil else {
                print(error?.localizedDescription ?? "Error retrieving photos")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx")
                return
            }
            
            guard let data = data else {
                print("No data was returned")
                return
            }
            
            self.convertData(data: data) { (result, error) in
                
                if error != nil {
                    // send error
                    return
                }
                
                guard let result = result else {
                    print("No data was returned from parse")
                    return
                }
                
                guard let photoDict = result[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    print("No photos in data")
                    return
                }
                
                guard let totalPages = photoDict[Constants.FlickrResponseKeys.Pages] as? Int else {
                    print("Pages key not found")
                    return
                }
                
                self.getPhotosForPin(annotationView: view, numberOfPages: totalPages)
            }
            
        }
        
        task.resume()
    }
    
    func getPhotosForPin(annotationView view: MKAnnotationView, numberOfPages: Int) {
        
    
        let lat = view.annotation?.coordinate.latitude
        let lon = view.annotation?.coordinate.longitude
        let latString = String(describing: lat)
        let lonString = String(describing: lon)
        
        let pageLimit = min(numberOfPages, 50)
        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
        
        
        let session = URLSession.shared
        
        var url = URLComponents()
        url.scheme = Constants.Flickr.APIScheme
        url.host = Constants.Flickr.APIHost
        url.path = Constants.Flickr.APIPath
        
        let request = NSMutableURLRequest(url: url.url!)
        request.addValue(Constants.FlickrParameterKeys.Method, forHTTPHeaderField: Constants.FlickrParameterValues.SearchMethod)
        request.addValue(Constants.FlickrParameterKeys.APIKey, forHTTPHeaderField: Constants.FlickrParameterValues.APIKey)
        request.addValue(Constants.FlickrParameterKeys.MediaType, forHTTPHeaderField: Constants.FlickrParameterValues.MediaType)
        request.addValue(Constants.FlickrParameterKeys.Extras, forHTTPHeaderField: Constants.FlickrParameterValues.MediumURL)
        request.addValue(Constants.FlickrParameterKeys.Format, forHTTPHeaderField: Constants.FlickrParameterValues.ResponseFormat)
        request.addValue(Constants.FlickrParameterKeys.NoJSONCallback, forHTTPHeaderField: Constants.FlickrParameterValues.DisableJSONCallback)
        request.addValue(Constants.FlickrParameterKeys.Radius, forHTTPHeaderField: Constants.FlickrParameterValues.Radius)
        request.addValue(Constants.FlickrParameterKeys.RadiusUnits, forHTTPHeaderField: Constants.FlickrParameterValues.RadiusUnits)
        request.addValue(Constants.FlickrParameterKeys.Latitude, forHTTPHeaderField: latString)
        request.addValue(Constants.FlickrParameterKeys.Longitude, forHTTPHeaderField: lonString)
        request.addValue(Constants.FlickrParameterKeys.PerPage, forHTTPHeaderField: Constants.FlickrParameterValues.PerPage)
        request.addValue(Constants.FlickrParameterKeys.Page, forHTTPHeaderField: String(randomPage))
        
        let task = session.dataTask(with: request as URLRequest) { (data, response, error) in
            
            guard error == nil else {
                print(error?.localizedDescription ?? "Error retrieving photos")
                return
            }
            
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode, statusCode >= 200 && statusCode <= 299 else {
                print("Your request returned a status code other than 2xx")
                return
            }
            
            guard let data = data else {
                print("No data was returned")
                return
            }
            
            self.convertData(data: data) { (result, error) in
                
                if error != nil {
                    // send error
                    return
                }
                
                guard let result = result else {
                    print("No data was returned from parse")
                    return
                }
                
                guard let photoDict = result[Constants.FlickrResponseKeys.Photos] as? [String:AnyObject] else {
                    print("No photos in data")
                    return
                }
                
                guard let photoArray = photoDict[Constants.FlickrResponseKeys.Photo] as? [[String:AnyObject]] else {
                    print("No photos in photoDict")
                    return
                }
                
                for photo in photoArray {
                    if let urlM = photo["url_m"] as? String {
                        if let geoPic = UIImage(contentsOfFile: urlM) {         // store as Pins & Photos instead
                            GeoPics.sharedInstance().allGeoPics.append(geoPic)
                            print("\(geoPic.description)")
                        }
                    }
                }
            }
        }
        
        task.resume()
    }
    
    private func convertData(data: Data, completionHandler:(_ result: AnyObject?, _ error: Error?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            print("Error parsing JSON")
            let userInfo = [NSLocalizedDescriptionKey: "JSON serialization failed"]
            completionHandler(nil, NSError(domain: "convertData", code: 1, userInfo: userInfo))
        }
        
        completionHandler(parsedResult, nil)
    }
}


