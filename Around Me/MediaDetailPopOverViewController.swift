//
//  MediaDetailPopOverViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 20.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

class MediaDetailPopOverViewController: UIViewController {

    @IBOutlet weak var mediaImageView: UIImageView!
    
    @IBOutlet weak var mediaCaptionTextLabel: UILabel!
    @IBOutlet weak var elapsedTimeLabel: UILabel!
    
    var mediaImage : UIImage!
    var media: Media!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        mediaCaptionTextLabel.alpha = 0.0
        
        let time = Time(unixTimeStamp: media.createdTime)
        if let elapsedTimeSinceMediaHasBeenPosted = time.elapsedTime() {
            self.elapsedTimeLabel.text = "\(elapsedTimeSinceMediaHasBeenPosted) by \(media.fullName)"
        }
        
        mediaImageView.image =  mediaImage
        if let mediaText = media.captionText {
            mediaCaptionTextLabel.text = mediaText
        }
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        UIView.animateWithDuration(1.0, delay: 1.5, options: UIViewAnimationOptions.TransitionFlipFromBottom, animations: {self.elapsedTimeLabel.alpha = 0.0}) { animationEnded in
            
            if animationEnded {
                self.mediaCaptionTextLabel.alpha = 1
            }
            
        }
        
    }

}
