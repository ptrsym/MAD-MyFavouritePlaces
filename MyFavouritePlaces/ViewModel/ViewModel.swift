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
/// Call an instance of  the `MapViewModel` class to configure and update the map view in your application, and observe the published properties to respond to changes in the map data.

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
    
    
    /// Function to retrieve map address location based on model stored coordinate attributes
    ///
    ///  A callback function to perform a reverse geocode lookup to retrieve an address string based on the current map orientation coordinates.
    ///  Assigns the address to the name attribute of the model.
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
    
    

    /// Finds the coordinates of the current address configuration of the model.
    ///
    /// This function performs a geocode address string lookup to match the address string provided by the model to a set of longitude and latitude coordinates.
    /// It uses a callback method with an escaping functin to achieve this so it can  correctly adjust the longitude and latitude fields of the view and centre the map view over the correct region with an animation.
    /// - Parameter callback: a callback function that updates the view's longitude and latitude textfields when the first lookup is completed.
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
    
    ///Asynchronous  interpretation of looking up location coords based on address
    ///
    /// This asynchronous function performs a geocoder lookup to convert an address to a set of location coordinates representing that address.
    /// It sets the model's attributes to the new coordinates and centres the map view over the found region.
    func fromAddressToLoc() async {
        let encode = CLGeocoder()
        let marks = try? await encode.geocodeAddressString(self.name)
        
            if let mark = marks?.first {
                self.latitude = mark.location?.coordinate.latitude ?? self.latitude
                self.longitude = mark.location?.coordinate.longitude ?? self.longitude
                self.setRegion()
            }
        }
    
    /// Zoom function for map slider
    ///
    /// A function to adjust the zoom of the map view based on the slider configuration.
    /// It uses a zoom variable to transform the locationdelta of the region currently being inspected
    /// - Parameter zoom: A variable to set the scale factor of the zoom slider.
    func zoomToDelta (_ zoom: Double) {
        let c1 = -10.0
        let c2 = 3.0
        self.delta = pow(10.0, zoom / c1 + c2)
    }

}

extension Place {
    
    /// Function to generate a thumbnail image based on current map orientation
    ///
    /// This function generates a snapshot of the map that would be displayed given the coordinates of the associated place to be used as a thumbnail.
    /// It uses MKShapshotter to generate this image by first configuring the options with the place attributes and the desired image size.
    /// - Returns: a UIImage representing the map of the associated place configured to thumbnail size. Nil if the operation errors.
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
    /// Adds a new detail to the place relationship from the context
    ///
    /// Creates a new detail entity from the  context and then assigns it the value of the parameter string.
    /// Assigns this detail entity to its associated place via the place relationship in CoreData.
    /// - Parameter description: A description of the place the detail is associated with.
    func addDetail(_ description:String) {
        let context = PersistenceHandler.shared.container.viewContext
        let newDetail = Detail(context: context)
        newDetail.detail = description
        newDetail.place = self
        saveData()
    }
    
    /// Function to fetch an image from a URL and store it into a local cache
    ///
    /// This function searches for an image associated with its imgurl attribute by looking up a local dictionary.
    /// If it has no entry in the dictionary it attempts to download the image associated with its imgurl attribute at that URL.
    /// If there is no URL string or it is an invalid URL a default image is displayed for use.
    /// - Returns: a SwiftUI image to be displayed that represents its associated place.
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

    /// Validates a correct delta value of the delta attribute when set and displays a string representation with get
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
    
    /// Retrieves a default value with get if empty else retrieves or sets the name attribute.
    var strName:String {
        get {
            self.name ?? "no name"
        }
        set {
            self.name = newValue
        }
    }
    
    /// Get/Set method on the longitude attribute. Gets a formatted string value representing stored latitude and Sets a valid longitude value.
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
    
    /// Get/Set method on the latitude attribute. Gets a formatted string value represting stored latitude and Sets a valid latitude value.
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

    /// Get/Set method on the imgurl attribute. Gets a string representation of the stored URL image and Safely unwraps a string converting it to a URL.
    var strUrl: String {
        get {
            self.imgurl?.absoluteString ?? ""
        }
        set {
            guard let url = URL(string: newValue) else {return}
            self.imgurl = url
            }
        }
    
    /// Checks if there is a stored timezone value and displays it otherwise performs a timezone lookup based on stored coordinate values and assigns the attribute to the retrieved timezone.
//    var timeZoneStr: String {
//        if let tz = self.timeZone{
//            return tz
//        }
//        fetchTimeZone()
//        return ""
//    }
    
    
    /// Function to retrieve the time of sunrise and sunset of a location
    ///
    ///A callback function that performs a get request to a Sunrise and Sunset API website to retrieve information based on stored latitude and longitude values.
    ///Decodes the  retrieved information into a storage struct to filter the values and then assigns the values to the associated place attributes.
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
    
    /// Function to retrieve the timezone of a location
    ///
    ///Callback function that first performs a get request to a web API that provides information about the timezone at the location of supplied coordinates.
    ///Decodes the retrieved JSON file into a storage struct and then assigns the value to into the place object's associated attribute
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
    
    /// A function to convert a time in GMT format to a local time given a supplied timezone.
    ///
    ///This function uses a DateFormatter to convert input GMT+0 time string into the local time of the place it is associated with.
    /// - Parameters:
    ///   - gmt: A string representing the GMT+0 time of a place.
    ///   - local: A string representing the local timezone of a place.
    /// - Returns: A string representing the local time of a place.
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

/// A struct to store decoded values for sunrise and sunset
struct SunriseSunset:Decodable {
    var sunrise: String
    var sunset: String
}

/// A struct to store the results of a get request to a sunrise sunset API
struct SunriseSunsetAPIResults:Decodable {
    var results: SunriseSunset
    
}

/// A struct to store the decoded timezone from a get request to an API
struct TimeZoneResults:Decodable {
    var timeZone: String
}


		
extension ContentView {
    /// Seletes a place entity from collection
    ///
    /// Deletes a place entity from a Place container created from the CoreData. It is executed after a swipe action provides the indexset of the place to be deleted.
    /// Uses a map closure to access the index and perform a delete method.
    /// Saves the context to persist the changes.
    /// - Parameter index: An indexset of the place to be deleted acquired by performing a delete on this place during editmode of the view.
    func delPlace(index: IndexSet) {
        withAnimation {
            index.map{favouritePlaces[$0]}.forEach { place in
                context.delete(place)
            }
            saveData()
        }
    }
    /// A function to create a new place entity from the context and then save the data to persist changes.
    func addPlace() {
        let newPlace = Place(context: context)
        newPlace.strName = "New Place"
        saveData()

    }
    
}
extension DetailView {
    // deletes a detail relationship from a place
    /// A function to delete a detail from a place entity through its CoreData relationship.
    /// Converts the set of details associated with a place to a workable array of detail objects and iterates through this array attempting to match the indexset supplied to the values in that array.
    /// Deletes any matching values from the context and performs a save to persist changes.
    /// - Parameter index: An indexset representing the items to be deleted from the details collection.
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
    
    /// A function to perform the address lookup based on coordinates within the mapview. Accepts the callback function to update the local longitude and latitude values.
    func checkAddress(){
        mapModel.fromAddressToLocOld(updateViewCoord)
    }
//        Task{
//            await mapModel.fromAddressToLoc()
//            latitude = mapModel.latStr
//            longitude = mapModel.longStr
//        }
//    }
        
    /// Retrieves the address name of the associated coordinates and centres the map
    ///
    ///
    /// A function that sets the attributes of the model to the latitude and longitude currently being observed by the user within the view. Updates the address of the view based on these coordinates
    /// and pans the camera to the location.
    func checkLocation(){
        mapModel.longStr = longitude
        mapModel.latStr = latitude
        mapModel.fromLocToAddress()
        mapModel.setRegion()
        
    }
    
    ///  Updates map as the mapview zooms in and out and sets the region
    ///
    ///  This function performs an update on the map model values after a zoom is performed using the view slider.
    ///  It calls the checkmap() function to update the model and local location values and then performs the zoom scale adjustment
    ///  on the map. Finally it checks the new address after map adjustment and centres the view more accurately over the coordinates.
    func checkZoom(){
        checkMap()
        mapModel.zoomToDelta(zoom)
        mapModel.fromLocToAddress()
        mapModel.setRegion()
    }
    

    /// Sets the models coordinate values to the current orientation on the map. Updates the local variables used for user interaction
    ///  and then retrieves the address name of the location currently being viewed in that orientation.
    func checkMap(){
        mapModel.updateFromRegion()
        latitude = mapModel.latStr
        longitude = mapModel.longStr
        mapModel.fromLocToAddress()
    }
    
    /// Sets local coords based on model configuration
    ///
    ///
    /// Assigns the local latitude and longitude variables of the view to the currently stored values in the map model.
    func updateViewCoord() {
        latitude = mapModel.latStr
        longitude = mapModel.longStr
    }
    
}






