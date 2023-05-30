//
//  DataModel.swift
//  MyFavouritePlaces
//
//  Created by Peter on 31/5/2023.
//

import Foundation
import SwiftUI
import CoreLocation
import MapKit
import CoreData


extension Place {
    
    // function to generate a thumbnail image based on current map orientation
    func generateThumbnailImage() async -> UIImage?{
        
        // create options instances and configure to current place setting
        let options = MKMapSnapshotter.Options()
        options.region = MKCoordinateRegion(center: CLLocationCoordinate2D(latitude:
                         self.latitude, longitude: self.longitude), span: MKCoordinateSpan(
                         latitudeDelta: 0.1, longitudeDelta: 0.1))
        options.mapType = .standard
        options.size = CGSize(width: 30, height: 30)
        
        do{
            // load options and take snapshot asynchronously
            let snapshot = try await MKMapSnapshotter(options: options).start()
            return snapshot.image
        } catch {
            print("Error creating map snapshot: \(error)")
            return nil
        }
    }
    // adds a new detail to the place relationship from the context
    func addDetail(_ description:String) {
        let context = PersistenceHandler.shared.container.viewContext
        let newDetail = Detail(context: context)
        newDetail.detail = description
        newDetail.place = self
        saveData()
    }
    
    // attempt to retrieve an image from a dictionary of cached images if it exists, if not download the image located
    // at the stored url attribute and add it to the downloadImage dictioanry. if no URl is stored or an error occurs
    // return a default image
    
    func getImage() async -> Image {
        guard let url = self.imgurl else {return defaultImage}
        if let image = downloadImage[url] {return image}
            do{
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let uiimg = UIImage(data: data) else {return defaultImage}
                let image = Image(uiImage: uiimg).resizable()
                downloadImage[url]=image
                return image
            }catch {
                print("error in downloading image \(error)")
            }
        
        return defaultImage
    }
        // validates delta value and adds string retrieval
        var strDelta:String {
            get {
                String(self.delta)
            }
            set {
                if let doubleValue = Double(newValue){
                    self.delta = doubleValue
                } else {
                    print("Invalid delta value \(newValue)")
                }
            }
        }
    
    var strName:String {
        get {
            self.name ?? "no name"
        }
        set {
            self.name = newValue
        }
    }
    
    //computed value to validate correct longitude entry
    //gets a string representation of stored double
    var strLongitude: String {
        get {
            String(format: "%.5f", self.longitude)
        }
        set {
            if let doubleValue = Double(newValue), doubleValue >= -180.0, doubleValue <= 180.0 {
                self.longitude = doubleValue
            } else {
                print("Invalid longitude value \(newValue)")
            }
        }
    }
    
    //computed value to validate correct latitude entry
    // gets a string representation of stored double value
    var strLatitude:String{
        get{
            String(format: "%.5f", self.latitude)
        }
        set {
            if let doubleValue = Double(newValue), doubleValue >= -90.0, doubleValue <= 90.0 {
                self.latitude = doubleValue
            } else {
                print("Invalid latitude value \(newValue)")
                }
            }
        }
    //computed value to fetch a string url from image or set url from string
    var strUrl: String {
        get {
            self.imgurl?.absoluteString ?? ""
        }
        set {
            guard let url = URL(string: newValue) else {return}
            self.imgurl = url
            }
        }
}


// let urlStr = "https://api.sunrisesunset.io/json?lat=\(latitude)&lng=\(longitude)&timezone=UTC"
