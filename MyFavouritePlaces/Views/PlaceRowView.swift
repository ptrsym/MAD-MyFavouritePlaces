//
//  PlaceRowView.swift
//  AssignmentTwo
//
//  Created by Peter on 25/5/2023.
//

import SwiftUI
import CoreData


struct PlaceRowView: View {
    
    @Environment(\.managedObjectContext) var context
    @ObservedObject var place: Place
    @State var image = defaultImage
    
    var body: some View {
        HStack{
            image.frame(width: 30, height: 30).clipShape(Rectangle())
                .padding(.trailing, 10)
            Text(place.strName)
        }.task {
            await image = place.getImage()
        }
        
    }
}

//struct PlaceRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaceRowView()
//    }
//}
