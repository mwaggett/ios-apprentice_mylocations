//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by Molly Waggett on 12/1/15.
//  Copyright © 2015 Molly Waggett. All rights reserved.
//

import UIKit
import CoreLocation
import CoreData

private let dateFormatter: NSDateFormatter = {
  let formatter = NSDateFormatter()
  formatter.dateStyle = .MediumStyle
  formatter.timeStyle = .ShortStyle
  return formatter
}()

class LocationDetailsViewController: UITableViewController {
  
  var observer: AnyObject!
  var managedObjectContext: NSManagedObjectContext!
  var locationToEdit: Location? {
    didSet {
      if let location = locationToEdit {
        descriptionText = location.locationDescription
        categoryName = location.category
        date = location.date
        coordinate = CLLocationCoordinate2DMake(
                                      location.latitude, location.longitude)
        placemark = location.placemark
      }
    }
  }
  var descriptionText = ""
  var categoryName = "No Category"
  var image: UIImage?
  var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
  var placemark: CLPlacemark?
  var date = NSDate()
  
  @IBOutlet weak var descriptionTextView: UITextView!
  @IBOutlet weak var categoryLabel: UILabel!
  @IBOutlet weak var addPhotoLabel: UILabel!
  @IBOutlet weak var imageView: UIImageView!
  @IBOutlet weak var latitudeLabel: UILabel!
  @IBOutlet weak var longitudeLabel: UILabel!
  @IBOutlet weak var addressLabel: UILabel!
  @IBOutlet weak var dateLabel: UILabel!
  
  deinit {
    print("*** deinit \(self)")
    NSNotificationCenter.defaultCenter().removeObserver(observer)
  }
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    if let location = locationToEdit {
      title = "Edit Location"
      if location.hasPhoto {
        if let image = location.photoImage {
          showImage(image)
        }
      }
    }
    
    descriptionTextView.text = descriptionText
    categoryLabel.text = categoryName
    latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
    longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
    if let placemark = placemark {
      addressLabel.text = stringFromPlacemark(placemark)
    } else {
      addressLabel.text = "No Address Found"
    }
    dateLabel.text = formatDate(date)
    
    let gestureRecognizer = UITapGestureRecognizer(target: self,
                                            action: Selector("hideKeyboard:"))
    gestureRecognizer.cancelsTouchesInView = false
    tableView.addGestureRecognizer(gestureRecognizer)
    
    listenForBackgroundNotification()
  }
  
  override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    if segue.identifier == "PickCategory" {
      let controller = segue.destinationViewController
                                              as! CategoryPickerViewController
      controller.selectedCategoryName = categoryName
    }
  }
  
  @IBAction func categoryPickerDidPickCategory(segue: UIStoryboardSegue) {
    let controller = segue.sourceViewController as! CategoryPickerViewController
    categoryName = controller.selectedCategoryName
    categoryLabel.text = categoryName
  }
  
  @IBAction func done() {
    let hudView = HudView.hudInView(navigationController!.view, animated: true)
    let location: Location
    if let temp = locationToEdit {
      hudView.text = "Updated"
      location = temp
    } else {
      hudView.text = "Tagged"
      location = NSEntityDescription.insertNewObjectForEntityForName(
          "Location", inManagedObjectContext: managedObjectContext) as! Location
      location.photoID = nil
    }
    
    location.locationDescription = descriptionTextView.text
    location.category = categoryName
    location.latitude = coordinate.latitude
    location.longitude = coordinate.longitude
    location.date = date
    location.placemark = placemark
    if let image = image {
      if !location.hasPhoto {
        location.photoID = Location.nextPhotoID()
      }
      if let data = UIImageJPEGRepresentation(image, 0.5) {
        do {
          try data.writeToFile(location.photoPath, options: .DataWritingAtomic)
        } catch {
          print("Error writing file: \(error)")
        }
      }
    }
    
    do {
      try managedObjectContext.save()
    } catch {
      fatalCoreDataError(error)
    }
    
    afterDelay(0.8) {
      self.dismissViewControllerAnimated(true, completion: nil)
    }
  }
  
  @IBAction func cancel() {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func showImage(image: UIImage) {
    imageView.image = image
    imageView.hidden = false
    imageView.frame = CGRect(x: 10, y: 10, width: 260,
                          height: 260 * (image.size.height / image.size.width))
    imageView.center = CGPointMake(imageView.superview!.bounds.size.width/2,
                                   imageView.superview!.bounds.size.height/2);
    addPhotoLabel.hidden = true
  }
  
  func stringFromPlacemark(placemark: CLPlacemark) -> String {
    var line = ""
    line.addText(placemark.subThoroughfare)
    line.addText(placemark.thoroughfare, withSeparator: " ")
    line.addText(placemark.locality, withSeparator: ", ")
    line.addText(placemark.administrativeArea, withSeparator: ", ")
    line.addText(placemark.postalCode, withSeparator: " ")
    line.addText(placemark.country, withSeparator: ", ")    
    return line
  }
  
  func formatDate(date: NSDate) -> String {
    return dateFormatter.stringFromDate(date)
  }
  
  func hideKeyboard(gestureRecoginizer: UIGestureRecognizer) {
    let point = gestureRecoginizer.locationInView(tableView)
    let indexPath = tableView.indexPathForRowAtPoint(point)
    if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0 {
      return
    }
    descriptionTextView.resignFirstResponder()
  }
  
  func listenForBackgroundNotification() {
    observer = NSNotificationCenter.defaultCenter().addObserverForName(
            UIApplicationDidEnterBackgroundNotification, object: nil,
            queue: NSOperationQueue.mainQueue()) { [weak self] _ in
      if let strongSelf = self {
        if strongSelf.presentedViewController != nil {
          strongSelf.dismissViewControllerAnimated(false, completion: nil)
        }
        strongSelf.descriptionTextView.resignFirstResponder()
      }
    }
  }
  
  // MARK: - UITableViewDelegate
  
  override func tableView(tableView: UITableView,
                    heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
    switch (indexPath.section, indexPath.row) {
      case (0, 0):
        return 88
        
      case (1, _):
        return imageView.hidden ? 44 : imageView.frame.height + 20
        
      case (2, 2):
        addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115,
          height: 10000)
        addressLabel.sizeToFit()
        addressLabel.frame.origin.x =
          view.bounds.size.width - addressLabel.frame.size.width - 15
        return addressLabel.frame.size.height + 20
        
      default:
        return 44
    }
  }
  
  override func tableView(tableView: UITableView,
              willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
    if indexPath.section == 0 || indexPath.section == 1 {
      return indexPath
    } else {
      return nil
    }
  }
  
  override func tableView(tableView: UITableView,
                              didSelectRowAtIndexPath indexPath: NSIndexPath) {
    if indexPath.section == 0 && indexPath.row == 0 {
      descriptionTextView.becomeFirstResponder()
    } else if indexPath.section == 1 && indexPath.row == 0 {
      tableView.deselectRowAtIndexPath(indexPath, animated: true)
      pickPhoto()
    }
  }
}

extension LocationDetailsViewController: UIImagePickerControllerDelegate,
                                          UINavigationControllerDelegate {
  
  func imagePickerController(picker: UIImagePickerController,
                didFinishPickingMediaWithInfo info: [String : AnyObject]) {
    image = info[UIImagePickerControllerEditedImage] as? UIImage
    if let image = image {
      showImage(image)
    }
    tableView.reloadData()
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func imagePickerControllerDidCancel(picker: UIImagePickerController) {
    dismissViewControllerAnimated(true, completion: nil)
  }
  
  func pickPhoto() {
    if UIImagePickerController.isSourceTypeAvailable(.Camera) {
      showPhotoMenu()
    } else {
      choosePhotoFromLibrary()
    }
  }
  
  func showPhotoMenu() {
    let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
    
    let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
    alertController.addAction(cancelAction)
    
    let takePhotoAction = UIAlertAction(title: "Take Photo", style: .Default, handler: { _ in self.takePhotoWithCamera() })
    alertController.addAction(takePhotoAction)
    
    let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library", style: .Default, handler: { _ in self.choosePhotoFromLibrary() })
    alertController.addAction(chooseFromLibraryAction)
    
    presentViewController(alertController, animated: true, completion: nil)
  }
  
  func choosePhotoFromLibrary() {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .PhotoLibrary
    imagePicker.delegate = self
    imagePicker.allowsEditing = true
    presentViewController(imagePicker, animated: true, completion: nil)
  }
  
  func takePhotoWithCamera() {
    let imagePicker = UIImagePickerController()
    imagePicker.sourceType = .Camera
    imagePicker.delegate = self
    imagePicker.allowsEditing = true
    presentViewController(imagePicker, animated: true, completion: nil)
  }
}
