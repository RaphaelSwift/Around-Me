//
//  Media.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 11.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation
import MapKit
import CoreData

@objc(Media)

class Media: NSManagedObject, MKAnnotation {
    
    
    enum Resolution {
        case LowResolution
        case StandardResolution
        case Thumbnail
    }
    
    struct Keys {
        static let Longitude = "longitude"
        static let Latitude = "latitude"
        static let Location = "location"
        static let Images = "images"
        static let LowResolution = "low_resolution"
        static let Thumbnail = "thumbnail"
        static let StandardResolution = "standard_resolution"
        static let Url = "url"
        static let CreatedTime = "created_time"
        static let Id = "id"
        static let Caption = "caption"
        static let Text = "text"
        static let User = "user"
        static let FullName = "full_name"
    }
    
    @NSManaged var createdTime: String
    @NSManaged var latitude: NSNumber
    @NSManaged var longitude: NSNumber
    @NSManaged var imagePathThumbnail: String
    @NSManaged var imagePathLowRes: String
    @NSManaged var imagePathStandardRes: String
    @NSManaged var id: String
    @NSManaged var captionText: String?
    @NSManaged var fullName: String
    
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String: AnyObject], context: NSManagedObjectContext) {
        
        // Core Data
        let entity = NSEntityDescription.entityForName("Media", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        // Dictionary
        
        // Retrieve the coordinates
        let locationDictionary = dictionary[Media.Keys.Location] as! [String: AnyObject]
        
        latitude = locationDictionary[Media.Keys.Latitude] as! Double
        longitude = locationDictionary[Media.Keys.Longitude] as! Double
        
        
        // Retrieve the image paths
        let imagesDictionary = dictionary[Media.Keys.Images] as! [String: AnyObject]
        imagePathLowRes = imagesDictionary[Media.Keys.LowResolution]![Media.Keys.Url]! as! String
        imagePathStandardRes = imagesDictionary[Media.Keys.StandardResolution]![Media.Keys.Url] as! String
        imagePathThumbnail = imagesDictionary[Media.Keys.LowResolution]![Media.Keys.Url] as! String
        
        // Retrieve the created time
        createdTime = dictionary[Media.Keys.CreatedTime] as! String
        
        // Retrieve the id
        id = dictionary[Media.Keys.Id] as! String
        
        // Retrieve the caption text
        if let captionDictionary = dictionary[Media.Keys.Caption] as? [String:AnyObject] {
            captionText = captionDictionary[Media.Keys.Text] as? String
        }
        
        // Retrieve the name of the user
        let userDictionary = dictionary[Media.Keys.User] as! [String:AnyObject]
        fullName = userDictionary[Media.Keys.FullName] as! String
    
    }
    
    // MKAnnotation
    var coordinate: CLLocationCoordinate2D {
        let coord = CLLocationCoordinate2D(latitude: latitude as! Double, longitude: longitude as! Double)
        
        return coord
    }
    
    
    // When the context is saved, we want to check if the object has been deleted, if it has effectively been, we want to remove it from the cache and document directory as well
    override func didSave() {
        
        if self.deleted {
            InstagramClient.Caches.imageCache.deleteImage(imagePathThumbnail)
            InstagramClient.Caches.imageCache.deleteImage(imagePathLowRes)
            InstagramClient.Caches.imageCache.deleteImage(imagePathStandardRes)
        }
    }
    
    var photoImage: UIImage? {
        
        get {
            return InstagramClient.Caches.imageCache.imageWithIdentifier(imagePathThumbnail)
        }
        
        set {
            InstagramClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePathThumbnail)
        }
    }
    
    var photoImageStandardResolution: UIImage? {
        
        get {
            return InstagramClient.Caches.imageCache.imageWithIdentifier(imagePathStandardRes)
        }
        
        set {
            InstagramClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePathStandardRes)
        }
    }
    
}
