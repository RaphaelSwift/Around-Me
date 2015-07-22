//
//  MediaDetailWebViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 22.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

class MediaDetailWebViewController: UIViewController, UIWebViewDelegate {
    
    var url: String?

    @IBOutlet weak var connectivityProblemLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var webView: UIWebView!
        {
        didSet {
            webView.delegate = self
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        connectivityProblemLabel.alpha = 0.0
        
        let nsurl = NSURL(string: url!)
        let request = NSURLRequest(URL: nsurl!)
        
        webView.loadRequest(request)
    }

    @IBAction func backTouchUpInside(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    //MARK: - UIWebViewDelegate
    
    func webViewDidStartLoad(webView: UIWebView) {
        activityIndicator.startAnimating()
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        activityIndicator.stopAnimating()
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError) {
        
        if error == -1001 {
            self.connectivityProblemLabel.alpha = 1.0
            UIView.animateWithDuration(1.0, delay: 2.0, options: UIViewAnimationOptions.CurveLinear, animations: {self.connectivityProblemLabel.alpha = 0.0}, completion: nil)
        }
    }
}
