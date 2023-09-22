//
//  File.swift
//  
//
//  Created by Maximiliano Ovando Ramírez on 21/09/23.
//

import XCTest
@testable import ServiceCoordinator

class NetworkErrorTests: XCTestCase {

    func testLocalizedDescriptionForNoInternetConnection() {
        let error = NetworkError.noInternetConnection
        XCTAssertEqual(error.localizedDescription, "No internet connection.")
    }

    func testLocalizedDescriptionForServerError() {
        let error = NetworkError.serverError(statusCode: 500)
        XCTAssertEqual(error.localizedDescription, "Server error: 500")
    }

    func testLocalizedDescriptionForRequestTimeout() {
        let error = NetworkError.requestTimeout
        XCTAssertEqual(error.localizedDescription, "Request timeout.")
    }

    func testLocalizedDescriptionForInvalidURL() {
        let error = NetworkError.invalidURL
        XCTAssertEqual(error.localizedDescription, "Invalid URL.")
    }

    func testLocalizedDescriptionForInvalidResponse() {
        let error = NetworkError.invalidResponse
        XCTAssertEqual(error.localizedDescription, "Invalid response from server.")
    }

    func testLocalizedDescriptionForBadRequest() {
        let error = NetworkError.badRequest
        XCTAssertEqual(error.localizedDescription, "Bad request")
    }

    func testLocalizedDescriptionForUnauthorized() {
        let error = NetworkError.unauthorized
        XCTAssertEqual(error.localizedDescription, "Unauthorized access.")
    }

    func testLocalizedDescriptionForNotFound() {
        let error = NetworkError.notFound
        XCTAssertEqual(error.localizedDescription, "Resource not found.")
    }

    func testLocalizedDescriptionForDecodingError() {
        let error = NetworkError.decodingError
        XCTAssertEqual(error.localizedDescription, "Error in decoding data")
    }

    func testLocalizedDescriptionForOther() {
        let message = "Custom error message"
        let error = NetworkError.other(message: message)
        XCTAssertEqual(error.localizedDescription, message)
    }

    func testLocalizedDescriptionForOtherCode() {
        let code = 123
        let error = NetworkError.otherCode(code: code)
        XCTAssertEqual(error.localizedDescription, "Other code: \(code)")
    }
}

