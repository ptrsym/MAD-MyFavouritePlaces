//
//  MyFavouritePlacesTests.swift
//  MyFavouritePlacesTests
//
//  Created by Peter on 28/5/2023.
//
import XCTest
@testable import MyFavouritePlaces

final class MyFavouritePlacesTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func teststrLongitude(){
//      let testPlace = TestClass()
        let context = PersistenceHandler.shared.container.viewContext
        let testPlace = Place(context: context)
        testPlace.strLatitude = "45"
        XCTAssert(testPlace.strLatitude == "45.00000")
        testPlace.strLatitude = "91"
        XCTAssert(testPlace.strLatitude == "45.00000")
        testPlace.strLatitude = "-20.555556"
        XCTAssert(testPlace.strLatitude == "-20.55556")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
