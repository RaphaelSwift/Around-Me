//
//  MapViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 09.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mapView: MKMapView!
    
    var locationManager = CLLocationManager()
    
    let refreshRate = 20.0
    
    @IBOutlet weak var searchRadiusSlider: UISlider!
    
    // The overlay currently displayed
    var currentOverlay: MKOverlay?
    
    // Create an instance of our LastKnownMapRegion class
    let lastKnownMapRegion = LastKnownMapRegion()
    
    // Convenience lazy context var, for easy access to the shared Managed Object Context
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    
    //MARK: - Lifecyle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchRadiusSlider.enabled = false
        
        //Set the delegates
        locationManager.delegate = self
        fetchedResultController.delegate = self
        
        // Set the map region, to the last known region displayed by the user
        if let lastRegion = lastKnownMapRegion.restoreRegion() {
            mapView.region = lastRegion
        }
        
        // Fetch the Media data from Core Data
        var fetchError: NSError? = nil
        
        fetchedResultController.performFetch(&fetchError)
        
        if let fetchError = fetchError {
            println(fetchError.localizedDescription)
        }
        
        // Add the media locations to the map
        self.mapView.addAnnotations(fetchedResultController.fetchedObjects)
        
        // Set a refresh timer
        let timer = NSTimer.scheduledTimerWithTimeInterval(self.refreshRate, target: self, selector: "fetchRecentDataFromInstagram", userInfo: nil, repeats: true)
        
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
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, InstagramClient.sharedInstance().regionRadius, InstagramClient.sharedInstance().regionRadius)
        mapView.setRegion(coordinateRegion, animated: true)
        
        // Save the region
        lastKnownMapRegion.saveRegion(coordinateRegion)
    }
    
    
    //MARK: - Core Data
    lazy var fetchedResultController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Media")
        
        // Sort by the time of creation, starting with the most recent
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdTime", ascending: false)]
        
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultController
        
    }()
    
    
    //MARK: - MKMapViewDelegate 
    
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        
        if !searchRadiusSlider.enabled {
            searchRadiusSlider.enabled = true
        }
        
        // Each time the location of the user changes, center the map on the user
        let userCoordinate = userLocation.location
        centerMapOnLocation(userCoordinate)
        
        // And adjust the overlay
        
        //1. Remove the existing overlay
        if let currentOverlay = currentOverlay {
            self.mapView.removeOverlay(currentOverlay)
        }
        
        //2. Add a new overlay with the new user location
        let circle = MKCircle(centerCoordinate: CLLocationCoordinate2D(latitude: userCoordinate.coordinate.latitude, longitude: userCoordinate.coordinate.longitude), radius: Double(searchRadiusSlider.value))
        self.mapView.addOverlay(circle)
        
        self.currentOverlay = circle
        
        // Update our model
        InstagramClient.sharedInstance().userLatitude = userCoordinate.coordinate.latitude
        InstagramClient.sharedInstance().userLongitude = userCoordinate.coordinate.longitude
        
        // Then retrieve new media, that were posted after our latest media item. If minTimeStamp is nil, it ll covers the last 5 days.
       self.fetchRecentDataFromInstagram()
        
    }
    
    // Create a circle renderer for rendering our shape
    func mapView(mapView: MKMapView!, rendererForOverlay overlay: MKOverlay!) -> MKOverlayRenderer! {
        if overlay.isKindOfClass(MKCircle) {
            
            let aRenderer = MKCircleRenderer(overlay: overlay)
            aRenderer.fillColor = UIColor.cyanColor().colorWithAlphaComponent(0.1)
            aRenderer.strokeColor = UIColor.blueColor().colorWithAlphaComponent(0.7)
            aRenderer.lineWidth = 1.5
        
            return aRenderer
        }
        
        return nil
    }
    
    
    func mapView(mapView: MKMapView!, viewForAnnotation annotation: MKAnnotation!) -> MKAnnotationView! {
        // Check if the annotation is the user annotation
        if annotation.isKindOfClass(MKUserLocation) {
            return nil
        }
        
        // Handle custom annotation class Media
        if annotation.isKindOfClass(Media) {
            
            //Try to dequeue an existing pin view first
            var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier("MediaPin") as? MKPinAnnotationView
            
            //If an existing pin view was not available, create one
            
            if pinView == nil {
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: "MediaPin")
                
                pinView?.image = UIImage(named: "Placeholder")
                
                //self.configurePinView(pinView, media: annotation as! Media)

            }
            
            else {
                pinView?.annotation = annotation
            }
            
            self.configurePinView(pinView, media: annotation as! Media)
            pinView?.setNeedsDisplay()
            
            return pinView
        }
        
        return nil
    }
    
    
    func configurePinView(pinView: MKPinAnnotationView?, media: Media) {
        
        // If the image has already been downloaded, display it
        if let photo = media.photoImage {
            pinView?.image = photo
        }
        else {
            
            // Else, download it
            InstagramClient.sharedInstance().downloadAndStoreImages(media) { image, error in
                if let error = error {
                    //Handle error
                }
                else {
                    //And display it
                    dispatch_async(dispatch_get_main_queue()) {
                        pinView?.image = image
                        pinView?.frame.size.height = 40
                        pinView?.frame.size.width = 40
                        
                    }
                }
            }
        }
        
        pinView?.frame.size.width = 40
        pinView?.frame.size.height = 40
        
    }
    
    //MARK: - Actions
    
    @IBAction func sliderValueChanged(sender: UISlider) {
        
        let circle = MKCircle(centerCoordinate: CLLocationCoordinate2D(latitude: mapView.userLocation.location.coordinate.latitude ,longitude: mapView.userLocation.coordinate.longitude), radius: Double(sender.value))
        self.mapView.addOverlay(circle)
        self.mapView.removeOverlay(self.currentOverlay)
            
        self.currentOverlay = circle
            
        
    
    }
    
    @IBAction func sliderTouchUpInside(sender: UISlider) {
        
        InstagramClient.sharedInstance().searchRadius = Int(sender.value)
        fetchRecentDataFromInstagram()
        
    }
    

    
    //MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
    }
    
    //MARK: - NSFetchedResultControllerDelegate
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
        case .Insert:
            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.addAnnotation(anObject as! Media)
            }
        
        case .Delete:
            dispatch_async(dispatch_get_main_queue()) {
            self.mapView.removeAnnotation(anObject as! Media)
            }
            
        case .Update:
            dispatch_async(dispatch_get_main_queue()) {
                self.mapView.addAnnotation(anObject as! Media)
            }
            
        default:
            return
            
        }
    }
    
    
    //MARK: - Helpers & convenience
    
    
    func fetchRecentDataFromInstagram() {
        
        // First delete all the media that are not within the overlay
        deleteOutOfRangeMediaObjects(self.currentOverlay!)
        
        // Then get the new media
        InstagramClient.sharedInstance().getMediaAtUserCoordinateFromInstagram(getLatestCreatedTime()) { success, error in
            
            if success {
                
            }
            
            if let error = error {
                //handle error here
            }
        }
    }
    
    
    // This method retrieve the created time of the latest media
    func getLatestCreatedTime() -> String? {
        
        //As the fetched objects are sorted by creation time in a descending order, we can simply get the first object and retrieve the created time
        
        if let media = fetchedResultController.fetchedObjects?.first as? Media {
            let createdTime = media.createdTime
            return createdTime
        }
        
        return nil
    }
    
    // Delete media objects that are not within our search radius
    func deleteOutOfRangeMediaObjects(overlay: MKOverlay) {
        
        let circleRenderer = MKCircleRenderer(overlay: overlay)
        
        if let fetchedObjects = fetchedResultController.fetchedObjects as? [Media] {
            
            // Loop through all fetched media objects and delete the ones which coordinates are not within the overlay
            for media in fetchedObjects {
                
                let mapPoint = MKMapPointForCoordinate(media.coordinate)
                let circleViewPoint = circleRenderer.pointForMapPoint(mapPoint)
            
                let mapCoordinateIsInCircle = CGPathContainsPoint(circleRenderer.path, nil, circleViewPoint, false)
            
                if !mapCoordinateIsInCircle {
                        self.sharedContext.deleteObject(media)
                }
            }
        }
        
        //Save the context (ie. commit the changes)
        CoreDataStackManager.sharedInstance().saveContext()
        
    }
    
    

    
}
