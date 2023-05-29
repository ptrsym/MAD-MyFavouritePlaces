//
//  MapView.swift
//  MyFavouritePlaces
//
//  Created by Peter on 29/5/2023.
//

import SwiftUI
import CoreData
import MapKit
import CoreLocation

struct MapView: View {
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.editMode) var isEditMode
    @ObservedObject var mapModel: MapViewModel
    
    
    var body: some View {
        VStack{
            Text("Hi")
        }
    }
}

