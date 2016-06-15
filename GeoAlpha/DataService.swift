    //
    //  BaseService.swift
    //  GeoAlpha
    //
    //  Created by Med Beji on 10/06/2016.
    //  Copyright © 2016 alphalab. All rights reserved.
    //
    
    import Foundation
    import Firebase
    
    let URL_BASE = "https://alphalab.firebaseio.com/"
    
    class DataService {
        
        static let ds = DataService()
        
        private var _REF_BASE = Firebase(url: "\(URL_BASE)")
        private var _REF_USERS = Firebase(url:"\(URL_BASE)/users")
        private var _REF_CONNECTIONS = Firebase(url:"\(URL_BASE)/connections")
        
        
        var REF_BASE: Firebase {
            return _REF_BASE
        }
        var REF_USERS: Firebase {
            return _REF_USERS
        }
        
        var REF_USER_CURRENT: Firebase {
            let uid = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
            let user = Firebase(url: "\(URL_BASE)").childByAppendingPath("users").childByAppendingPath(uid)
            return user!
            
        }
        
        var REF_CONNECTIONS:Firebase {
            return _REF_CONNECTIONS
        }
        
        var CURRENT_USER_ID : String {
            return CURRENT_USER.authData.uid
        }
        
        var CURRENT_USER: Firebase {
            let userID = NSUserDefaults.standardUserDefaults().valueForKey("uid") as! String
            let currentUser = Firebase(url: "\(REF_USERS.childByAppendingPath(userID))")
            return currentUser
        }
        
        
        func createFirebaseUser(uid: String,user:Dictionary<String,String>){
            
        }
    }