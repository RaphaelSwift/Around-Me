//
//  InstagramClient.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 08.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation

@objc protocol InstagramClientDelegate {
    
    optional func didFinishAuthenticate()
}

class InstagramClient: NSObject {
    
    var delegate:InstagramClientDelegate?
    
    // Shared Session
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // We use a property observer to check when we have recieved the returned token from Instagram.
    var tokenValue: String? {
        didSet {
            
            self.saveAccessToken(tokenValue!)
            delegate?.didFinishAuthenticate!()

        }
    }
    
    
    // Computed property that builds the authenticate url to retrieve the token/code
    var authenticateURL: String {
        
        let parameters: [String:AnyObject] = [
            InstagramClient.UrlKeys.ClientID: InstagramClient.Constants.ClientID,
            InstagramClient.UrlKeys.RedirectURI: InstagramClient.Constants.RedirectURI,
            InstagramClient.UrlKeys.ResponseType: "token"
        ]
        let escapedURL = Constants.AuthenticateBaseURL + self.escapedParameters(parameters)
        
        return escapedURL
    }
    

    
 /*
    //MARK: GET Method
    
    func taskForGetMethod(parameters: [String:AnyObject], completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        //Set the parameters
        var mutableParameters = parameters
        
        
        
        return
    }
   */ 
    
    
    //MARK: - Shared Instance
    
    class func sharedInstance() -> InstagramClient {
        
        struct Singleton {
            static var sharedInstance = InstagramClient()
        }
        return Singleton.sharedInstance
    }
    
    
    //MARK: - NSKeyedArichver
    
    func saveAccessToken(accessToken: String) {
        
        var filePath: String {
            let manager = NSFileManager.defaultManager()
            let url = manager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
            return url.URLByAppendingPathComponent("accessToken").path!
        }
        
        NSKeyedArchiver.archiveRootObject(accessToken, toFile: filePath)
    }
    
    //Return true if an access token exists at this path
    func restoreAccessToken() -> Bool {
        
        var filePath: String {
            let manager = NSFileManager.defaultManager()
            let url = manager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
            return url.URLByAppendingPathComponent("accessToken").path!
        }
        
        if let accessToken = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? String {
            self.tokenValue = accessToken
            
            return true
        }
    
    return false
    }
    
    
    //MARK: - Helpers
    
    // Helper function, given a dictionary of parameters, convert to a string for a URL
    func escapedParameters(parameters: [String:AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key,value) in parameters {
            
            let valueString = "\(value)"
            
            let escapedValue = valueString.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            urlVars.append("\(key)=\(escapedValue!)")
            
        }
        
        return (!urlVars.isEmpty ? "?" : "") + join("&" , urlVars)
    }
}




