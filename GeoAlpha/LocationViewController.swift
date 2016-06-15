//
//  LocationViewController.swift
//  GeoAlpha
//
//  Created by Med Beji on 12/06/2016.
//  Copyright © 2016 alphalab. All rights reserved.
//

import UIKit
import MapKit 
import Firebase

class LocationViewController: UIViewController, CLLocationManagerDelegate , MKMapViewDelegate{
    
    @IBOutlet  var map: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    var  userTarget  = Client()
    var locationManager: CLLocationManager!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var requestLocation = CLLocationCoordinate2DMake(0, 0)
    var seenError : Bool = false
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        requestLocation =  CLLocationCoordinate2DMake(userTarget.location.longitude, userTarget.location.latitude)
        distanceLabel.hidden = true
        seenError = false
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
        self.updateLocation()
        listeningEventForLocation()
        
    }
    
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func showDistance(sender: AnyObject) {
        
        distanceLabel.hidden =  false
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let location:CLLocationCoordinate2D = manager.location!.coordinate
        
        self.latitude = location.latitude
        self.longitude = location.longitude
        // Calcul distance
        requestLocation = CLLocationCoordinate2DMake(userTarget.location.latitude, userTarget.location.longitude)
        let requestCLLocation = CLLocation(latitude: requestLocation.latitude, longitude: requestLocation.longitude)
        let myCLLocation = CLLocation(latitude: location.latitude, longitude: location.longitude)
        let distance = myCLLocation.distanceFromLocation(requestCLLocation)
        let distanceDouble = Double(distance/1000)
        let roundedDistance = Double(round(distanceDouble * 10) / 10)
        distanceLabel.text = "\(roundedDistance) Km"
        
    }
    
    
    func updateLocation(){
        
        let region = MKCoordinateRegion(center: requestLocation, span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01))
        
        self.map.setRegion(region, animated: true)
        
        let objectAnnotation = MKPointAnnotation()
        objectAnnotation.coordinate = requestLocation
        objectAnnotation.title = userTarget.username
        self.map.addAnnotation(objectAnnotation)
        
    }
    
    
    func listeningEventForLocation(){
        
        DataService.ds.REF_USERS.childByAppendingPath(userTarget.userID).childByAppendingPath("location").observeEventType(.Value, withBlock: {
            snapshot in
            
            var userLocation = Location()
            print ("SNAP: \(snapshot)")
            if let userLoc = snapshot.value as? Dictionary<String,AnyObject> {
                userLocation = Location(dictionary: userLoc)
            }
            self.userTarget.location = userLocation
            self.updateLocation()
        })
        
        
    }
    
    
    
}
