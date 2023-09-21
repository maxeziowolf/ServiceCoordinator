//
//  NetworkError.swift
//  
//
//  Created by Maximiliano Ovando Ramírez on 20/09/23.
//

/**
 An enumeration representing various network-related errors that can occur during network requests.

 Use this enum to handle and describe different types of errors that may arise in the context of network requests, such as lack of internet connection, server errors with specific status codes, request timeouts, invalid URLs, invalid responses, unauthorized access, resource not found, and generic other errors.

 Each case in this enum provides a localized description that describes the nature of the error.

 - Note:
    Customize this enum to suit the specific error scenarios of your application.

 - SeeAlso: `localizedDescription`
 */
public enum NetworkError: Error {
    /// No internet connection.
    case noInternetConnection

    /// Server error with a specific status code.
    case serverError(statusCode: Int)

    /// Request timeout.
    case requestTimeout

    /// Invalid URL.
    case invalidURL

    /// Invalid response from the server.
    case invalidResponse

    /// Invalid response from the server.
    case badRequest

    /// Unauthorized access.
    case unauthorized

    /// Resource not found.
    case notFound

    /// Error in decodign
    case decodingError

    /// Generic other error with a custom message.
    case otherCode(code: Int)

    /// Generic other error with a custom message.
    case other(message: String)

    /**
     A localized description of the error.
     
     This computed property returns a human-readable description of the error based on its case. It provides additional context about the nature of the error.

     - Returns:
        A string describing the error.
     */
    public var localizedDescription: String {
        switch self {
        case .noInternetConnection:
            return "No internet connection."
        case .serverError(let statusCode):
            return "Server error: \(statusCode)"
        case .requestTimeout:
            return "Request timeout."
        case .invalidURL:
            return "Invalid URL."
        case .invalidResponse:
            return "Invalid response from server."
        case .badRequest:
            return "Bad request"
        case .unauthorized:
            return "Unauthorized access."
        case .notFound:
            return "Resource not found."
        case .decodingError:
            return "Error in decoding data"
        case .other(let message):
            return message
        case .otherCode(let code):
            return "Other code: \(code)"
        }
    }
}
