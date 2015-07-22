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

class MapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, NSFetchedResultsControllerDelegate, UIPopoverPresentationControllerDelegate, UIAdaptivePresentationControllerDelegate, InstagramClientDataSource {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var searchRadiusSlider: UISlider!
    
    var locationManager = CLLocationManager()
    let refreshControl = UIRefreshControl()
    var refreshTimer = NSTimer()
    let userDefault = NSUserDefaults()
    
    let refreshRate = 10.0
    let maxMediaObjectsToDisplay = 50
    
    var tapGestureRecognizer: UIGestureRecognizer? = nil
    let searchRadiusKey = "searchRadius"
    
    // Used when segueing to MediaDetailWebViewController
    var lastMediaPinSelected: Media!

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
        
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: "displayDetails:")
        
        // Initial settings
        self.tabBarController?.tabBar.userInteractionEnabled = false
        refreshButton.enabled = false
        searchRadiusSlider.enabled = false
        searchRadiusSlider.value = userDefault.floatForKey(searchRadiusKey)
        
        //Set the delegates
        locationManager.delegate = self
        fetchedResultController.delegate = self
        InstagramClient.sharedInstance().dataSource = self
        
        
        // Set the map region, to the last known region displayed by the user
        if let lastRegion = lastKnownMapRegion.restoreRegion() {
            mapView.region = lastRegion
        }
        
        // Fetch the Media data from Core Data
        var fetchError: NSError? = nil
        
        fetchedResultController.performFetch(&fetchError)
        
        if let fetchError = fetchError {
            //Handle error here
        }
        
        // Add the media locations to the map
        self.mapView.addAnnotations(fetchedResultController.fetchedObjects)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        checkLocationUserStatus()
        startTimer()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(true)
        refreshTimer.invalidate()
    }

    
    //MARK: - Actions
    
    // Each time the value of the slider changes, adjust the overlay
    @IBAction func sliderValueChanged(sender: UISlider) {
        
        let circle = MKCircle(centerCoordinate: CLLocationCoordinate2D(latitude: mapView.userLocation.location.coordinate.latitude ,longitude: mapView.userLocation.coordinate.longitude), radius: Double(sender.value))
        self.mapView.addOverlay(circle)
        self.mapView.removeOverlay(self.currentOverlay)
        self.currentOverlay = circle
    }
    
    @IBAction func sliderTouchUpInside(sender: UISlider) {
        
        //1. Delete all the media that are not within the overlay
        if let currentOverlay = self.currentOverlay {
            deleteOutOfRangeMediaObjects(self.currentOverlay!)
        }
        
        //2. Fetch RecentDataFromInstagram
        fetchRecentDataFromInstagram()
        
        //3. Save the prefered search radius
        userDefault.setFloat(sender.value, forKey: searchRadiusKey)
    }
    
    @IBAction func refreshTouchUpInside(sender: AnyObject) {
        
        fetchRecentDataFromInstagram()
    }
    
    
    //MARK: - Convenience UI methods
    
    func checkLocationUserStatus() {
        
        if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.Denied {
            
            displayAlertController("Location Service Denied", errorMessage: "Location service are off. To use location service you must turn on 'While Using The App' in the Location Services Settings. The apps requires location service to function correctly.", networkError: nil)
            
        } else if CLLocationManager.authorizationStatus() == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.showsUserLocation = true
            
        } else {
            locationManager.requestWhenInUseAuthorization()
        }
    }
    
    func centerMapOnLocation(location: CLLocation) {
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(location.coordinate, Double(searchRadiusSlider.value * 1.5), Double(searchRadiusSlider.value * 1.5))
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
    
    
    //MARK: - InstagramClientDataSource
    
    func searchRadius(sender: InstagramClient) -> Int? {
        return Int(searchRadiusSlider.value)
    }
    
    func userLocation(sender: InstagramClient) -> CLLocation? {
        return mapView.userLocation.location ?? nil
    }
    
    
    //MARK: - MKMapViewDelegate 
    
    func mapView(mapView: MKMapView!, didUpdateUserLocation userLocation: MKUserLocation!) {
        
        if !self.tabBarController!.tabBar.userInteractionEnabled {
            self.tabBarController?.tabBar.userInteractionEnabled = true
        }
        
        if !searchRadiusSlider.enabled {
            searchRadiusSlider.enabled = true
        }
        
        if !refreshButton.enabled {
            refreshButton.enabled = true
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
        
        //3. First delete all the media that are not within the overlay
        if let currentOverlay = self.currentOverlay {
            deleteOutOfRangeMediaObjects(self.currentOverlay!)
        }
        
        //4. Then retrieve new media, that were posted after our latest media item. If minTimeStamp is nil, it ll covers the last 5 days.
       self.fetchRecentDataFromInstagram()
        
    }
    
    // Create a circle renderer for rendering our circle shape
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
    
    func mapView(mapView: MKMapView!, didSelectAnnotationView view: MKAnnotationView!) {
        
        //Present the image in a popover view controller
        let controller = storyboard?.instantiateViewControllerWithIdentifier("MediaDetailPopOverViewController") as! MediaDetailPopOverViewController
        controller.modalPresentationStyle = UIModalPresentationStyle.Popover
        controller.preferredContentSize = CGSizeMake(200, 200)
        
        //Add a gesture recognizer to the popover controller's view
        controller.view.addGestureRecognizer(tapGestureRecognizer!)
        
        //Set the lastMediaPinSelected, to be used when segueing to MediaDetailWebViewController
        lastMediaPinSelected = view.annotation as! Media
        
        let popOverController = controller.popoverPresentationController
        popOverController?.delegate = self
        popOverController?.sourceView = self.view
        
        // Position the popover on the pin that was selected
        let point = mapView.convertCoordinate(view.annotation.coordinate, toPointToView: super.view)
        popOverController?.sourceRect = CGRectMake(point.x, point.y, 0, 0)
        
        // Pass the data and present the popover controller
        controller.mediaImage = view.image
        controller.media = view.annotation as! Media
        self.presentViewController(controller, animated: true, completion: nil)
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
            }
            
            else {
                pinView?.annotation = annotation
            }
            
            self.configurePinView(pinView, media: annotation as! Media)
            
            return pinView
        }
        return nil
    }
    
    
    //MARK: - PinView Convenience Method
    
    func configurePinView(pinView: MKPinAnnotationView?, media: Media) {
        
        // If the image has already been downloaded, display it
        if let photo = media.photoImage {
            pinView?.image = photo
        }
        else {
            // Else, download it
            InstagramClient.sharedInstance().downloadAndStoreImages(media, imageResolution: Media.Resolution.Thumbnail) { image, error in
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
    
    
    //MARK: - UIAdaptivePresentationControllerDelegate
    
    // We need to implement this method, so that the popover presentation doesnt take full screen on Iphone
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return .None
    }
    
    
    //MARK: - CLLocationManagerDelegate
    
    func locationManager(manager: CLLocationManager!, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == CLAuthorizationStatus.AuthorizedWhenInUse {
            mapView.showsUserLocation = true
        }
        
        if status == CLAuthorizationStatus.Denied {
            searchRadiusSlider.enabled = false
            refreshButton.enabled = false
            self.tabBarController?.tabBar.userInteractionEnabled = false
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
        
        if self.refreshControl.refreshing == false {
            self.refreshControl.beginRefreshing()
            
            self.deleteExceedingMediaObjects()
            
            // Then get the new media
            InstagramClient.sharedInstance().getMediaAtUserCoordinateFromInstagram(getLatestCreatedTime()) { success, error in
                
                self.refreshControl.endRefreshing()
                
                if let error = error {
                    
                    //Check for an internet connectivity error
                    if error.code == -1001 {
                        self.displayAlertController("Error", errorMessage: "The request timed out. Please check your internet connectivity", networkError: true)
                    }
                }
            }
        }
    }
    
    
    // Retrieve the created time of the latest media
    func getLatestCreatedTime() -> String? {
        
        //As the fetched objects are sorted by creation time in a descending order, we can simply get the first object and retrieve the created time
        if let media = fetchedResultController.fetchedObjects?.first as? Media {
            let createdTime = media.createdTime
            return createdTime
        }
        return nil
    }
    
    // Check the number of media objects and delete the ones exceeding the maximum limit, deleting the oldest ones...
    func deleteExceedingMediaObjects() {
        
        if let fetchedObjectsCount = fetchedResultController.fetchedObjects?.count {
            let numberOfObjectsToDelete = fetchedObjectsCount - self.maxMediaObjectsToDisplay
            
            if numberOfObjectsToDelete > 0 {
                
                var fetchedObjectToDelete = fetchedResultController.fetchedObjects!
            
                for index in 1...numberOfObjectsToDelete {

                    self.sharedContext.deleteObject(fetchedObjectToDelete.removeLast() as! Media)

                }
            }
            //Save the context (ie. commit the changes)
            CoreDataStackManager.sharedInstance().saveContext()
        }
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
    
    // Start the timer
    func startTimer() {
        refreshTimer = NSTimer.scheduledTimerWithTimeInterval(self.refreshRate, target: self , selector: "fetchRecentDataFromInstagram", userInfo: nil, repeats: true)
    }
    
    //MARK: - UIAlertController
    
    func displayAlertController(errorTitle:String ,errorMessage:String, networkError: Bool?) {
        
        let alert = UIAlertController(title: "Error", message: errorMessage, preferredStyle: UIAlertControllerStyle.Alert)
        
        let action = UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: nil)
        
        alert.addAction(action)
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func displayDetails(recognizer: UITapGestureRecognizer) {
        
        let controller = storyboard!.instantiateViewControllerWithIdentifier("MediaDetailWebViewController") as! MediaDetailWebViewController
        self.presentedViewController?.dismissViewControllerAnimated(true, completion: nil)
        controller.url = lastMediaPinSelected.link
        presentViewController(controller, animated: true, completion: nil)

    }
}
