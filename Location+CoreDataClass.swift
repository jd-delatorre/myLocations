//
//  Location+CoreDataClass.swift
//  MyLocations
//
//  Created by John DeLaTorre on 5/17/17.
//  Copyright © 2017 John DeLaTorre. All rights reserved.
//

import Foundation
import CoreData
import MapKit

@objc(Location)
public class Location: NSManagedObject, MKAnnotation {

    public var coordinate: CLLocationCoordinate2D{
        return CLLocationCoordinate2DMake(latitude, longitude)
    }
    
    public var title: String? {
        if locationDescription.isEmpty{
            return "(No Description)"
        }else{
            return locationDescription
        }
    }
    
    public var subtitle: String?{
        return category
    }
    
}



