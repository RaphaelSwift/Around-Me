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
            
            if second > 0 {
                if second == 1 {
                    postedTimeAgo = "\(second) second ago"
                } else {
                    postedTimeAgo = "\(second) seconds ago"
                }
            }
            
            if minute > 0 {
                if minute == 1 {
                    postedTimeAgo = "\(minute) minute ago"
                } else {
                    postedTimeAgo = "\(minute) minutes ago"
                }
            }
            
            if hour > 0 {
                if hour == 1 {
                    postedTimeAgo = "\(hour) hour ago"
                } else {
                    postedTimeAgo = "\(hour) hours ago"
                }
            }
            
            if day > 0 {
                if day == 1 {
                    postedTimeAgo = "\(day) day ago"
                }
                else {
                    postedTimeAgo = "\(day) days ago"
                }
            }

            return postedTimeAgo!
        }
        return nil
    }
    
}