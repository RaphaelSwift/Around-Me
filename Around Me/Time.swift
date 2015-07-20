//
//  Time.swift
//  Around Me
//
//  Created by Raphael Neuenschwander on 20.07.15.
//  Copyright (c) 2015 Raphael Neuenschwander. All rights reserved.
//

import Foundation


class Time {
    
    var unixTimeStamp: Double?
    var date: NSDate? {
        if let unixTimeStamp = unixTimeStamp {
            return NSDate(timeIntervalSince1970: unixTimeStamp)
            }
        return nil
    }
    
    init(unixTimeStamp: String) {
        self.unixTimeStamp = NSNumberFormatter().numberFromString(unixTimeStamp)?.doubleValue
    }
    
    // convert the unixTimeStan in the following string format "04:02 PM"
    func getTime() -> String? {
        
        let formatter = NSDateFormatter()
        formatter.locale = NSLocale.currentLocale()
        formatter.dateStyle = NSDateFormatterStyle.ShortStyle
        formatter.dateFormat = "HH:mm a"
        
        if let date = date {
            return formatter.stringFromDate(date)
        }
        
        return nil
    }
    
    
    // Calculate the elapsed time between the unixtimestamp and the current time
    func elapsedTime() -> String? {
        
        let now = NSDate()
        
        var components = NSDateComponents()
        
        if let date = date {
        
        components = NSCalendar.currentCalendar().components(NSCalendarUnit.CalendarUnitDay|NSCalendarUnit.CalendarUnitHour|NSCalendarUnit.CalendarUnitMinute|NSCalendarUnit.CalendarUnitSecond, fromDate: date, toDate: now, options: nil)
            
            var day = components.day
            var hour = components.hour
            var minute = components.minute
            var second = components.second
            
            var postedTimeAgo: String?
            
            if day > 0 {
                postedTimeAgo = "\(day) days ago"
            }
            
            if hour > 0 {
                postedTimeAgo = "\(hour) hours ago"
            }
            
            if minute > 0 {
                postedTimeAgo = "\(minute) minutes ago"
            }
            
            if second > 0 {
                postedTimeAgo = "\(second) seconds ago"
            }
            
            return postedTimeAgo!
        }
        return nil
    }
    
}