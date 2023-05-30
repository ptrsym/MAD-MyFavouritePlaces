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
    @State var zoom = 10.0
    @State var latitude = ""
    @State var longitude = ""
    
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
                Spacer()
                Button("Update"){
                    checkMap()
                }
            }
            HStack{
                Text("Latitude: ")
                TextField("Latitude", text: $latitude)
                Text("Longitude: ")
                TextField("Longitude", text: $longitude)
            }
            Slider(value: $zoom, in: 10...60) {
                if !$0 {
                   checkZoom()
                }
            }
            ZStack{
                Map(coordinateRegion: $mapModel.region)
                VStack{
                    Image(systemName: "mappin")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding(.top, 10)
                        .onTapGesture {
                            if isEditMode?.wrappedValue == .active{
                                checkLocation()
                            }
                        }
                    Spacer()
                }
            }
                    HStack{
                        Text("Latitude: \(mapModel.region.center.latitude)")
                    }.padding(.leading, 40)
                    HStack{
                        Text("Longitude: \(mapModel.region.center.longitude)")
                    }.padding(.leading, 40)
                
            
                
        }.onAppear {
            mapModel.updateModel(place)
        }
        .task{
            checkMap()
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

