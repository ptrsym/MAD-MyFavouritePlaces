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
                    TextField("Address", text: $mapModel.name)
                } else {
                    Text("\(mapModel.name)")
                }
            }
            ZStack{
                Map(coordinateRegion: $mapModel.region)
                Image(systemName: "mappin")
                    .resizable()
                    .frame(width: 50, height: 50)
                    .onTapGesture {
                        if isEditMode?.wrappedValue == .active{
                            //      checkLocation()
                        }
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
            
                
        }.onAppear {
            mapModel.updateModel(place)
        }
        .navigationTitle("Map of \(mapModel.name)")
        .navigationBarItems(trailing: HStack{
            Button(action: {
                mapModel.updatePlace()
                isEditMode?.wrappedValue = .inactive
            }) {
                Text("Save")
            }
            EditButton()
        })
    }
}

