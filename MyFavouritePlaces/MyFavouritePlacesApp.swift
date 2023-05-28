//
//  MyFavouritePlacesApp.swift
//  MyFavouritePlaces
//
//  Created by Peter on 28/5/2023.
//

import SwiftUI

@main
struct MyFavouritePlacesApp: App {
    
    let persistenceHandler = PersistenceHandler.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, persistenceHandler.container.viewContext)
                .environment(\.colorScheme, .dark)
        }
    }
}
