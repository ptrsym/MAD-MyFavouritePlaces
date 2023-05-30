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
                            //using callback method queue finding location coordinates based on address field
                           checkAddress()
                        }
                    }
                Text("Address: ")
                if isEditMode?.wrappedValue == .active{
                    TextField("Address", text: $mapModel.name)
                } else {
                    Text("\(mapModel.name)")
                }
                Spacer()
                Button("Update"){
                    // tap to update local fields with current orientation and address
                    checkMap()
                }
            }
            HStack{
                Text("Latitude: ")
                TextField("Latitude", text: $latitude)
                Text("Longitude: ")
                TextField("Longitude", text: $longitude)
            }
            // add a slider to set zoom level
            Slider(value: $zoom, in: 10...60) {
                if !$0 {
                    //reorient and update map details based on zoom scale
                   checkZoom()
                }
            }
            ZStack{
                //display map based on stored region specifications
                Map(coordinateRegion: $mapModel.region)
                VStack{
                    Image(systemName: "mappin")
                        .resizable()
                        .frame(width: 40, height: 40)
                        .padding(.top, 10)
                        .onTapGesture {
                            if isEditMode?.wrappedValue == .active{
                                // tap to find address name of current orientation coordinates
                                checkLocation()
                            }
                        }
                    Spacer()
                }
            }       // bind current map orientation to long/lat display
                    HStack{
                        Text("Latitude: \(mapModel.region.center.latitude)")
                    }.padding(.leading, 40)
                    HStack{
                        Text("Longitude: \(mapModel.region.center.longitude)")
                    }.padding(.leading, 40)
        // load place into mapviewmodel on view entry
        }.onAppear {
            mapModel.updateModel(place)
        }
        // queue map centering on place location coordinates on view entry
        .task{
            checkMap()
        }
        .navigationTitle("Map of \(mapModel.name)")
        .navigationBarItems(trailing: HStack{
            // update associated place
            Button(action: {
                mapModel.updatePlace()
                isEditMode?.wrappedValue = .inactive
            }) {
                Text("Save")
            }
            // edit mode enables texfield manual modification
            EditButton()
        })
    }
}

