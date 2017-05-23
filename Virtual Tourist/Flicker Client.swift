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

    
    let stack = CoreDataStack.sharedInstance()
    let context = CoreDataStack.sharedInstance().context
    
    
    func getRandomPhotosForPin(pin pinView: Pin, completionHandlerForRandomPhotos: @escaping (_ photos: [Photo]) -> Void) {
        
        // gets number of pages returned from flikr
        
        let lat = pinView.latitude
        let lon = pinView.longitude
        let latString = String(lat)
        let lonString = String(lon)
        print(latString, lonString)
        
        let session = URLSession.shared
        
        let queryItems = [Constants.FlickrParameterKeys.Method:Constants.FlickrParameterValues.SearchMethod,
                          Constants.FlickrParameterKeys.APIKey:Constants.FlickrParameterValues.APIKey,
                          Constants.FlickrParameterKeys.MediaType:Constants.FlickrParameterValues.MediaType,
                          Constants.FlickrParameterKeys.Extras:Constants.FlickrParameterValues.MediumURL,
                          Constants.FlickrParameterKeys.Format:Constants.FlickrParameterValues.ResponseFormat,
                          Constants.FlickrParameterKeys.NoJSONCallback:Constants.FlickrParameterValues.DisableJSONCallback,
                          Constants.FlickrParameterKeys.Radius:Constants.FlickrParameterValues.Radius,
                          Constants.FlickrParameterKeys.RadiusUnits:Constants.FlickrParameterValues.RadiusUnits,
                          Constants.FlickrParameterKeys.Latitude:latString,
                          Constants.FlickrParameterKeys.Longitude:lonString]
        
        
        let request = NSMutableURLRequest(url: constructURL(queryItems as [String : AnyObject]))
        
        
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
                    print(error!.localizedDescription)
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
                
                self.getPhotosForPin(pin: pinView, numberOfPages: totalPages) { photos in
                    completionHandlerForRandomPhotos(photos)
                }
            }
            
        }
        
        task.resume()
    }
    
    private func getPhotosForPin(pin pinView: Pin, numberOfPages: Int, completionForGetPhotos: @escaping (_ photos: [Photo]) -> Void) {
        
    
        let lat = pinView.latitude
        let lon = pinView.longitude
        let latString = String(lat)
        let lonString = String(lon)
        
        let pageLimit = min(numberOfPages, 50)
        let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
        print("\(numberOfPages) total pages")
        print("\(pageLimit) page limit")
        print("\(randomPage) random page number")
        
        
        let session = URLSession.shared
        
        let queryItems = [Constants.FlickrParameterKeys.Method:Constants.FlickrParameterValues.SearchMethod,
                          Constants.FlickrParameterKeys.APIKey:Constants.FlickrParameterValues.APIKey,
                          Constants.FlickrParameterKeys.MediaType:Constants.FlickrParameterValues.MediaType,
                          Constants.FlickrParameterKeys.Extras:Constants.FlickrParameterValues.MediumURL,
                          Constants.FlickrParameterKeys.Format:Constants.FlickrParameterValues.ResponseFormat,
                          Constants.FlickrParameterKeys.NoJSONCallback:Constants.FlickrParameterValues.DisableJSONCallback,
                          Constants.FlickrParameterKeys.Radius:Constants.FlickrParameterValues.Radius,
                          Constants.FlickrParameterKeys.RadiusUnits:Constants.FlickrParameterValues.RadiusUnits,
                          Constants.FlickrParameterKeys.Latitude:latString,
                          Constants.FlickrParameterKeys.Longitude:lonString,
                          Constants.FlickrParameterKeys.PerPage:Constants.FlickrParameterValues.PerPage,
                          Constants.FlickrParameterKeys.Page:String(randomPage)]
        
        let request = NSMutableURLRequest(url: constructURL(queryItems as [String : AnyObject]))
        
        
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
                
                // Do I put photoArray^ in the closure expression and then convert data like below? Or will this not work outside of this network function?
                
                var allPhotos = [Photo]()
                
                for photo in photoArray {
                    if let urlM = photo["url_m"] as? String {
                        if let photoData = NSData(contentsOf: URL(string: urlM)!) {
                            let photo = Photo(imageData: photoData, context: self.context)
                            allPhotos.append(photo)
                            print(photo)
                        }
                    }
                }
                
                completionForGetPhotos(allPhotos)
            }
        }
        
        task.resume()
    }
    
    // Utilities
    
    private func convertData(data: Data, completionHandler:(_ result: AnyObject?, _ error: Error?) -> Void) {
        
        var parsedResult: AnyObject! = nil
        
        do {
            parsedResult = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as AnyObject
        } catch {
            print("Error parsing JSON (convertData)")
            let userInfo = [NSLocalizedDescriptionKey: "JSON serialization failed"]
            completionHandler(nil, NSError(domain: "convertData", code: 1, userInfo: userInfo))
        }
        
        completionHandler(parsedResult, nil)
    }
    
    private func constructURL(_ dictionary: [String:AnyObject]) -> URL {
        
        var components = URLComponents()
        components.scheme = Constants.Flickr.APIScheme
        components.host = Constants.Flickr.APIHost
        components.path = Constants.Flickr.APIPath
        components.queryItems = [URLQueryItem]()
        
        for (key, value) in dictionary {
            let queryItem = URLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        return components.url!
    }
}


