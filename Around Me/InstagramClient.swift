//
//  InstagramClient.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 08.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation
import MapKit

@objc protocol InstagramClientDelegate {
    
    optional func didFinishAuthenticate()
}

class InstagramClient: NSObject {
    
    var delegate:InstagramClientDelegate?
    
    // Set the region radius
    let regionRadius: CLLocationDistance = 3000
    
    // Set the searchRadius
    var searchRadius: Int {
        let radius = Int(regionRadius / 1.5)
        return radius
    }
    
    var userLatitude: Double?
    var userLongitude: Double?
    
    
    // Shared Session
    var session: NSURLSession
    
    override init() {
        session = NSURLSession.sharedSession()
        super.init()
    }
    
    // Each time the token value is set, we store it in the Document directory, using NSKeyedArchiver
    var tokenValue: String? {
        didSet {
            
            if !NSFileManager.defaultManager().fileExistsAtPath(filePath) {
                self.saveAccessToken(tokenValue!)
            }
        }
    }
    
    // We use a property observer to check when we have recieved the returned token from Instagram.
    var authenticated : Bool? {
        didSet {
            if authenticated == true {
                delegate?.didFinishAuthenticate!()
            }
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
    
    // FilePath to store the token
    var filePath: String {
        let manager = NSFileManager.defaultManager()
        let url = manager.URLsForDirectory(NSSearchPathDirectory.DocumentDirectory, inDomains: .UserDomainMask).first as! NSURL
        return url.URLByAppendingPathComponent("accessToken").path!
    }
    

    //MARK: GET Method
    
    func taskForGetMethod(parameters: [String:AnyObject], method: String, completionHandler: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        
        //1. Set the parameters
        var mutableParameters = parameters
        mutableParameters[UrlKeys.AccessToken] = self.tokenValue!
        
        //2. Build the url
        
        let urlString = Constants.BaseURL + method + escapedParameters(mutableParameters)
        let url = NSURL(string: urlString)!
        
        //3. Make the request
        
        let request = NSURLRequest(URL: url)
        
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if let error = error {
                completionHandler(result: nil, error: error)
                
            } else {
                
                var jsonifyError:NSError? = nil
                
                //Parse the Data
                if let parsedData: AnyObject? = NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments , error: &jsonifyError) {
                    
                    if let error = error {
                        completionHandler(result: nil, error: error)
                        
                    } else {
                        completionHandler(result: parsedData, error: nil)
                    }
                }
                
            }
            
        }
        
        // Start the request
        task.resume()
        return task
    }
    
    
    // Task Method to download an image from a given string url
    
    func taskForImage (imagePath: String, completionHandler: (imageData: NSData?, error: NSError?) -> Void ) -> NSURLSessionTask {
        
        let url = NSURL(string: imagePath)!
        
        let request = NSURLRequest(URL: url)
        
        //Make the request
        let task = session.dataTaskWithRequest(request) { data, response, error in
            
            if let error = error {
                completionHandler(imageData: nil, error: error)
                
            } else {
                completionHandler(imageData: data, error: nil)
            }
            
        }
        
        task.resume()
        return task
    }

    
    
    //MARK: - Shared Instance
    
    class func sharedInstance() -> InstagramClient {
        
        struct Singleton {
            static var sharedInstance = InstagramClient()
        }
        return Singleton.sharedInstance
    }
    
    
    //MARK: - NSKeyedArichver
    
    func saveAccessToken(accessToken: String) {
        
        NSKeyedArchiver.archiveRootObject(accessToken, toFile: filePath)
    }
    
    //Return true if an access token exists at this path
    func restoreAccessToken() -> Bool {
        
        if let accessToken = NSKeyedUnarchiver.unarchiveObjectWithFile(filePath) as? String {
            self.tokenValue = accessToken
            
            return true
        }
    
    return false
    }
    
    //MARK: - Shared Cache
    
    struct Caches {
        static let imageCache = ImageCache()
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




