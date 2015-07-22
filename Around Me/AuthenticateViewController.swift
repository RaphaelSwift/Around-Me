//
//  AuthenticateViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 08.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

class AuthenticateViewController: UIViewController, UIWebViewDelegate, AppDelegateDelegate, InstagramClientDelegate {
    
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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        let appDelegate = AppDelegate()
        appDelegate.delegate = self
        
        connectionLabel.text = "Could not open Instagram authentication page, please check your internet connectivity and try again..."
        connectionLabel.textColor = UIColor.whiteColor()
        connectionLabel.alpha = 0.0
        cancelButton.hidden = true
        
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
    
    // MARK: - AppDelegateDelegate
    func didAuthenticate(token: String?) {
        InstagramClient.sharedInstance().
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

