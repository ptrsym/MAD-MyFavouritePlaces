//
//  MapRowView.swift
//  MyFavouritePlaces
//
//  Created by Peter on 29/5/2023.
//

import SwiftUI
import CoreData
import MapKit
import CoreLocation

struct MapRowView: View {
    @Environment(\.managedObjectContext) var context
    @EnvironmentObject var mapModel: MapViewModel
    @ObservedObject var place: Place
    @State var image: UIImage?

    var body: some View {
        HStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
            } else {
                Text("Loading...")
            }
            Spacer()
            Text("View Map")

        }
        .task {
            image = await place.generateThumbnailImage()
        }
    }
}
