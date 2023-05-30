//
//  MyFavouritePlacesTests.swift
//  MyFavouritePlacesTests
//
//  Created by Peter on 28/5/2023.
//
import XCTest
@testable import MyFavouritePlaces

final class MyFavouritePlacesTests: XCTestCase {
    
    let context = PersistenceHandler.shared.container.viewContext

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testExample() throws {
        // put test functions in here to test them
        teststrLongitude()
        testupdateModel()
        teststrLatitude()
    }
    
    // computed property of Place
    func teststrLatitude(){
        let testPlace = Place(context: context)
        testPlace.strLatitude = "45"
        XCTAssert(testPlace.strLatitude == "45.00000")
        testPlace.strLatitude = "91"
        XCTAssert(testPlace.strLatitude == "45.00000")
        testPlace.strLatitude = "-20.55556"
        XCTAssert(testPlace.strLatitude == "-20.55556")
    }
    func teststrLongitude(){
        let testPlace = Place(context: context)
        testPlace.strLongitude = "45"
        XCTAssert(testPlace.strLongitude == "45.00000")
        testPlace.strLongitude = "181"
        XCTAssert(testPlace.strLongitude == "45.00000")
        testPlace.strLongitude = "-120.1234567"
        XCTAssert(testPlace.strLongitude == "-120.12346")
    }

    //test loading the mapviewmodel with a place entity and empty viewmodel init
    func testupdateModel(){
        let place = Place(context:context)
        place.name = "Home"
        place.latitude = -27.0
        place.longitude = 152.0
        place.delta = 0.2
        let testModel = MapViewModel()
        XCTAssertTrue(testModel.place == nil)
        XCTAssertTrue(testModel.name == "")
        XCTAssertTrue(testModel.latitude == 0.0)
        XCTAssertTrue(testModel.longitude == 0.0)
        XCTAssertTrue(testModel.delta == 100)
        testModel.updateModel(place)
        XCTAssertTrue(testModel.name == "Home")
        XCTAssertTrue(testModel.latitude == -27.0)
        XCTAssertTrue(testModel.longitude == 152.0)
        XCTAssertTrue(testModel.delta == 0.2)
    }


    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
