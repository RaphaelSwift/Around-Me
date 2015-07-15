//
//  MediaCollectionViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 14.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit
import CoreData

class MediaCollectionViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var mediaCollectionView: UICollectionView!
    
    // Create 3 empty arrays that will keep track of insertions, deletions, updates
    var insertedIndexPaths : [NSIndexPath]!
    var deletedIndexPaths : [NSIndexPath]!
    var updatedIndexPaths : [NSIndexPath]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        fetchedResultController.delegate = self
        
        var fetchError: NSError? = nil
        
        fetchedResultController.performFetch(&fetchError)
        
        if let fetchError = fetchError {
            //Handle error here
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override func viewDidLayoutSubviews() {
        // Lay out the collection view so that cells take up 1/3 of the width,
        // with no space in between.de
        
        let layout : UICollectionViewFlowLayout = UICollectionViewFlowLayout()
        layout.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        layout.minimumLineSpacing = 1
        layout.minimumInteritemSpacing = 1
        
        let width = floor(self.mediaCollectionView.frame.size.width/3) - layout.minimumLineSpacing
        layout.itemSize = CGSize(width: width, height: width)
        
        mediaCollectionView.collectionViewLayout = layout
    }
    
    
    
    // Convenience lazy context var, for easy access to the shared Managed Object Context
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext!
        }()
    
    
    //MARK: - Core Data
    lazy var fetchedResultController: NSFetchedResultsController = {
        
        let fetchRequest = NSFetchRequest(entityName: "Media")
        
        // Sort by the time of creation, starting with the most recent
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: "createdTime", ascending: false)]
        
        let fetchedResultController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: self.sharedContext, sectionNameKeyPath: nil, cacheName: nil)
        
        return fetchedResultController
        
        }()

    
    //MARK: UICollectionViewDelegate, UICollectionViewDataSource
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return fetchedResultController.sections?.count ?? 0
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let sectionInfo = fetchedResultController.sections![section] as! NSFetchedResultsSectionInfo
        return sectionInfo.numberOfObjects
    }
    
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = mediaCollectionView.dequeueReusableCellWithReuseIdentifier("MediaViewCell", forIndexPath: indexPath) as! MediaCollectionViewCell
        
        let media = fetchedResultController.objectAtIndexPath(indexPath) as! Media
        
        configureCell(cell, media: media)
        
        return cell
        
    }
    
    func configureCell(mediaImageCell: MediaCollectionViewCell, media: Media) {
        
        mediaImageCell.imageView.image = UIImage(named: "Placeholder")
        mediaImageCell.timeStampLabel.text = media.createdTime
        mediaImageCell.locationLabel.text =  "\(media.latitude) \(media.longitude)"
        
        // If the image has already been downloaded, display it
        if let photo = media.photoImage {
            mediaImageCell.imageView.image = photo
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
                        mediaImageCell.imageView.image = image
                    }
                }
            }
        }
        
    }
    
    
    
    //MARK: - Add NSFetchedResultsControllerDelegate methods
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        
        // We create the three empty array to handle changes in the collection view
        insertedIndexPaths = [NSIndexPath]()
        deletedIndexPaths = [NSIndexPath]()
        updatedIndexPaths = [NSIndexPath]()
    }
    
    func controller(controller: NSFetchedResultsController, didChangeSection sectionInfo: NSFetchedResultsSectionInfo, atIndex sectionIndex: Int, forChangeType type: NSFetchedResultsChangeType) {
        //Do nothing for the moment.
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        switch type {
            
        case .Insert:
            // Insert the corresponding new indexpath in the array
            insertedIndexPaths.append(newIndexPath!)
            
        case .Delete:
            // Insert the indexpath to delete in the array
            deletedIndexPaths.append(indexPath!)
            
        case .Update:
            // Insert the indexpath to be udpated in the array
            updatedIndexPaths.append(indexPath!)
            
        case .Move:
            break
            
        default :
            break
            
        }
        
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        // loop through the arrays and perform the changes all at once
        dispatch_async(dispatch_get_main_queue()) {
            
            self.mediaCollectionView.performBatchUpdates({() -> Void in
                
                for indexPath in self.insertedIndexPaths {
                    self.mediaCollectionView.insertItemsAtIndexPaths([indexPath])
                }
                
                for indexPath in self.deletedIndexPaths {
                    self.mediaCollectionView.deleteItemsAtIndexPaths([indexPath])
                }
                
                for indexPath in self.updatedIndexPaths {
                    self.mediaCollectionView.reloadItemsAtIndexPaths([indexPath])
                }
                
                }, completion: nil)
            
        }
        
    }

    
    

}
