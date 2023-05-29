//
//  DataModel.swift
//  MyFavouritePlaces
//
//  Created by Peter on 29/5/2023.
//

import Foundation
import MapKit
import CoreData

//extension Place {
//    @Published var region = MKCoordinateRegion(center: CLLocationCoordinate2D(
//        latitude: self.latitude, longitude: self.longitude), span:
//        MKCoordinateSpan(latitudeDelta: self.delta, longitudeDelta: self.delta))
//}










//class TestClass {
//    var latitude: Double
//    var longitude: Double
//
//    init(){
//        self.latitude = 0.0
//        self.longitude = 0.0
//    }
//
//    var strLongitude: String {
//        get {
//            String(format: "%.5f", self.longitude)
//        }
//        set {
//            if let doubleValue = Double(newValue), doubleValue >= -180.0, doubleValue <= 180.0 {
//                self.longitude = doubleValue
//            } else {
//                print("Invalid longitude value \(newValue)")
//            }
//        }
//    }
//    var strLatitude:String{
//        get{
//            String(format: "%.5f", self.latitude)
//        }
//        set {
//            if let doubleValue = Double(newValue), doubleValue >= -90.0, doubleValue <= 90.0 {
//                self.latitude = doubleValue
//            } else {
//                print("Invalid latitude value \(newValue)")
//                }
//            }
//        }
//
//}
