//
//  FirstViewController.swift
//  MyLocations
//
//  Created by Molly Waggett on 11/30/15.
//  Copyright © 2015 Molly Waggett. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

class CurrentLocationViewController: UIViewController,
                                              CLLocationManagerDelegate {
  
  var managedObjectContext: NSManagedObjectContext!
  
  let locationManager = CLLocationManager()
  var location: CLLocation?
  var updatingLocation = false
  var lastLocationError: NSError?
  
  let geocoder = CLGeocoder()
  var placemark: CLPlacemark?
  var performingReverseGeocoding = false
  var lastGeocodingError: NSError?
  
  var timer: NSTimer?
  
  @IBOutlet weak var messageLabel: UILabel!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var tagButton: UIButton!
  @IBOutlet weak var getButton: UIButton!

  override func viewDidLoad() {
    super.viewDidLoad()
    updateLabels()
    configureGetButton()
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "TagLocation" {
      let navigationController = segue.destinationViewController
                                              as! UINavigationController
      let controller = navigationController.topViewController
                                              as! LocationDetailsViewController
      controller.coordinate = location!.coordinate
      controller.placemark = placemark
      controller.managedObjectContext = managedObjectContext
    }
  }

  @IBAction func getLocation() {
    let authStatus = CLLocationManager.authorizationStatus()
    if authStatus == .NotDetermined {
      locationManager.requestWhenInUseAuthorization()
      return
    }
    if authStatus == .Denied || authStatus == .Restricted {
      showLocationServicesDeniedAlert()
      return
    }
    if updatingLocation {
      stopLocationManager()
    } else {
      location = nil
      lastLocationError = nil
      placemark = nil
      lastGeocodingError = nil
      startLocationManager()
    }
    updateLabels()
    configureGetButton()
  }
  
  func showLocationServicesDeniedAlert() {
    let alert = UIAlertController(title: "Location Services Disabled",
          message: "Please enable location services for this app in Settings.",
          preferredStyle: .Alert)
    let okAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
    alert.addAction(okAction)
    presentViewController(alert, animated: true, completion: nil)
  }
  
  func startLocationManager() {
    if CLLocationManager.locationServicesEnabled() {
      locationManager.delegate = self
      locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
      locationManager.startUpdatingLocation()
      updatingLocation = true
      timer = NSTimer.scheduledTimerWithTimeInterval(60, target: self,
                selector: Selector("didTimeOut"), userInfo: nil, repeats: false)
    }
  }
  
  func stopLocationManager() {
    if updatingLocation {
      if let timer = timer {
        timer.invalidate()
      }
      locationManager.stopUpdatingLocation()
      locationManager.delegate = nil
      updatingLocation = false
    }
  }
  
  func didTimeOut() {
    print("*** Time out")
    
    if location == nil {
      stopLocationManager()
      lastLocationError = NSError(domain: "MyLocationsErrorDomain", code: 1,
                                  userInfo: nil)
      updateLabels()
      configureGetButton()
    }
  }
  
  func updateLabels() {
    if let location = location {
      latitudeLabel.text = String(format: "%.8f", location.coordinate.latitude)
      longitudeLabel.text = String(format: "%.8f",
                                    location.coordinate.longitude)
      tagButton.hidden = false
      messageLabel.text = ""
      if let placemark = placemark {
        addressLabel.text = stringFromPlacemark(placemark)
      } else if performingReverseGeocoding {
        addressLabel.text = "Searching for Address..."
      } else if lastGeocodingError != nil {
        addressLabel.text = "Error Finding Address"
      } else {
        addressLabel.text = "No Address Found"
      }
    } else {
      latitudeLabel.text = ""
      longitudeLabel.text = ""
      addressLabel.text = ""
      tagButton.hidden = true
      
      let statusMessage: String
      if let error = lastLocationError {
        if error.domain == kCLErrorDomain
                  && error.code == CLError.Denied.rawValue {
          statusMessage = "Location Services Disabled"
        } else {
          statusMessage = "Error Getting Location"
        }
      } else if !CLLocationManager.locationServicesEnabled() {
        statusMessage = "Location Services Disabled"
      } else if updatingLocation {
        statusMessage = "Searching..."
      } else {
        statusMessage = "Tap 'Get My Location' to Start"
      }
      messageLabel.text = statusMessage
    }
  }
  
  func configureGetButton() {
    if updatingLocation {
      getButton.setTitle("Stop", forState: .Normal)
    } else {
      getButton.setTitle("Get My Location", forState: .Normal)
    }
  }
  
  func stringFromPlacemark(placemark: CLPlacemark) -> String {
    var line1 = ""
    line1.addText(placemark.subThoroughfare)
    line1.addText(placemark.thoroughfare, withSeparator: " ")
    
    var line2 = ""
    line2.addText(placemark.locality)
    line2.addText(placemark.administrativeArea, withSeparator: ", ")
    line2.addText(placemark.postalCode, withSeparator: " ")
    
    line1.addText(line2, withSeparator: "\n")
    
    return line1
  }
  
  // MARK: - CLLocationManagerDelegate
  
  func locationManager(manager: CLLocationManager,
                        didFailWithError error: NSError) {
    if error.code == CLError.LocationUnknown.rawValue {
      return
    }
    lastLocationError = error
    stopLocationManager()
    updateLabels()
    configureGetButton()
    print("didFailWithError \(error)")
  }
  
  func locationManager(manager: CLLocationManager,
                        didUpdateLocations locations: [CLLocation]) {
    let newLocation = locations.last!
    print("didUpdateLocations \(newLocation)")
    
    if newLocation.timestamp.timeIntervalSinceNow < -5 {
      return
    }
                          
    if newLocation.horizontalAccuracy < 0 {
      return
    }
                          
    var distance = CLLocationDistance(DBL_MAX)
    if let location = location {
      distance = newLocation.distanceFromLocation(location)
    }
                          
    if location == nil
            || location!.horizontalAccuracy > newLocation.horizontalAccuracy {
      lastLocationError = nil
      location = newLocation
      updateLabels()
      
      if newLocation.horizontalAccuracy <= locationManager.desiredAccuracy {
        print("*** We're done!")
        stopLocationManager()
        configureGetButton()
        
        if distance > 0 {
          performingReverseGeocoding = false
        }
      }
      
      if !performingReverseGeocoding {
        print("*** Going to geocode")
        performingReverseGeocoding = true
        geocoder.reverseGeocodeLocation(newLocation, completionHandler: {
          placemarks, error in
            print("*** Found placemarks: \(placemarks), error: \(error)")
            self.lastGeocodingError = error
            if error == nil, let p = placemarks where !p.isEmpty {
              self.placemark = p.last!
            } else {
              self.placemark = nil
            }
            self.performingReverseGeocoding = false
            self.updateLabels()
        })
      }
    } else if distance < 1.0 {
      let timeInterval =
              newLocation.timestamp.timeIntervalSinceDate(location!.timestamp)
      if timeInterval > 10 {
        print("*** Force done!")
        stopLocationManager()
        updateLabels()
        configureGetButton()
      }
    }
  }

}

