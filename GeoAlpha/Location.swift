//
//  Location.swift
//  GeoAlpha
//
//  Created by Med Beji on 12/06/2016.
//  Copyright © 2016 alphalab. All rights reserved.
//

import Foundation

class Location {
    
    private var _latitude: Double!
    private var _longitude: Double!
    private var _locationName: String?
    
    var latitude : Double{
        return _latitude
    }
    
    var longitude : Double {
        return _longitude
    }
    
    var locationName : String {
        return _locationName!
    }
    init(){
    }
    init ( latitude: Double,longitude:Double){
    
    
    }
    init( latitude: Double,longitude:Double , locationName:String){
    
    
    }
    
    init(dictionary : Dictionary<String,AnyObject>){
        
        if let latitude = dictionary["latitude"] as? Double {
            self._latitude = latitude
        }
        
        if let longitude = dictionary["longitude"] as? Double {
            self._longitude = longitude
        }
        
        }
}