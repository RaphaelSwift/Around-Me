//
//  LastKnownMapRegion.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 10.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation
import MapKit

//This class saves and restores a map region using NKeyedArchiver, NSKeyedUnarchiver

class LastKnownMapRegion {
    
        var filePath : String {
        
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("lastKnownMapRegionArchive").path!
    }
    
    
    func saveRegion(region:MKCoordinateRegion) {
        
        let regionAttributes = [
            "centerLat": region.center.latitude,
            "centerLong": region.center.longitude,
            "latitudeDelta": region.span.latitudeDelta,
            "longitudeDelta": region.span.longitudeDelta
        ]
        
        NSKeyedArchiver.archiveRootObject(regionAttributes, toFile: filePath)
        
    }
    
    func restoreRegion() -> MKCoordinateRegion? {
        
        if let region = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? [String: AnyObject] {
            
            let centerLat = region["centerLat"] as! CLLocationDegrees
            let centerLong = region["centerLong"] as! CLLocationDegrees
            let latitudeDelta = region["latitudeDelta"] as! CLLocationDegrees
            let longitudeDelta = region["longitudeDelta"] as! CLLocationDegrees
            
            let center = CLLocationCoordinate2DMake(centerLat, centerLong)
            let span = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
            
            return MKCoordinateRegion(center: center, span: span)
            
        } else {
            
            return nil
        }
        
    }
    
}