//
//  AuthenticateViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 08.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

class AuthenticateViewController: UIViewController, UIWebViewDelegate, InstagramClientDelegate {
    
    @IBOutlet var uiView: UIView!
    @IBOutlet weak var signWithInstagramButton: UIButton!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var connectionLabel: UILabel!
    @IBOutlet weak var cancelButton: UIButton!
    

    @IBOutlet weak var authenticateWebView: UIWebView! {
        didSet {
            authenticateWebView.delegate = self
        }
    }
    
    
    //MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        InstagramClient.sharedInstance().delegate = self
        
        connectionLabel.text = "Could not open Instagram authentication page, please check your internet connectivity and try again..."
        connectionLabel.textColor = UIColor.whiteColor()
        connectionLabel.alpha = 0.0
        cancelButton.hidden = true
        
        // Design the Sign In button & UIView background
        signWithInstagramButton.backgroundColor = UIColor(red:0/255, green:64/255, blue:128/255, alpha:1)
        signWithInstagramButton.layer.cornerRadius = 5
        uiView.backgroundColor = UIColor(red:0/255, green:64/255, blue:128/255, alpha:0.3)
        
        if InstagramClient.sharedInstance().tokenValue != nil {
            self.signWithInstagramButton.hidden = true
        }
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(true)
        
        // Checks if an access token already exists. If it does, performs segue.
        if InstagramClient.sharedInstance().tokenValue != nil {
            
            let myController = storyboard?.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
            self.presentViewController(myController, animated: true, completion: nil)
        }
    }
    

    //MARK: - Actions
    
    @IBAction func authenticate() {
        
        //UIApplication.sharedApplication().openURL(NSURL(string: InstagramClient.sharedInstance().authenticateURL)!)
        let request = NSURLRequest(URL: NSURL(string: InstagramClient.sharedInstance().authenticateURL)!)
        self.authenticateWebView.loadRequest(request)
    
    }
    
    
    @IBAction func cancelTouchUpInside() {
        self.authenticateWebView.stopLoading()
        self.authenticateWebView.hidden = true
        self.cancelButton.hidden = true
    }
    
    
    // MARK: - InstagramClientDelegate
    
    func didFinishAuthenticate() {
        
        let myController = storyboard?.instantiateViewControllerWithIdentifier("TabBarController") as! UITabBarController
        self.presentViewController(myController, animated: true, completion: nil)
    }
    
    
    //MARK: - UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView) {
        self.activityIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        self.activityIndicator.stopAnimating()
        self.authenticateWebView.hidden = false
        self.cancelButton.hidden = false
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        
        self.activityIndicator.stopAnimating()
        
        if error.code == -1001 {
            self.connectionLabel.alpha = 1.0
            UIView.animateWithDuration(1.0, delay: 2.0, options: UIViewAnimationOptions.CurveLinear, animations: {self.connectionLabel.alpha = 0.0}, completion: nil)
        }
        
    }
}

