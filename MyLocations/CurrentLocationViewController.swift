//
//  FirstViewController.swift
//  MyLocations
//
//  Created by John DeLaTorre on 5/4/17.
//  Copyright © 2017 John DeLaTorre. All rights reserved.
//

import UIKit
import CoreLocation

class CurrentLocationViewController: UIViewController, CLLocationManagerDelegate {
    
    //instance outlet variables for Current Location View Controller
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var tagButton: UIButton!
    @IBOutlet weak var getButton: UIButton!
    
    let locationManager = CLLocationManager()
    
    var location: CLLocation?
    var updatingLocation = false
    var lastLocationError: Error?
    
    //for reverse geocoding
    let geocoder = CLGeocoder()
    var placemark: CLPlacemark?
    var performingReverseGeoding = false
    var lastGeocodingError: Error?
    
    //adding timer to stop app from running too long
    var timer: Timer?
    
    //Action to get current location
    @IBAction func getLocation(){
        //requesting permission to use user's location
        let authStatus = CLLocationManager.authorizationStatus()
        
        if authStatus == .notDetermined{
            locationManager.requestWhenInUseAuthorization()
            return
        }
        
        if authStatus == .denied || authStatus == .restricted{
            showLocationServicesDeniedAlert()
            return
        }
        
        //if currently updating location, then pressing the button is to stop
        if updatingLocation{
            stopLocationManager()
        }else{
            location = nil
            lastLocationError = nil
            placemark = nil
            lastGeocodingError = nil
            startLocationManager()
        }
        
        updateLabels()
        configureGetButton()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        updateLabels()
        configureGetButton()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    //location manager delegate
    //MARK: CLLocationManagerDelegate
    
    func locationManager(_ manager: CLLocationManager,
                         didFailWithError error:Error){
        print("didFailWithError\(error)")
        
        if(error as NSError).code == CLError.locationUnknown.rawValue{
            return
        }
        
        lastLocationError = error
        
        stopLocationManager()
        updateLabels()
        configureGetButton()
    }
    
    func locationManager(_ manager: CLLocationManager,
                         didUpdateLocations locations: [CLLocation]){
        let newLocation = locations.last!
        print("didUpdateLocations \(newLocation)")
        
        if newLocation.timestamp.timeIntervalSinceNow < -5{
            return
        }
        
        if newLocation.horizontalAccuracy < 0{
            return
        }
        
        var distance = CLLocationDistance(DBL_MAX)
        if let location = location{
            distance = newLocation.distance(from: location)
        }
        
        if location == nil || location!.horizontalAccuracy > newLocation.horizontalAccuracy{
            lastLocationError = nil
            location = newLocation
            updateLabels()
            
            if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy{
                print("*** We're done!")
                stopLocationManager()
                configureGetButton()
                
                if distance > 0{
                    performingReverseGeoding = false
                }
            }
            
            if !performingReverseGeoding{
                print("*** Going to geocode")
                
                performingReverseGeoding = true
                
                geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
                    placemarks, error in
                
                    print("*** Found plaemarks: \(placemarks), error: \(error)")
                    
                    self.lastGeocodingError = error
                    if error == nil, let p = placemarks, !p.isEmpty{
                        self.placemark = p.last!
                    }else{
                        self.placemark = nil
                    }
                    
                    self.performingReverseGeoding = false
                    self.updateLabels()
                })
            }else if distance < 1{
                let timeInterval = newLocation.timestamp.timeIntervalSince(location!.timestamp)
                
                if timeInterval > 10{
                    print("*** Force Done!")
                    stopLocationManager()
                    updateLabels()
                    configureGetButton()
                }
            }
        }
    }
    
    //to give user an alert
    func showLocationServicesDeniedAlert(){
        let alert = UIAlertController(title: "Location Services Disabled",
                                      message: "Please enable location services for this app in Settings.",
                                      preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .default,
                                     handler: nil)
        
        alert.addAction(okAction)
        
        present(alert, animated: true, completion: nil)
    }
    
    //adding the gps coordinates to the app labels
    func updateLabels(){
        if let location = location{
            latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
            longitudeLabel.text = String(format: "%.8f", location.coordinate.longitude)
            
            tagButton.isHidden = false
            messageLabel.text = ""
            
            //for the address label
            if let placemark = placemark{
                addressLabel.text = string(from: placemark)
            }else if performingReverseGeoding{
                addressLabel.text = "Searching for Address.."
            }else if lastGeocodingError != nil{
                addressLabel.text = "Error Finding Address"
            }else{
                addressLabel.text = "No Address Found"
            }
            
        }else{
            latitudeLabel.text = ""
            longitudeLabel.text = ""
            addressLabel.text = ""
            tagButton.isHidden = true
            
            let statusMessage: String
            if let error = lastLocationError as? NSError{
                if error.domain == kCLErrorDomain && error.code == CLError.denied.rawValue{
                    statusMessage = "Location Services Disabled"
                }else{
                    statusMessage = "Error Getting Location"
                }
            }else if !CLLocationManager.locationServicesEnabled(){
                statusMessage = "Location Services Disabled"
            }else if updatingLocation{
                statusMessage = "Searching..."
            }else {
                statusMessage = "Tap 'Get My Location' to Start"
            }
            
            messageLabel.text = statusMessage
            
        }
    }
    
    func startLocationManager(){
        if CLLocationManager.locationServicesEnabled(){
            locationManager.delegate = self
            locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager.startUpdatingLocation()
            updatingLocation = true
            
            timer = Timer.scheduledTimer(timeInterval: 60,
                                         target: self,
                                         selector: #selector(didTimeOut),
                                         userInfo: nil,
                                         repeats: false)
        }
    }
    
    //in case of error, adding function to stop location manager
    func stopLocationManager(){
        if updatingLocation{
            locationManager.stopUpdatingLocation()
            locationManager.delegate = nil
            updatingLocation = false
            if let timer = timer{
                timer.invalidate()
            }
        }
    }
    
    func configureGetButton(){
        if updatingLocation{
            getButton.setTitle("Stop", for: .normal)
        }else{
            getButton.setTitle("Get My Location", for: .normal)
        }
    }
    
    func string(from plaemark: CLPlacemark) -> String{
        var line1 = ""
        
        if let s = placemark?.subThoroughfare{
            line1 += s + " "
        }
        
        if let s = placemark?.thoroughfare{
            line1 += s
        }
        
        var line2 = ""
        
        if let s = placemark?.locality{
            line2 += s + " "
        }
        
        if let s = placemark?.administrativeArea{
            line2 += s + " "
        }
        
        if let s = placemark?.postalCode{
            line2 += s
        }
        
        return line1 + "\n" + line2
    }
    
    //for the timer
    func didTimeOut(){
        print("*** Time out")
        
        if location == nil{
            stopLocationManager()
            
            lastLocationError = NSError(domain:"MyLocationsErrorDomain",
                                        code: 1, userInfo: nil)
            
            updateLabels()
            configureGetButton()
        }
    }
    
    //when seguing to LocationDetailsViewController
    override func prepare(for segue: UIStoryboardSegue, sender: Any?){
        if segue.identifier == "TagLocation"{
            let navigationController = segue.destination as! UINavigationController
            let controller = navigationController.topViewController as! LocationDetailsViewController
            
            controller.coordinate = location!.coordinate
            controller.placemark = placemark
        }
    }

}






























