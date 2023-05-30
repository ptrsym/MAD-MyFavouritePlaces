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

/// Saves the current context
///
/// This function allows data persistance using the CoreData functionality. It accesses the current working context and saves it.
func saveData() {
    let context = PersistenceHandler.shared.container.viewContext
    do {
        try context.save()
    } catch {
        fatalError("Error occured while saving: \(error)")
    }
}

/// class to handle interactions with the MapKit feature
///
/// The `MapViewModel` class represents a view model for managing map-related data and functionality.
/// It provides properties for storing and accessing information about a specific place, including its name, latitude, longitude, delta value, and region on the map.
/// Use the `MapViewModel` class to configure and update the map view in your application, and observe the published properties to respond to changes in the map data.

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
    /// A string represtation of the stored latitude value.
    ///
    /// This property provides a formatted string representing the latitude value of the location.
    /// It also validates the latitude value when set.
    ///
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

    /// string represtation of stored longitude double. also validates longitude
    ///
    /// This property provides a formatted string represting the longitude of the location.
    /// It also validates the longitude when set.
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
    
    /// Updates the model with attributes based on the associated place
    ///
    /// This method updates each model attribute with the corresponding values stored within the passed Place object
    /// so that map operations may reflect this place.
    ///
    /// - Parameter place: The 'Place' instance containing the attributes for the model to operate on
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
    
 
    /// Updates the place instance associated with the model.
    ///
    /// This method sets the attributes of the associated place to those stored in the model from the result of operations done on the map.
    /// It sets the values then saves the current context to persist changes.
    func updatePlace() {
        self.place?.longitude = self.region.center.longitude
        self.place?.latitude = self.region.center.latitude
        self.place?.name = self.name
        self.place?.delta = self.delta
        saveData()
    }
    

    /// Updates the stored latitude and longitude attributes with values based on the current region orientation of the map.
    func updateFromRegion(){
        self.longitude = region.center.longitude
        self.latitude = region.center.latitude
    }
    
    
    /// Sets the view region with an animation
    ///
    /// This method sets the region property specification to the currently stored latitude, longitude and delta values of the model
    /// It is called after changes have been made to the attributes but the map view has not been centered on them.
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
    // adds an empty new place entity to a fetched place collection
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




let delta = 10.0

class LocationManger: NSObject, CLLocationManagerDelegate, ObservableObject {
    
    @Published var region = MKCoordinateRegion()
    
    let manager = CLLocationManager()
    override init() {
        super.init()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
        region.span.longitudeDelta = delta
        region.span.latitudeDelta = delta
    }
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.last.map{
            region.center.latitude = $0.coordinate.latitude
            region.center.longitude = $0.coordinate.longitude
            print("lat: \($0.coordinate.latitude), long: \($0.coordinate.longitude)")
        }
    }
}






