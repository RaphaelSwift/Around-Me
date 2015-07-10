//
//  MapViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 09.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    
    // Set the region radius
    let regionRadius: CLLocationDistance = 1000
    
    // Create an instance of our LastKnownMapRegion class
    let lastKnownMapRegion = LastKnownMapRegion()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        locationManager.delegate = self
        
        // Set the map region, to the last known region displayed by the user
        if let lastRegion = lastKnownMapRegion.restoreRegion() {
            mapView.region = lastRegion
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        checkLocationUserStatus()
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func checkLocationUserStatus() {
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.showsUserLocation = true
            
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    
    func centerMapOnLocation(location: CLLocation) {
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, regionRadius, regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
        // Save the region
        lastKnownMapRegion.saveRegion(coordinateRegion)
    }
    
    
    //MARK: - MKMapViewDelegate 
    
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        
        let userCoordinate = mapView.userLocation.location
        centerMapOnLocation(userCoordinate)

    }
    
    
    //MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.showsUserLocation = true
            
        }
    }

}
