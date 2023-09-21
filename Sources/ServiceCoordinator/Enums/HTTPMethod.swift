//
//  HTTPMethod.swift
//  
//
//  Created by Maximiliano Ovando Ramírez on 19/09/23.
//

/**
 Enumeration for common HTTP request methods.
 
 This enumeration provides cases for the most commonly used HTTP request methods, allowing for clear and readable representation of methods in your code. Each case is associated with a string that represents the method in text format.
 
 Example of usage:
 
 let method = HTTPMethod.get
 print(method.rawValue) // Prints "GET"
 
 - Available cases:
   - `get`: Used to retrieve data from a web server.
   - `post`: Used to send data to the server for processing.
   - `put`: Used to update an existing resource on the server or create a new one if it doesn't exist.
   - `delete`: Used to remove a specific resource on the server.
   - `patch`: Used to apply partial modifications to a resource on the server.
   - `options`: Used to obtain information about available communication options for the target resource.
   - `head`: Used to check the availability of a resource without downloading the full content.
   - `trace`: Used to trace the route a request takes through intermediary servers.
   - `connect`: Used to establish a network connection to the resource identified by the URI.
 */
public enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case delete = "DELETE"
    case patch = "PATCH"
    case options = "OPTIONS"
    case head = "HEAD"
    case trace = "TRACE"
    case connect = "CONNECT"
}

