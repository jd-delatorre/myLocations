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
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var addPhotoLabel: UILabel!
    
    //instance variables
    var coordinate = CLLocationCoordinate2D(latitude: 0, longitude: 0)
    var placemark: CLPlacemark?
    var categoryName = "No Category"
    var managedObjectContext: NSManagedObjectContext!
    var date = Date()
    var locationToEdit: Location?{
        didSet{
            if let location = locationToEdit{
                descriptionText = location.locationDescription
                categoryName = location.category
                date = location.date
                coordinate = CLLocationCoordinate2DMake(location.latitude, location.longitude)
                placemark = location.placemark
            }
        }
    }
    var descriptionText = ""
    var image: UIImage?
    var observer: Any!
    
    @IBAction func done(){
        let hudView = HudView.hud(inView: navigationController!.view,
                                  animated: true)
        
        let location: Location
        if let temp = locationToEdit{
            hudView.text = "Updated"
            location = temp
        }else{
            hudView.text = "Tagged"
            location = Location(context: managedObjectContext)
        }
        
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
        
        if let location = locationToEdit{
            title = "Edit Location"
        }
        
        descriptionTextView.text = descriptionText
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
        
        //listening for app to go to background
        listenForBackgroundNotification()
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
        switch(indexPath.section, indexPath.row){
        case(0, 0):
            return 88
        case(1, _):
            //ternary conditional operator, SPACE IS NECESSARY BETWEEN '?' AND ISHIDDEN
            return imageView.isHidden ? 44 : 280
        case(2, 2):
            addressLabel.frame.size = CGSize(width: view.bounds.size.width - 115,
                                             height: 10000)
            addressLabel.sizeToFit()
            addressLabel.frame.origin.x = view.bounds.size.width - addressLabel.frame.size.width - 15
            return addressLabel.frame.size.height + 20
            
        default:
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
        }else if indexPath.section == 1 && indexPath.row == 0{
            tableView.deselectRow(at: indexPath, animated: true)
            pickPhoto()
        }
    }
    
    func show(image: UIImage){
        imageView.image = image
        imageView.isHidden = false
        imageView.frame = CGRect(x: 10, y: 10, width: 260, height: 260)
        addPhotoLabel.isHidden = true
    }
    
    //when app is going to background, dismiss action sheet and image picker
    func listenForBackgroundNotification(){
        observer = NotificationCenter.default.addObserver(
            forName: Notification.Name.UIApplicationDidEnterBackground,
            object: nil, queue: OperationQueue.main
        ){
            //closure will only run if notification is received
            [weak self] _ in
            if let strongSelf = self{
                if strongSelf.presentedViewController != nil{
                    strongSelf.dismiss(animated: false, completion: nil)
                }
                
                strongSelf.descriptionTextView.resignFirstResponder()
            }
        }
    }
    
    deinit{
        print("**** deinit \(self)")
        NotificationCenter.default.removeObserver(observer)
    }
    
}
//MARK: Extensions
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
///////////////////////////////////////////////////////////////////////////////////////////////
extension LocationDetailsViewController: UIImagePickerControllerDelegate,
    UINavigationControllerDelegate{
    
    func takePhotoWithCamera(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .camera
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String: Any]){
        image = info[UIImagePickerControllerEditedImage] as? UIImage
        
        if let theImage = image{
            show(image: theImage)
        }
        
        tableView.reloadData()  //refreshing table view
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func choosePhotoFromLibrary(){
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        present(imagePicker, animated: true, completion: nil)
    }
    
    //checking if camera present, if it is, then give user option of using camera or photo library
    func pickPhoto(){
        if UIImagePickerController.isSourceTypeAvailable(.camera){
            showPhotoMenu()
        }else{
            choosePhotoFromLibrary()
        }
    }
    
    func showPhotoMenu(){
        let alertController = UIAlertController(title: nil,
                                                message: nil,
                                                preferredStyle: .actionSheet)
        
        let cancelAction = UIAlertAction(title: "Cancel",
                                         style: .cancel,
                                         handler: nil)
        
        alertController.addAction(cancelAction)
        
        let takePhotoAction = UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { _ in self.takePhotoWithCamera() })
        
        alertController.addAction(takePhotoAction)
        
        let chooseFromLibraryAction = UIAlertAction(title: "Choose From Library",
                                                    style: .default,
                                                    handler: { _ in self.choosePhotoFromLibrary() })
        
        alertController.addAction(chooseFromLibraryAction)
        
        present(alertController, animated: true, completion: nil)
    }
}



















































