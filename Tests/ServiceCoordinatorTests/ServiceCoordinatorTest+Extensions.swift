//
//  ServiceCoordinatorTest+Extensions.swift
//  PokemonMasterTests
//
//  Created by Maximiliano Ovando Ramírez on 23/06/23.
//

import XCTest
@testable import ServiceCoordinator

final class ServiceCoordinatorTestExtensions: XCTestCase {

    func testDataToString() {
        let jsonData =
              """
              [
                  {
                      "firstName": "Lee"
                  },
                  {
                      "firstName": 0
                  }
              ]
              """

        guard let data = jsonData.data(using: .utf8) else {
            XCTFail("No se configuro de forma correcta el JSON")
            return
        }

        let stringData = data.toString()

        XCTAssertNotEqual(stringData, "Sin informacion", "No codifico de forma correcta la informacion")
    }

    func testErrorDataToString() {
        let data = Data([0xFF, 0xFE, 0xFD])

        let stringData = data.toString()

        XCTAssertEqual(stringData, "Sin informacion", "Codifico de forma correcta la informacion")
    }

}
