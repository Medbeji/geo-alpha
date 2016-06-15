//
//  User.swift
//  GeoAlpha
//
//  Created by Med Beji on 12/06/2016.
//  Copyright © 2016 alphalab. All rights reserved.
//

import Foundation

 class Client {
    
    private var _username: String!
    private var _password: String!
    private var _location:Location?
    private var _userID:String!
    
    
    var username: String {
        return _username
    }
    
    var location: Location {
        set { _location = newValue }
        get { return _location!}
    }
    
    var userID: String {
        return _userID
    }
    
    init(){
        
    }
    
    init (uid:String,username:String,password:String){
        self._userID = uid
        self._username = username
        self._password = password
    }
    
    init (key:String,location:Location,dictionary : Dictionary<String,AnyObject>) {
        
        self._userID = key

        if let username = dictionary["name"] as? String {
            self._username = username
        }
        if let password = dictionary["password"] as? String {
            self._password = password
        }
        
        self._location = location
        
    }
}