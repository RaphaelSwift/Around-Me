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
    
    func getMediaAtUserCoordinateFromInstagram(minTimeStamp: String?, completionHandler: (success: Bool, error: NSError?) -> Void) {
        
        if let userLatitude = dataSource?.userLocation(self)?.coordinate.latitude, userLongitude = dataSource?.userLocation(self)?.coordinate.longitude, searchRadius = dataSource?.searchRadius(self) {
        
            getMediaFromInstagramAtGivenLocation(distanceInMeters: searchRadius, latitude: userLatitude, longitude: userLongitude, minTimeStamp: minTimeStamp) { success, error in
            
                if let error = error {
                    completionHandler(success: false, error: error)
                }
                else {
                    completionHandler(success: true, error: nil)
                }
            }
        }
        
        else {
            completionHandler(success: false, error: NSError(domain: "user", code: 100, userInfo: [NSLocalizedDescriptionKey:"User location is nil"]))
        }
    }
    
    func getMediaFromInstagramAtGivenLocation(distanceInMeters distance: Int, latitude: Double, longitude: Double, minTimeStamp: String?, completionHandler: (success: Bool, error: NSError?) -> Void ) {
        
        let method = Methods.MediaSearch
        
        var parameters: [String: AnyObject] = [
            InstagramClient.UrlKeys.Latitude: latitude,
            InstagramClient.UrlKeys.Longitude: longitude,
            InstagramClient.UrlKeys.Distance: distance,
        ]
        
        if let minTimeStampString = minTimeStamp {
            parameters[InstagramClient.UrlKeys.MinTimeStamp] = minTimeStampString
        }
        
        taskForGetMethod(parameters, method: method) { data, error in
            if let error = error {
                completionHandler(success: false, error: error)
            }
            else {
                if let mediaData = data as? [String:AnyObject], let mediaDatas = mediaData[ResponseKeys.Data] as? [[String: AnyObject]]  {

                    //map the array of dicionary to Media managed objects
                    var mediaDatas = mediaDatas.map() { (dictionary: [String:AnyObject]) -> Media? in
                        
                        // According to Instagram doc, it should return items taken only later than the specified timeStamp. However, I noticed that if it doesn't have any new items, it returns the first or second latest media item, which we want to avoid in our case because it creates duplications. Therefore, we have to check and add only the object if it's more recent than the specified timestamp.
                        if let createdTimeOfReturnedMediaObject = dictionary[ResponseKeys.CreatedTime] as? String {
                            if let minTimeStampMediaObject = minTimeStamp{
                                if createdTimeOfReturnedMediaObject <= minTimeStampMediaObject {
                                    return nil
                                }
                            }
                        }
                        
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



    func downloadAndStoreImages(media: Media, imageResolution: Media.Resolution, completionHandler: (image: UIImage?, error: NSError?) -> Void ){
        
        switch imageResolution {
            
        case .Thumbnail:
            let imagePath = media.imagePathThumbnail
        case .LowResolution:
            let imagePath = media.imagePathLowRes
        case .StandardResolution:
            let imagePath = media.imagePathStandardRes            
        }
    
        if let imagePath = media.imagePathThumbnail {
    
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
}