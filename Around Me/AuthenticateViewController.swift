//
//  AuthenticateViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 08.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

class AuthenticateViewController: UIViewController, InstagramClientDelegate {
    

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        InstagramClient.sharedInstance().delegate = self
        println("loaded")
    
    }
    

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        // Checks if an access token already exists. If it does, performs segue.
        if InstagramClient.sharedInstance().restoreAccessToken() {
            //TODO: Performs segue
            println("performs segue")
            
            let myController = storyboard?.instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
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
        println("Logged in succesfully")
    }
}

