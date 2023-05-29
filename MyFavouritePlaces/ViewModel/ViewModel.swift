//
//  ViewModel.swift
//  MyFavouritePlaces
//
//  Created by Peter on 28/5/2023.
//

import Foundation
import CoreData
import SwiftUI
import MapKit
import CoreLocation


var defaultImage = Image(systemName: "photo").resizable()
var downloadImage: [URL: Image] = [:]

func saveData() {
    let context = PersistenceHandler.shared.container.viewContext
    do {
        try context.save()
    } catch {
        fatalError("Error occured while saving: \(error)")
    }
}

class MapViewModel: ObservableObject {
    @Published var place: Place?
    @Published var name: String
    @Published var latitude: Double
    @Published var longitude: Double
    @Published var delta: Double
    @Published var region: MKCoordinateRegion
    init(place: Place? = nil){
        self.place = place
        self.name = ""
        self.latitude = 0.0
        self.longitude = 0.0
        self.delta = 100
        self.region = MKCoordinateRegion(center:
                                            CLLocationCoordinate2D(latitude: 0.0, longitude: 0.0), span:
                                            MKCoordinateSpan(latitudeDelta: 100, longitudeDelta: 100))
    }
    
    var regionLat:String {
        get{
            String(format: "%.5f", self.region.center.latitude)
        }
        set {
            if let doubleValue = Double(newValue), doubleValue >= -90.0, doubleValue <= 90.0 {
                self.latitude = doubleValue
            } else {
                print("Invalid longitude value \(newValue)")
            }
        }
    }
    
    var regionLong:String {
        get{
            String(format: "%.5f", self.region.center.longitude)
        }
        set {
            if let doubleValue = Double(newValue), doubleValue >= -180.0, doubleValue <= 180.0 {
                self.longitude = doubleValue
            } else {
                print("Invalid longitude value \(newValue)")
            }
        }
    }
    
    func updateModel(_ place: Place){
        self.place = place
        self.name = place.name ?? "no name"
        self.latitude = place.latitude
        self.longitude = place.longitude
        self.delta = place.delta
        self.region = MKCoordinateRegion(center:
                      CLLocationCoordinate2D(latitude: place.latitude, longitude: place.longitude), span:
                      MKCoordinateSpan(latitudeDelta: place.delta, longitudeDelta: place.delta))
    }
    
    func updatePlace() {
        self.place?.longitude = self.region.center.longitude
        self.place?.latitude = self.region.center.latitude
        self.place?.name = self.name
        self.place?.delta = self.delta
        saveData()
    }
    
    func checkAddress(){
        
    }
    
    func checkLocation(){
    }
}

extension Place {
    
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
    
extension Detail {
    var detailString:String {
        get {
            self.detail ?? "Add a description for your place"
        }
        set {
            self.detail = newValue
        }
    }
}

extension ContentView {
    func delPlace(index: IndexSet) {
        withAnimation {
            index.map{favouritePlaces[$0]}.forEach { place in
                context.delete(place)
            }
            saveData()
        }
    }
    func addPlace() {
        let newPlace = Place(context: context)
        newPlace.strName = "New Place"
        saveData()

    }
    
}
extension DetailView {
    func delDetail(index: IndexSet) {
        withAnimation {
            guard let detailsArray = Array(place.details ?? []) as? [Detail] else {
                return
            }
            index.forEach {i in
                if i < detailsArray.count {
                    let detail = detailsArray[i]
                    context.delete(detail)
                }
            }
            saveData()
        }
    }
}

