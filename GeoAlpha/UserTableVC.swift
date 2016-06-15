//
//  MyTableVC.swift
//  GeoAlpha
//
//  Created by Med Beji on 12/06/2016.
//  Copyright © 2016 alphalab. All rights reserved.
//

import UIKit
import Firebase

class UserTableVC: UITableViewController  {
    
    var users = [Client]()
    var authenDict = Dictionary<String,Bool>()
    var isAuthorized = false
    var usersConnectedWith = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        
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
                        
                        //Listening for responses!!
                        self.listeningForDemandsResponse(user.userID)
                        
                    }
                }
            }
            self.tableView.reloadData()
        })
        usersConnectedWith = []
        // Listening for demands !!
        self.listeningForDemands()
        
    }
    
    
    func listeningForDemands(){
        
        DataService.ds.REF_CONNECTIONS.childByAppendingPath(DataService.ds.CURRENT_USER_ID).observeEventType(.Value, withBlock: {
            snapshot in
            print("hello this is snapshot key \(snapshot.key)")
            print("hello this is snapshot key \(snapshot.value is NSNull)")
            if  !(snapshot.value is NSNull){
                let userDict = snapshot.value as? Dictionary<String,AnyObject>
                let userIDSource = Array(userDict!.keys)[0] as String
                // We can  get information about the user from Firebase here ...
                print("userIDSource = ", userIDSource)
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
                print("Action Accepted!")
                
                DataService.ds.REF_CONNECTIONS.childByAppendingPath(DataService.ds.CURRENT_USER_ID).childByAppendingPath(usrIDSrc).childByAppendingPath("accept").setValue("true")
                
            })
            let denyAction = UIAlertAction(title: "Deny", style: .Default, handler: {
                (alert:UIAlertAction) in
                print("Action denied!")
                
                DataService.ds.REF_CONNECTIONS.childByAppendingPath(DataService.ds.CURRENT_USER_ID).childByAppendingPath(usrIDSrc).childByAppendingPath("accept").setValue("false")
            })
            alert.addAction(acceptAction)
            alert.addAction(denyAction)
            
        }
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    // MARK: - Table view data source
    
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
        
        // Configure the cell...
        
        let user = users[indexPath.row]
        cell.textLabel?.text = user.username
        
        return cell
    }
    
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == SEGUE_SHOW_DETAILS {
            
            
            // Sucess , permission granted
            if let destination  = segue.destinationViewController as? LocationViewController {
                destination.userTarget = users[(tableView.indexPathForSelectedRow!.row)]
                print("Our Target Name is = \(destination.userTarget.username)")
                print("Location = \(destination.userTarget.location.latitude) |  \(destination.userTarget.location.longitude)")
                print("UserID = \(destination.userTarget.userID)")
            }
            
        }
        
        if segue.identifier == SEGUE_LOGGED_OUT{
            
            navigationController?.setNavigationBarHidden(navigationController?.navigationBarHidden == false, animated: false)
            DataService.ds.CURRENT_USER.unauth()
            NSUserDefaults.standardUserDefaults().setValue(nil, forKey: KEY_UID)
        }
        
    }
    
    
    
    
    
    override func shouldPerformSegueWithIdentifier(identifier: String, sender: AnyObject?) -> Bool {
        if identifier == "showDetails" {
            let userTarget = users[(tableView.indexPathForSelectedRow!.row)]
            let userID = userTarget.userID
            isAuthorized = authenDict[userID]!
            
            
            // Date for today 
            
            let todaysDate:NSDate = NSDate()
            let dateFormatter:NSDateFormatter = NSDateFormatter()
            dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
            let DateInFormat:String = dateFormatter.stringFromDate(todaysDate)
            
            // Set the request in Firebase connections node.
            let receiver: Dictionary<String,AnyObject> = ["\(DataService.ds.CURRENT_USER_ID)":["date": DateInFormat,"accept":"false"]]
            DataService.ds.REF_CONNECTIONS.childByAppendingPath(userTarget.userID).setValue(receiver)
            
            if !isAuthorized {
                
                let alertController = UIAlertController(title: "Sorry", message: "You cannot perform this segue because access is not granted yet!", preferredStyle: .Alert)
                
                let defaultAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
                alertController.addAction(defaultAction)
                
                presentViewController(alertController, animated: true, completion: nil)
                
                return false
            }
        }
        
        return true
    }
    
    
}
