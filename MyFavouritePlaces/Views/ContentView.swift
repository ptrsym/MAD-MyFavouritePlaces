//
//  ContentView.swift
//  AssignmentTwo
//
//  Created by Peter on 24/5/2023.
//

import SwiftUI
import CoreData

struct ContentView: View {
    
    @Environment(\.managedObjectContext) var context
    @FetchRequest(entity: Place.entity(), sortDescriptors: [NSSortDescriptor(key: "name", ascending: true)])
    var favouritePlaces: FetchedResults<Place>
    
    var body: some View {
        NavigationView{
            VStack{
                List{
                    ForEach(favouritePlaces) { place in
                        NavigationLink(destination: DetailView(place: place)){
                            PlaceRowView(place: place)
                        }
                    }.onDelete(perform: delPlace)
                }.padding()
//                    .onAppear{
//                        fetchData()
//                    }
            }
            .navigationTitle("My Favourite Places")
            .navigationBarItems(
                leading: Button(action:{
                    addPlace()
                }) {Image(systemName:"plus")}
                ,
                trailing: EditButton())
        }
    }
}
