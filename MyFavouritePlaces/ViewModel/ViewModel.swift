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

//configured default image
var defaultImage = Image(systemName: "photo").resizable()
//dictionary to cache images once downloaded
var downloadImage: [URL: Image] = [:]

//saves contex to persist data
func saveData() {
    let context = PersistenceHandler.shared.container.viewContext
    do {
        try context.save()
    } catch {
        fatalError("Error occured while saving: \(error)")
    }
}

// class the handle interactions with the MapKit feature
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
    //string representation of stored latitude value. also validates latitude
    var latStr:String {
        get{
            String(format: "%.5f", self.latitude)
        }
        set {
            if let doubleValue = Double(newValue), doubleValue >= -90.0, doubleValue <= 90.0 {
                self.latitude = doubleValue
            } else {
                print("Invalid longitude value \(newValue)")
            }
        }
    }
    
    // string represtation of stored longitude double. also validates longitude
    var longStr:String {
        get{
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
    
    // function to link a place instance to an empty mapModel retrieved from environment
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
    
    //loads the mapModel configuration back into its associated place instance and saves context
    func updatePlace() {
        self.place?.longitude = self.region.center.longitude
        self.place?.latitude = self.region.center.latitude
        self.place?.name = self.name
        self.place?.delta = self.delta
        saveData()
    }
    
    //updates stored long/lat values based on current orientation
    func updateFromRegion(){
        self.longitude = region.center.longitude
        self.latitude = region.center.latitude
    }
    
    //pans the map to the region specified in stored mapmodel attributes with an animation
    func setRegion(){
        withAnimation{
            region.center.latitude = self.latitude
            region.center.longitude = self.longitude
            region.span.latitudeDelta = self.delta
            region.span.longitudeDelta = self.delta
        }
       }
    
    
    // function to retrieve map address location based on model stored coordinate attributes
    func fromLocToAddress() {
        let coder = CLGeocoder()
        coder.reverseGeocodeLocation(CLLocation(latitude: self.latitude,
            longitude: self.longitude)) {marks, error in
            if let err = error {
                print("error finding address from location: \(err)")
                return
            }
            let mark = marks?.first
            let name = mark?.name ?? mark?.country ?? mark?.locality ?? mark?.administrativeArea ?? "No name"
            self.name = name
        }
    }
    
    
    // escaping callback function interpretation of address lookup
    func fromAddressToLocOld(_ callback: @escaping () -> Void) {
        let encode = CLGeocoder()
        encode.geocodeAddressString(self.name) {marks, error in
            if let err = error {
                print("error finding location \(err)")
                return
            }
            if let mark = marks?.first {
                self.latitude = mark.location?.coordinate.latitude ?? self.latitude
                self.longitude = mark.location?.coordinate.longitude ?? self.longitude
                callback()
                self.setRegion()
            }
        }
    }
    
    //asynch interpretation of looking up location coords based on address
    func fromAddressToLoc() async {
        let encode = CLGeocoder()
        let marks = try? await encode.geocodeAddressString(self.name)
        
            if let mark = marks?.first {
                self.latitude = mark.location?.coordinate.latitude ?? self.latitude
                self.longitude = mark.location?.coordinate.longitude ?? self.longitude
                self.setRegion()
            }
        }
    
    // zoom function for map slider
    func zoomToDelta (_ zoom: Double) {
        let c1 = -10.0
        let c2 = 3.0
        self.delta = pow(10.0, zoom / c1 + c2)
    }

}

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
    
    //computed value to validate correct long entry
    //gets a string representation of stored double8
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
    
    //computed value to validate correct lat entry into attribute and retrieve
    // a string representation of stored double value
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
    // deletes a place entity from collection8
    func delPlace(index: IndexSet) {
        withAnimation {
            index.map{favouritePlaces[$0]}.forEach { place in
                context.delete(place)
            }
            saveData()
        }
    }
    // adds an empty new place entity to collection
    func addPlace() {
        let newPlace = Place(context: context)
        newPlace.strName = "New Place"
        saveData()

    }
    
}
extension DetailView {
    // deletes a detail relationship from a place
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

extension MapView {
    
    
    // callback function updating the local long/lat parameters from an address
    func checkAddress(){
        mapModel.fromAddressToLocOld(updateViewCoord)
//        Task{
//            await mapModel.fromAddressToLoc()
//            latitude = mapModel.latStr
//            longitude = mapModel.longStr
//        }
    }
    
    
    // retrieves the address name of the associated coordinates and centres the map
    func checkLocation(){
        mapModel.longStr = longitude
        mapModel.latStr = latitude
        mapModel.fromLocToAddress()
        mapModel.setRegion()
        
    }
    
    // updates map as the mapview zooms in and out and sets the region
    func checkZoom(){
        checkMap()
        mapModel.zoomToDelta(zoom)
        mapModel.fromLocToAddress()
        mapModel.setRegion()
    }
    
    // takes the current map view and assigns local coordinate parameters to
    // the current orientation then finds the address of coordinates
    func checkMap(){
        mapModel.updateFromRegion()
        latitude = mapModel.latStr
        longitude = mapModel.longStr
        mapModel.fromLocToAddress()
    }
    
    //sets local coords based on model configuration
    func updateViewCoord() {
        latitude = mapModel.latStr
        longitude = mapModel.longStr
    }
    
}
