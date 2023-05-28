//
//  Persistence.swift
//  MyFavouritePlaces
//
//  Created by Peter on 28/5/2023.
//

import Foundation
import CoreData

struct PersistenceHandler {
    static let shared = PersistenceHandler()
    let container: NSPersistentContainer
    
    init (){
        container = NSPersistentContainer(name: "Places")
        container.loadPersistentStores { storeDescription, error in
            if let error = error as NSError? {
                fatalError("Error to load with \(error)")
            }
        }
    }
}

