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
import CoreLocation

class LocationViewController: UIViewController {
    
    @IBOutlet  var map: MKMapView!
    @IBOutlet weak var distanceLabel: UILabel!
    var  userTarget  = Client()
    var locationManager: CLLocationManager!
    var latitude: CLLocationDegrees = 0
    var longitude: CLLocationDegrees = 0
    var requestLocation = CLLocationCoordinate2DMake(0, 0)
    var seenError : Bool = false
    var activityIndicator: UIActivityIndicatorView?
    
    @IBOutlet weak var totalTimeLabel: UILabel!
    
    var locationArray: [(textField: String!, mapItem: MKMapItem?)]!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.map.delegate = self
        locationArray = [("CURRENT_LOCATION",nil),("DESTINATION_LOCATION",nil)]
        self.requestLocation =  CLLocationCoordinate2DMake(userTarget.location.latitude,userTarget.location.longitude)
        self.getuserTargetLocationPlacemark(userTarget.location.latitude,longitude: userTarget.location.longitude)
        distanceLabel.hidden = true
        seenError = false
        self.locationSetting()
        self.updateLocation()
        listeningEventForLocation()
        
    }
    
    func locationSetting(){
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation()
        
    }
    
    
    
    @IBAction func showDistance(sender: AnyObject) {
        distanceLabel.hidden =  false
    }
    
    
    func formatAddressFromPlacemark(placemark: CLPlacemark) -> String {
        return (placemark.addressDictionary!["FormattedAddressLines"] as! [String]).joinWithSeparator(", ")
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
            if let userLoc = snapshot.value as? Dictionary<String,AnyObject> {
                userLocation = Location(dictionary: userLoc)
            }
            
            self.getuserTargetLocationPlacemark(userLocation.latitude,longitude: userLocation.longitude)
            self.userTarget.location = userLocation
            self.updateLocation()
        })
        
        
    }
    
    func getuserTargetLocationPlacemark(latitude: Double,longitude: Double) {
        let coordinates = CLLocation(latitude: latitude, longitude: longitude)
        CLGeocoder().reverseGeocodeLocation(coordinates,
                                            completionHandler: {(placemarks:[CLPlacemark]?, error:NSError?) -> Void in
                                                if let placemarks = placemarks {
                                                    let placemark = placemarks[0]
                                                    self.locationArray[1].mapItem = MKMapItem(placemark:
                                                        MKPlacemark(coordinate: placemark.location!.coordinate,
                                                            addressDictionary: placemark.addressDictionary as! [String:AnyObject]?))
                                                    print("Target all adresses Dictionary = \(placemark.addressDictionary)")
                                                    print("destination location = \(self.formatAddressFromPlacemark(placemark))")
                                                }
        })
        
    }
    
    
    @IBAction func ShowRoute(sender: AnyObject) {
        self.addActivityIndicator()
        self.calculateSegmentDirections(0, time: 0, routes: [])
        
    }
    
    func addActivityIndicator() {
        activityIndicator = UIActivityIndicatorView(frame: UIScreen.mainScreen().bounds)
        activityIndicator?.activityIndicatorViewStyle = .WhiteLarge
        activityIndicator?.backgroundColor = UIColor.darkGrayColor()
        activityIndicator?.startAnimating()
        view.addSubview(activityIndicator!)
    }
    
    func hideActivityIndicator() {
        if activityIndicator != nil {
            activityIndicator?.removeFromSuperview()
            activityIndicator = nil
        }
    }
    
    func calculateSegmentDirections(index: Int,
                                    time: NSTimeInterval, routes: [MKRoute]) {
        
        let request: MKDirectionsRequest = MKDirectionsRequest()
        request.source = locationArray[0].mapItem
        request.destination = locationArray[1].mapItem
        request.requestsAlternateRoutes = true
        //request.transportType = .Any
        
        let directions = MKDirections(request: request)
        directions.calculateDirectionsWithCompletionHandler ({
            (response: MKDirectionsResponse?, error: NSError?) in
            if ( error != nil ) {
                print("direction error = \(error)")
            }else {
                if let routeResponse = response?.routes {
                    let quickestRouteForSegment: MKRoute =
                        routeResponse.sort({$0.expectedTravelTime <
                            $1.expectedTravelTime})[0]
                    
                    var timeVar = time
                    var routesVar = routes
                    
                    routesVar.append(quickestRouteForSegment)
                    timeVar += quickestRouteForSegment.expectedTravelTime
                    
                    if index+2 < self.locationArray.count {
                        print("Calculating routes")
                        self.calculateSegmentDirections(index+1, time: timeVar, routes: routesVar)
                    } else {
                        print("Showing the routes")
                        self.showMeTheRoute(routesVar, time: timeVar)
                        self.hideActivityIndicator()
                    }
                } else if let _ = error {
                    let alert = UIAlertController(title: nil,
                        message: "Directions not available.", preferredStyle: .Alert)
                    let okButton = UIAlertAction(title: "OK",
                    style: .Cancel) { (alert) -> Void in
                        self.navigationController?.popViewControllerAnimated(true)
                    }
                    alert.addAction(okButton)
                    self.presentViewController(alert, animated: true,
                        completion: nil)
                }
            }
        })
    }
    
    
    
    func showMeTheRoute(routes: [MKRoute], time: NSTimeInterval) {
        for i in 0..<routes.count {
            plotPolyline(routes[i])
        }
        printTimeToLabel(time)
    }
    func printTimeToLabel(time: NSTimeInterval) {
        
        let timeString = self.calculateTime(time)
        totalTimeLabel.text = "Total Time: \(timeString)"
    }
    
    func calculateTime(time: NSTimeInterval) -> String{
        let hours = Int(time) / 3600
        let minutes = Int(time) / 60 % 60
        let seconds = Int(time) % 60
        return String(format:"%02i:%02i:%02i", hours, minutes, seconds)
    }
    
    func plotPolyline(route: MKRoute) {
        map.addOverlay(route.polyline)
        if map.overlays.count == 1 {
            map.setVisibleMapRect(route.polyline.boundingMapRect,
                                  edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                                  animated: true)
        } else {
            let polylineBoundingRect =  MKMapRectUnion(map.visibleMapRect,
                                                       route.polyline.boundingMapRect)
            map.setVisibleMapRect(polylineBoundingRect,
                                  edgePadding: UIEdgeInsetsMake(10.0, 10.0, 10.0, 10.0),
                                  animated: true)
        }
    }
    
    
    
    
}



extension LocationViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView,
                 rendererForOverlay overlay: MKOverlay) -> MKOverlayRenderer {
        let polylineRenderer = MKPolylineRenderer(overlay: overlay)
        if (overlay is MKPolyline) {
            if mapView.overlays.count == 1 {
                polylineRenderer.strokeColor =
                    UIColor.blueColor().colorWithAlphaComponent(0.75)
            } else if mapView.overlays.count == 2 {
                polylineRenderer.strokeColor =
                    UIColor.greenColor().colorWithAlphaComponent(0.75)
            } else if mapView.overlays.count == 3 {
                polylineRenderer.strokeColor =
                    UIColor.redColor().colorWithAlphaComponent(0.75)
            }
            polylineRenderer.lineWidth = 5
        }
        return polylineRenderer
    }
    
    
}



extension LocationViewController: CLLocationManagerDelegate {
    
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location:CLLocationCoordinate2D = manager.location!.coordinate
        CLGeocoder().reverseGeocodeLocation(locations.last!,
                                            completionHandler: {(placemarks:[CLPlacemark]?, error:NSError?) -> Void in
                                                if let placemarks = placemarks {
                                                    let placemark = placemarks[0]
                                                    self.locationArray[0].mapItem = MKMapItem(placemark:
                                                        MKPlacemark(coordinate: placemark.location!.coordinate,
                                                            addressDictionary: placemark.addressDictionary as! [String:AnyObject]?))
                                                    print("Source all adresses Dictionary = \(placemark.addressDictionary)")
                                                    print(self.formatAddressFromPlacemark(placemark))
                                                }
        })
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
        
        let objectAnnotation1 = MKPointAnnotation()
        objectAnnotation1.coordinate = CLLocationCoordinate2DMake(self.latitude,self.longitude)
        objectAnnotation1.title = "My Location"
        self.map.addAnnotation(objectAnnotation1)
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
        print("There are an error")
        print(error)
    }
    
}
