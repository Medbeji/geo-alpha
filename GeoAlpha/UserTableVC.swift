//
//  MyTableVC.swift
//  GeoAlpha
//
//  Created by Med Beji on 12/06/2016.
//  Copyright © 2016 alphalab. All rights reserved.
//

import UIKit
import Firebase
import MapKit

class UserTableVC: UITableViewController  ,MKMapViewDelegate  {
    
    var locationManager: CLLocationManager!
    var users = [Client]()
    var authenDict = Dictionary<String,Bool>()
    var isAuthorized = false
    var usersConnectedWith = [String]()
    var myConnectionsHistory: [String] = []
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        tableView.delegate = self
        tableView.dataSource = self
        self.showUsers()
        usersConnectedWith = []
        self.listeningForDemands()
        self.locationSetting()
        
    }
    
    func locationSetting(){
        
        self.locationManager = CLLocationManager()
        self.locationManager.requestAlwaysAuthorization()
        self.locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
        }
    }
    
    
    func showUsers(){
        DataService.ds.REF_USERS.observeEventType(.Value, withBlock: {
            snapshot in
            self.users = []
            if let snapshots = snapshot.children.allObjects as? [FDataSnapshot] {
                for snap in snapshots {
                    var userLocation = Location()
                    if let userDict = snap.value as? Dictionary<String,AnyObject> {
                        let location = snap.children.nextObject() as? FDataSnapshot
                        if let userLoc = location!.value as? Dictionary<String,AnyObject> {
                            userLocation = Location(dictionary: userLoc)
                        }
                        let key = snap.key
                        let user = Client(key: key, location: userLocation,dictionary: userDict)
                        if user.userID != DataService.ds.CURRENT_USER_ID {
                            self.users.append(user)
                        }
                        if ( self.authenDict[user.userID] == nil) {
                            self.authenDict[user.userID] = false
                        }
                        self.listeningForDemandsResponse(user.userID)
                        
                    }
                }
            }
            self.tableView.reloadData()
        })
    }
    
    func listeningForDemands(){
        
        DataService.ds.REF_CONNECTIONS.childByAppendingPath(DataService.ds.CURRENT_USER_ID).observeEventType(.Value, withBlock: {
            snapshot in
            if  !(snapshot.value is NSNull){
                let userDict = snapshot.value as? Dictionary<String,AnyObject>
                let userIDSource = Array(userDict!.keys)[0] as String
                // We can  get information about the user from Firebase here ...
                var showAlert = true
                
                for user in self.usersConnectedWith {
                    if user == userIDSource {
                        showAlert = false
                    }
                }
                
                if showAlert {
                    self.usersConnectedWith.append(userIDSource)
                    // Show Alerte!
                    self.ShowAlert(" Show me your location request arrived ! ",msg: "\(userIDSource) want to get your location",usrIDSrc: userIDSource)
                }
                
            }
        })
        
    }
    
    
    
    func listeningForDemandsResponse(userID:String){
        
        DataService.ds.REF_CONNECTIONS.childByAppendingPath(userID).childByAppendingPath(DataService.ds.CURRENT_USER_ID).observeEventType(.Value, withBlock: {
            snapshot in
            
            if let infoDict = snapshot.value as? Dictionary<String,AnyObject> {
                if let isConfirmed = infoDict["accept"] as? String {
                    if ( isConfirmed == "true") {
                        self.authenDict[userID] = true
                    }
                } else {
                    print("cannot set the isConfirmed value")
                }
                
            }
        })
        
        
    }
    
    
    func ShowAlert(title : String,msg:String,usrIDSrc: String){
        let alert = UIAlertController(title:title,message:msg,preferredStyle: .Alert)
        
        if  ( usrIDSrc == "" ) {
            let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
            alert.addAction(action)
        } else {
            
            let acceptAction = UIAlertAction(title: "Accept", style: .Default, handler: {
                (alert:UIAlertAction) in
                DataService.ds.REF_CONNECTIONS.childByAppendingPath(DataService.ds.CURRENT_USER_ID).childByAppendingPath(usrIDSrc).childByAppendingPath("accept").setValue("true")
                
            })
            let denyAction = UIAlertAction(title: "Deny", style: .Default, handler: {
                (alert:UIAlertAction) in
                DataService.ds.REF_CONNECTIONS.childByAppendingPath(DataService.ds.CURRENT_USER_ID).childByAppendingPath(usrIDSrc).childByAppendingPath("accept").setValue("false")
            })
            alert.addAction(acceptAction)
            alert.addAction(denyAction)
            
        }
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    
    
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        
        return  1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return users.count
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("userCell", forIndexPath: indexPath)
        let user = users[indexPath.row]
        cell.textLabel?.text = user.username
        
        return cell
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == SEGUE_SHOW_DETAILS {
            if let destination  = segue.destinationViewController as? LocationViewController {
                destination.userTarget = users[(tableView.indexPathForSelectedRow!.row)]
                destination.latitude = self.latitude
                destination.longitude = self.longitude
            }
            
        }
        
        if segue.identifier == SEGUE_LOGGED_OUT{
            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: false)
            DataService.ds.CURRENT_USER.unauth()
            NSUserDefaults.standardUserDefaults().setValue(nil, forKey: KEY_UID)
            DataService.ds.REF_BASE.removeAllObservers()
            for  connectionID in myConnectionsHistory {
                DataService.ds.REF_CONNECTIONS.childByAppendingPath(connectionID).removeValue()
            }
        }
        
    }
    
    
    
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showDetails" {
            let userTarget = users[(tableView.indexPathForSelectedRow!.row)]
            let userID = userTarget.userID
            isAuthorized = authenDict[userID]!
            
            
            // Today's date
            
            let todaysDate:NSDate = NSDate()
            let dateFormatter:NSDateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            let DateInFormat:String = dateFormatter.stringFromDate(todaysDate)
            
            // Set the request in Firebase connections node.
            let receiver: Dictionary<String,AnyObject> = ["date": DateInFormat,"accept":"false"]
            DataService.ds.REF_CONNECTIONS.childByAppendingPath(userTarget.userID).childByAppendingPath(DataService.ds.CURRENT_USER_ID).setValue(receiver)
            myConnectionsHistory.append("\(userTarget.userID)/\(DataService.ds.CURRENT_USER_ID)")
            if !isAuthorized {
                
                let alertController = UIAlertController(title: "Wait for destination response..", message: "You cannot perform this segue because access is not granted yet!", preferredStyle: .Alert)
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(defaultAction)
                presentViewController(alertController, animated: true, completion: nil)
                
                return false
            }
        }
        
        return true
    }
    
    
}


extension UserTableVC: CLLocationManagerDelegate  {
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0]
        if (DataService.ds.CURRENT_USER_ID != ""){
            
            DataService.ds.REF_USERS.childByAppendingPath(DataService.ds.CURRENT_USER_ID).childByAppendingPath("location/longitude").setValue(userLocation.coordinate.longitude)
            DataService.ds.REF_USERS.childByAppendingPath(DataService.ds.CURRENT_USER_ID).childByAppendingPath("location/latitude").setValue(userLocation.coordinate.latitude)
            latitude = userLocation.coordinate.latitude
            longitude = userLocation.coordinate.longitude
            
        }
        
    }
    
}