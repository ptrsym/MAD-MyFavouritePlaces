//
//  ViewModel.swift
//  MyFavouritePlaces
//
//  Created by Peter on 28/5/2023.
//

import Foundation
import CoreData
import SwiftUI


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

extension Place {
    
    
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
    
//    func fetchData() {
//        let fetchRequest: NSFetchRequest<Place> = Place.fetchRequest()
//        do {
//            let fetchedPlaces = try context.fetch(fetchRequest)
//        } catch {
//            print("Failed to fetch data: \(error)")
//        }
//    }


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



