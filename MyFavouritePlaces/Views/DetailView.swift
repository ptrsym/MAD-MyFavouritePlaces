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
    var place:Place
    @State var isAddingDetail = false
    @State var newDetail = ""
    @State var name = ""
    @State var url = ""
    @State var longitude = ""
    @State var latitude = ""
    
    var body: some View {
        NavigationView {
            VStack (alignment: .leading) {
                if isEditMode?.wrappedValue == .active{
                        TextField("Enter place a name:", text:$name)
                        .padding(.top, 15)
                    HStack {
                        Text("Longitude:")
                        TextField("Enter location", text:$longitude)
                    }
                    HStack {
                        Text("Latitude:")
                        TextField("Enter latitude", text:$latitude)
                    }
                    TextField("Enter an image url: ", text: $url)
                        HStack {
                            Button(action: {
                                isAddingDetail = true
                            }) {
                                Text("Add new detail")
                            }
                            
                            //Save the new detail based on user input
                            Button(action: {
                                place.addDetail(newDetail)
                                newDetail = ""
                                isAddingDetail = false
                            }) {
                                Text("Save detail")
                            }
                        }.padding(.top, 10)
                        //provide a textfield when the user wants to add a detail
                        if isAddingDetail {
                            TextField("Enter a location detail", text: $newDetail)
                        }
                        List{
                            ForEach(place.details?.allObjects as? [Detail] ?? []) { detail in
                                Text(detail.detail ?? "")
                            }
                            .onDelete(perform:delDetail)
                        }
                       
                    Spacer()
                } else {
                    Text("Longitude: \(place.longitude)")
                        .padding(.leading, 20)
                        .padding(.top, 15)
                    Text("Latitude: \(place.latitude)")
                        .padding(.top, 5)
                        .padding(.leading, 20)
                    // display image url here
                    Text("Location Details:")
                        .padding(.top, 10)
                        .padding(.leading, 20)
                    List{
                        ForEach(place.details?.allObjects as? [Detail] ?? []) { detail in
                            Text(detail.detail ?? "")
                        }.onDelete(perform: delDetail)

                    }



                }
            }
        }
            .navigationBarTitle("\(place.strName)")
            .navigationBarItems(trailing: HStack{
                Button(action: {
                    place.strName = name
                    place.strUrl = url
                    place.strLongitude = longitude
                    place.strLatitude = latitude
                    saveData()
                    isEditMode?.wrappedValue = .inactive
                }) {
                    Text("Save")
                }
                EditButton()
            })
            .onAppear {
                name = place.strName
                url = place.strUrl
                longitude = place.strLongitude
                latitude = place.strLatitude
            }
    }
}

//struct DetailView_Previews: PreviewProvider {
//    static var previews: some View {
//        DetailView(place: place)
//    }
//}
