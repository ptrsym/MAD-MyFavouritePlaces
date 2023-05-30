//
//  DetailView.swift
//  AssignmentTwo
//
//  Created by Peter on 25/5/2023.
//

import SwiftUI
import CoreData

struct DetailView: View {
    @Environment(\.editMode) var isEditMode
    @Environment(\.managedObjectContext) var context
    
    @ObservedObject var place:Place
    @State var newDetail = ""
    @State var name = ""
    @State var url = ""
    @State var longitude = ""
    @State var latitude = ""
    @State var image = defaultImage
    
    var body: some View {
        VStack (alignment: .leading) {
            if isEditMode?.wrappedValue == .active{
                List{
                    
                    TextField("Enter place a name:", text:$name)
                        .padding(.leading, -20)
                        .listRowBackground(Color.clear)
                    TextField("Enter an image url: ", text: $url)
                        .padding(.leading, -20)
                        .listRowBackground(Color.clear)
                    TextField("Enter a location detail", text: $newDetail)
                        .listRowBackground(Color.clear)
                        .padding(.leading, -20)
                    
                    //unwraps place-details relationship and converts to workable array
                    ForEach(place.details?.allObjects as? [Detail] ?? []) { detail in
                        Text(detail.detail ?? "")
                    }.onDelete(perform:delDetail)
                    
                    HStack {
                        Text("Longitude:")
                        TextField("Enter location", text:$longitude)
                    }
                    .listRowBackground(Color.clear)
                    .padding(.leading, -20)
                    .padding(.top, 10)
                    
                    HStack {
                        Text("Latitude:")
                        TextField("Enter latitude", text:$latitude)
                    }
                    .listRowBackground(Color.clear)
                    .padding(.leading, -20)
                }
            } else {
                //finer control over image size
                GeometryReader{ geometry in
                    image
                        .scaledToFit()
                        .padding(20)
                        .frame(maxWidth: geometry.size.width, maxHeight: geometry.size.height)
                }.padding(.bottom, -20)
                
                List{
                    NavigationLink(destination: MapView(place: place)){
                        MapRowView(place: place)
                    }
                    Text("Location Details:")
                        .padding(.leading, -20)
                        .padding(.bottom, 10)
                        .listRowBackground(Color.clear)
                    
                    //unpacks the place-details relationship from an NSSet into a workable array
                    ForEach(place.details?.allObjects as? [Detail] ?? []) { detail in
                        Text(detail.detail ?? "")
                    }.onDelete(perform: delDetail)
                    
                    Text("Longitude: \(place.longitude)")
                        .padding(.leading, -20)
                        .padding(.top, 10)
                        .listRowBackground(Color.clear)
                    Text("Latitude: \(place.latitude)")
                        .padding(.leading, -20)
                        .listRowBackground(Color.clear)
            
                }.padding(.top, -20)
                
            }
            HStack {
                riseView
                Spacer()
                setView
            }.offset(y: -UIScreen.main.bounds.height * 0.1)
        }
        .navigationBarTitle("\(place.strName)").padding(.bottom, -40)
        .navigationBarItems(trailing: HStack{
            //save all changes and reset relevant fields. avoids adding an empty detail
            Button(action: {
                place.strName = name
                place.strUrl = url
                place.strLongitude = longitude
                place.strLatitude = latitude
                if !newDetail.isEmpty {
                    place.addDetail(newDetail)
                }
                newDetail = ""
                saveData()
                Task{
                    await image = place.getImage()
                }
                isEditMode?.wrappedValue = .inactive
            }) {
                Text("Save")
            }
            EditButton()
        })
        //display correct field values
        .onAppear {
            name = place.strName
            url = place.strUrl
            longitude = place.strLongitude
            latitude = place.strLatitude
        }
        //retrieve the image from the cache if available
        .task {
            await image = place.getImage()
            place.fetchTimeZone()
            place.fetchRiseSet()
        }
    }
}
