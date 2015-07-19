//
//  AuthenticateViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 08.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

class AuthenticateViewController: UIViewController, InstagramClientDelegate {
    
    @IBOutlet var uiView: UIView!
    @IBOutlet weak var signWithInstagramButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        InstagramClient.sharedInstance().delegate = self
        
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(true)
        
        
        // Design the Sign In button & UIView background
        
        signWithInstagramButton.backgroundColor = UIColor(red:0/255, green:64/255, blue:128/255, alpha:1)
        
        signWithInstagramButton.layer.cornerRadius = 5

        uiView.backgroundColor = UIColor(red:0/255, green:64/255, blue:128/255, alpha:0.3)
        
    }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        // Checks if an access token already exists. If it does, performs segue.
        if InstagramClient.sharedInstance().restoreAccessToken() {
            
            let myController = storyboard?.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
            self.presentViewController(myController, animated: true, completion: nil)
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func authenticate() {
        
        UIApplication.sharedApplication().openURL(NSURL(string: InstagramClient.sharedInstance().authenticateURL)!)
    
    }
    
    // MARK: InstagramClientDelegate
    func didFinishAuthenticate() {
        
        let myController = storyboard?.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
        self.presentViewController(myController, animated: true, completion: nil)
    }
}

