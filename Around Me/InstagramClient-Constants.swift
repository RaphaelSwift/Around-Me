//
//  InstagramClient-Constants.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 08.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation

extension InstagramClient {
    
    struct Constants {
        static let ClientID = "6f983ee6a01c41ca937d45205beba287"
        static let BaseURL = "https://api.instagram.com/v1"
        static let AuthenticateBaseURL = "https://api.instagram.com/oauth/authorize/"
        static let RedirectURI = "AroundMe://"
    
    }
    
    struct UrlKeys {
        static let ClientID = "client_id"
        static let RedirectURI = "redirect_uri"
        static let ResponseType = "response_type"
        static let Distance = "distance"
        static let Latitude = "lat"
        static let Longitude = "lng"
        static let AccessToken = "access_token"
        static let MinTimeStamp = "min_timestamp"
    }
    
    struct ResponseKeys {
        static let Location = "location"
        static let Data = "data"
        static let CreatedTime = "created_time"
        static let Id = "id"
    }
    
    struct Methods {
        static let MediaSearch = "/media/search"
    
    }
    
}
