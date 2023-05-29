//
//  MapRowView.swift
//  MyFavouritePlaces
//
//  Created by Peter on 29/5/2023.
//

import SwiftUI
import CoreData
import MapKit

struct MapRowView: View {
    @Environment(\.managedObjectContext) var context
    @ObservedObject var place: Place
    @State var image: UIImage?

    var body: some View {
        HStack {
            if let image = image {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else {
                Text("Loading...")
            }
            Text("View Map")
        }
        .task {
            image = await place.generateThumbnailImage()
        }
    }
}
