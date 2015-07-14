//
//  InstagramClient-Convenience.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 09.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation
import UIKit

extension InstagramClient {
    
    func getMediaFromInstagramAtGivenLocation(distanceInMeters distance: Int, latitude: Double, longitude: Double, completionHandler: (success: Bool, error: NSError?) -> Void ) {
        
        let method = Methods.MediaSearch
        
        var parameters: [String: AnyObject] = [
            InstagramClient.UrlKeys.Latitude: latitude,
            InstagramClient.UrlKeys.Longitude: longitude,
            InstagramClient.UrlKeys.Distance: distance,
        ]
        
        taskForGetMethod(parameters, method: method) { data, error in
            if let error = error {
                completionHandler(success: false, error: error)
            }
            else {
                if let mediaData = data as? [String:AnyObject], let mediaDatas = mediaData[ResponseKeys.Data] as? [[String: AnyObject]]  {
                    
                    //map the array of dicionary to Media managed objects
                    
                    var mediaDatas = mediaDatas.map() { (dictionary: [String:AnyObject]) -> Media in
                        
                        let media = Media(dictionary: dictionary, context: CoreDataStackManager.sharedInstance().managedObjectContext!)
                        
                        return media
                    }
                    
                    dispatch_async(dispatch_get_main_queue()) {
                        //Save the objects in the persistent store
                        CoreDataStackManager.sharedInstance().saveContext()
                    }
                    
                    completionHandler(success: true, error: nil)
                }
            }
        }
    }



    func downloadAndStoreImages(media: Media, completionHandler: (image: UIImage?, error: NSError?) -> Void ){
    
            //TODO: Adapt it for standard and low resolution later ?
        let imagePath = media.imagePathThumbnail
    
        taskForImage(imagePath) { data, error in
            if let error = error {
                //Handle error here
                completionHandler(image: nil, error: error)
            }
        
            if let data = data {
                let photoImage = UIImage(data: data)
                
                //Cache the image
                media.photoImage = photoImage
                
                completionHandler(image: photoImage, error: nil)
               }
        }
    }
}