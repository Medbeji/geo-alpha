//
//  LoginViewController.swift
//  GeoAlpha
//
//  Created by Med Beji on 10/06/2016.
//  Copyright © 2016 alphalab. All rights reserved.
//

import UIKit
import MapKit

class LoginViewController: UIViewController ,CLLocationManagerDelegate , MKMapViewDelegate , UITextFieldDelegate {
    
    
    @IBOutlet weak var emailTField: UITextField!
    @IBOutlet weak var passwordTField: UITextField!
    var locationManager: CLLocationManager!
    var longitude: Double = 0
    var latitude: Double = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.emailTField.delegate = self
        self.passwordTField.delegate = self
        locationSetting()
        
        
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    override func viewDidAppear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        //        let location : Dictionary<String,AnyObject>=["latitude":self.latitude,"longitude":self.longitude]
        //        print(location)
        //        DataService.ds.REF_USERS.childByAppendingPath(DataService.ds.CURRENT_USER.authData.uid).childByAppendingPath("location").setValue(location)
        
        if NSUserDefaults.standardUserDefaults().valueForKey(KEY_UID) != nil && DataService.ds.CURRENT_USER.authData != nil {
            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
        }
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    @IBAction func login(sender: AnyObject) {
        
        // CURRENT LOCATION !
        
        if  let email = self.emailTField.text where email != "" , let pwd = self.passwordTField.text where pwd != "" {
            firebaseLoginOrSignUp(email,pwd: pwd)
        } else {
            showErrerAlert("Email and Password Required", msg: "You must enter an email and a password")
        }
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
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let userLocation:CLLocation = locations[0] 
        self.longitude = userLocation.coordinate.longitude
        self.latitude = userLocation.coordinate.latitude
        //Do What ever you want with it
    }
    
    
    func firebaseLoginOrSignUp(email: String,pwd:String){
        
        DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: {
            error,authData in
            if error != nil {
                print(error.code)
                if  error.code == STATUS_ACCOUNT_NONEXITS {
                    // SignUP
                    
                    DataService.ds.REF_BASE.createUser(email, password: pwd, withValueCompletionBlock: {
                        error,result in
                        if error != nil {
                            self.showErrerAlert("Could not create account", msg: "Problem creating account. Try again please..")
                        } else {
                            
                            // Add the USER to USERS node in Firebase with Name by Default and Current location
                            let user: Dictionary<String,AnyObject> = [ "location" : ["latitude":self.latitude,"longitude":self.longitude],"name":email.substringToIndex((email.rangeOfString("@")?.startIndex)!),"password":pwd]
                            DataService.ds.REF_USERS.childByAppendingPath("\(result[KEY_UID]!)").setValue(user)
                            NSUserDefaults.standardUserDefaults().setValue(result[KEY_UID]!, forKey: KEY_UID)
                            DataService.ds.REF_BASE.authUser(email, password: pwd, withCompletionBlock: nil)
                            self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
                        }
                        
                    })
                }
            } else {
                // Login
                let location : Dictionary<String,AnyObject>=["latitude":self.latitude,"longitude":self.longitude]
                print(location)
                DataService.ds.REF_USERS.childByAppendingPath(authData.uid).childByAppendingPath("location").setValue(location)
                NSUserDefaults.standardUserDefaults().setValue(authData.uid, forKey: KEY_UID)
                self.performSegueWithIdentifier(SEGUE_LOGGED_IN, sender: nil)
            }
            
        })
        
    }
    
    
    func showErrerAlert(title : String,msg:String){
        let alert = UIAlertController(title:title,message:msg,preferredStyle: .Alert)
        let action = UIAlertAction(title: "OK", style: .Default, handler: nil)
        alert.addAction(action)
        presentViewController(alert, animated: true, completion: nil)
        
    }
    
}
