//
//  TimeZoneView.swift
//  MyFavouritePlaces
//
//  Created by Peter on 31/5/2023.
//

import SwiftUI

struct TimeZoneView: View {
    
    @ObservedObject var place: Place

    var body: some View {
        HStack{
            
            Image(systemName: "sunrise.fill").background(.yellow)
            Text("Sunrise: \(place.timezone)")
            Spacer()
            Image(systemName: "moon.fill").background(.white)
            Text("Sunset: \(place.timezone)")
        }
        
        
    }
    
}

