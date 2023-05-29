//
//  MapView.swift
//  MyFavouritePlaces
//
//  Created by Peter on 29/5/2023.
//

import SwiftUI
import CoreData
import MapKit

struct MapView: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.editMode) var isEditMode
    @EnvironmentObject var mapModel: MapViewModel
    @ObservedObject var place: Place
    @State var address = ""
    @State var longitude = 0.0
    @State var latitude = 0.0
    
    var body: some View {
        VStack(alignment: .leading){
            HStack{
                Image(systemName: "magnifyingglass")
                    .onTapGesture {
                        if isEditMode?.wrappedValue == .active{
                      //      checkAddress()
                        }
                    }
                if isEditMode?.wrappedValue == .active{
                    TextField("Address", text: $address)
                } else {
                    Text("\(place.strName)")
                }
            }
            ZStack{
                Map(coordinateRegion: $mapModel.region)
            }
            HStack{
                Image(systemName: "mappin")
                    .onTapGesture {
                        if isEditMode?.wrappedValue == .active{
                            //      checkLocation()
                        }
                    }
                if isEditMode?.wrappedValue == .active{
                    HStack{
                        Text("Latitude: ")
                        TextField("Latitude", text: $mapModel.regionLat)
                    }.padding(.leading, 40)
                    HStack{
                        Text("Longitude: ")
                        TextField("Longitude", text: $mapModel.regionLong)
                    }.padding(.leading, 40)
                } else {
                    HStack{
                        Text("Latitude: \(mapModel.region.center.latitude)")
                    }.padding(.leading, 40)
                    HStack{
                        Text("Longitude: \(mapModel.region.center.longitude)")
                    }.padding(.leading, 40)
                }
            }
                
        }.onAppear {
            mapModel.updateModel(place)
            address = place.strName
        }
        .navigationTitle("Map of \(place.strName)")
        .navigationBarItems(trailing: HStack{
            Button(action: {
                place.strName = address
                //  place.longitude = longitude
                //  place.latitude = latitude
                saveData()
            }) {
                Text("Save")
            }
            EditButton()
        })
    }
}

