//
//  LocationDetailsViewController.swift
//  MyLocations
//
//  Created by John DeLaTorre on 5/10/17.
//  Copyright © 2017 John DeLaTorre. All rights reserved.
//

import Foundation
import UIKit
import CoreLocation
import CoreData

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    print("running formatter")
    return formatter
}()

class LocationDetailsViewController: UITableViewController{
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var categoryLabel: UILabel!
    @IBOutlet weak var latitudeLabel: UILabel!
    @IBOutlet weak var longitudeLabel: UILabel!
    @IBOutlet weak var addressLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    
    //instance variables
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var date = Date()
    
    @IBAction func done(){
        let hudView = HudView.hud(inView: navigationController!.view,
                                  animated: true)
        
        hudView.text = "Tagged"
        
        let location = Location(context: managedObjectContext)
        
        location.locationDescription = descriptionTextView.text
        location.category = categoryName
        location.latitude = coordinate.latitude
        location.longitude = coordinate.longitude
        location.date = date
        location.placemark = placemark
        
        do{
            try managedObjectContext.save()
            
            afterDelay(0.6){
                self.dismiss(animated: true, completion: nil)
            }
        }catch{
            fatalCoreDataError(error)
        }
    }
    
    @IBAction func cancel(){
        dismiss(animated: true, completion: nil)
    }
    
    //for the unwind segue
    @IBAction func categoryPickerDidPickCategory(_ segue: UIStoryboardSegue){
        let controller = segue.source as! CategoryPickerViewController
        categoryName = controller.selectedCategoryName
        categoryLabel.text = categoryName
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        descriptionTextView.text = ""
        categoryLabel.text = categoryName
        
        latitudeLabel.text = String(format: "%.8f", coordinate.latitude)
        longitudeLabel.text = String(format: "%.8f", coordinate.longitude)
        
        if let placemark = placemark{
            addressLabel.text = string(from: placemark)
        }else{
            addressLabel.text = "No Address Found"
        }
        
        dateLabel.text = format(date: date)
        
        //making keyboard disappear if user taps anywhere else on screen
        let gestureRecognizer = UITapGestureRecognizer(target: self,
                                                       action: #selector(hideKeyboard))
        gestureRecognizer.cancelsTouchesInView = false
        tableView.addGestureRecognizer(gestureRecognizer)
    }
    
    func string(from placemark: CLPlacemark) -> String{
        var text = ""
        
        if let s = placemark.subThoroughfare{
            text += s + " "
        }
        
        if let s = placemark.thoroughfare{
            text += s + ", "
        }
        
        if let s = placemark.locality{
            text += s + ", "
        }
        
        if let s = placemark.administrativeArea{
            text += s + " "
        }
        
        if let s = placemark.postalCode{
            text += s + ", "
        }
        
        if let s = placemark.country{
            text += s
        }
        
        return text
    }
    
    func format(date: Date) -> String{
        return dateFormatter.string(from: date)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "PickCategory"{
            let controller = segue.destination as! CategoryPickerViewController
            controller.selectedCategoryName = categoryName
        }
    }
    
    func hideKeyboard(_ gestureRecognizer: UIGestureRecognizer){
        let point = gestureRecognizer.location(in: tableView)
        let indexPath = tableView.indexPathForRow(at: point)
        
        if indexPath != nil && indexPath!.section == 0 && indexPath!.row == 0{
            return
        }
        
        descriptionTextView.resignFirstResponder()
    }
    
    //MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView,
                            heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0 && indexPath.row == 0{
            return 88
        }else if indexPath.section == 2 && indexPath.row == 2{
            addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115,
                                             height: 10000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            return addressLabel.frame.size.height + 20
        }else{
            return 44
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            willSelectRowAt indexPath: IndexPath) -> IndexPath? {
        if indexPath.section == 0 || indexPath.section == 1{
            return indexPath
        }else{
            return nil
        }
    }
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath) {
        if indexPath.section == 0 && indexPath.row == 0{
            descriptionTextView.becomeFirstResponder()
        }
    }
    
    
}



















































