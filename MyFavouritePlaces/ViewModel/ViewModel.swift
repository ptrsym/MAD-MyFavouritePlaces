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
    
    var timeZoneStr: String {
        if let tz = self.timeZone{
            return tz
        }
        fetchTimeZone()
        return ""
    }
    
    
    func fetchRiseSet() {
        let urlStr = "https://api.sunrisesunset.io/json?lat=\(self.latitude)&lng=\(self.longitude)"
        print("\(self.latitude) \(self.longitude)")
        
        guard let url = URL(string: urlStr) else {
            print("url error")
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) {
            data, _, _ in
            guard let data = data,
            let api = try? JSONDecoder().decode(SunriseSunsetAPIResults.self, from: data)
            else {
                print("decode error")
                return
            }
            DispatchQueue.main.async {
                self.sunRise = api.results.sunrise
                self.sunSet = api.results.sunset
            }
            
        }.resume()
    }
    
    func fetchTimeZone() {
        let urlStr = "https://www.timeapi.io/api/TimeZone/coordinate?latitude=\(self.latitude)&longitude=\(self.longitude)"
        print("\(self.latitude) \(self.longitude)")
        
        guard let url = URL(string: urlStr) else {
            print("url error")
            return
        }
        let request = URLRequest(url: url)
        URLSession.shared.dataTask(with: request) {
            data, _, _ in
            guard let data = data,
            let api = try? JSONDecoder().decode(TimeZoneResults.self, from: data)
            else {
                print("decode error")
                return
            }
            DispatchQueue.main.async {
                self.timeZone = api.timeZone

            }
            
        }.resume()
    }
    
    func timeGMTtoLocal(_ gmt: String, _ local: String) -> String{
        let inputFormatter = DateFormatter()
        inputFormatter.dateStyle = .none
        inputFormatter.timeStyle = .medium
        inputFormatter.timeZone = .init(secondsFromGMT: 0)
        
        let outputFormatter = DateFormatter()
        outputFormatter.dateStyle = .none
        outputFormatter.timeStyle = .medium
        outputFormatter.timeZone = TimeZone(identifier: local)
        
        if let time = inputFormatter.date(from: gmt) {
            return outputFormatter.string(from: time)
        }
        return "<unknown>"
        
    }
    


}

struct SunriseSunset:Decodable {
    var sunrise: String
    var sunset: String
}

struct SunriseSunsetAPIResults:Decodable {
    var results: SunriseSunset
    
}

struct TimeZoneResults:Decodable {
    var timeZone: String
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
    
    var riseViewConverted : some View {
        HStack {
            Text("Sunrise:")
            if let rise = place.sunRise{
                if let zone = place.timeZone {
                    let loc = place.timeGMTtoLocal(rise, zone)
                    Text("GMT: \(rise) Local: \(loc)")
                } else {
                    Text("GMT: \(rise)")
                }
            } else {
                ProgressView()
            }
        }
    }
    
    var setViewConverted : some View {
        HStack {
            Text("Sunset:")
            if let set = place.sunSet{
                if let zone = place.timeZone {
                    let loc = place.timeGMTtoLocal(set, zone)
                    Text("GMT: \(set) Local: \(loc)")
                } else {
                    Text("GMT: \(set)")
                }
            } else {
                ProgressView()
            }
        }
    }
    
    var riseView: some View {
        HStack {
            Text("Sunrise:")
            Image(systemName: "sun.and.horizon.fill").foregroundColor(.yellow)
            if let rise = place.sunRise {
                Text("Local: \(rise)")
            } else {
                ProgressView()
            }
        }
    }
    var setView: some View {
        HStack {
            Text("Sunset:")
            Image(systemName: "moon.fill").foregroundColor(.white)
            if let set = place.sunSet {
                Text("Local: \(set)")
            } else {
                ProgressView()
            }
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






