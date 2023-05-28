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
    var place: Place
    
    var body: some View {
        HStack{
            //Configure image thumbnail
            Text(place.strName)
        }
        
    }
}

//struct PlaceRowView_Previews: PreviewProvider {
//    static var previews: some View {
//        PlaceRowView()
//    }
//}
