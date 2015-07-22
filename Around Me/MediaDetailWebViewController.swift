//
//  MediaDetailWebViewController.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 22.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import UIKit

class MediaDetailWebViewController: UIViewController {

    @IBOutlet weak var webView: UIWebView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let nsurl = NSURL(string: "https://instagram.com/p/5cNAoXM1b5/")
        
        let request = NSURLRequest(URL: nsurl!)
        
        webView.loadRequest(request)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func backTouchUpInside(sender: UIButton) {
        
        self.dismissViewControllerAnimated(true, completion: nil)
    }
}
