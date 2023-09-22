# Service Coordinator

  

`ServiceCoordinator` is a utility class that simplifies the coordination of network requests in a Swift application. This class provides an easy way to customize the configuration of the shared URLSession session and send network requests asynchronously.

  

## Key Features:

  

-  **Custom Configuration**: Use the `setConfiguration(...)` function to customize the configuration of the shared URLSession session. You can adjust parameters such as timeout, the ability to use cellular data, and more.

  

-  **Asynchronous Request Sending**: The `sendRequest(...)` function allows you to send network requests asynchronously and receive results using the Combine framework. You can specify the URL, parameters, HTTP method, headers, and more.

  

-  **Error Handling**: The `ServiceCoordinator` class handles common network errors and provides specific results according to the status of the request.

  

## Basic Usage:

  

```swift

// Configure the shared URLSession session with custom options

ServiceCoordinator.shared.setConfiguration(timeOutRequest: 10, allowsCellular: false)

  

// Send a network request and receive the result using Combine

ServiceCoordinator.shared.sendRequest(url: "https://api.example.com/data", httpMethod: .get)

.sink { result in

switch result {

case .success(let data):

// Process the received data

case .failed(let error):

// Handle the network error

case .information(let statusCode):

// Process additional information

}

}

.store(in: &cancellables) // Ensure the subscriber is retained

  ```

## Example of Usage with Async/Await

In this example, we demonstrate how to use the `ServiceCoordinator` class with `async`/`await` in Swift to send a network request asynchronously and handle the response.

```swift
import Foundation

// Define a Codable structure to represent response data
struct ResponseData: Codable {
    let name: String
}

// Create an asynchronous function to send a network request
async func sendNetworkRequest() {
    // Configure the ServiceCoordinator session (customize as needed)
    ServiceCoordinator.shared.setConfiguration(timeOutRequest: 10, allowsCellular: true)
    
    // Define parameters for the request (if needed)
    let parameters: [String: Any] = ["key1": "value1", "key2": "value2"]
    
    // Send the network request and await the response using async/await
    do {
        let result: ServiceStatus<ResponseData?> = try await ServiceCoordinator.shared.sendRequest(
            url: "https://api.example.com/data",
            parameters: parameters,
            httpMethod: .get
        )
        
        switch result {
        case .success(let responseData):
            if let data = responseData {
                print("Data received: \(data)")
            } else {
                print("No data received.")
            }
        case .failed(let error):
            print("Network error: \(error.localizedDescription)")
        case .information(let statusCode):
            print("Informational response with status code: \(statusCode)")
        }
    } catch {
        print("Error sending the network request: \(error)")
    }
}

// Call the asynchronous function to send the network request
sendNetworkRequest()
```
Be sure to customize the `ServiceCoordinator` configuration and request parameters according to the specific needs of your application.

For more information and detailed examples, refer to the documentation of the **ServiceCoordinator** class  and the available functions.

  

## Warning Notes:

Customizing the configuration of the shared URLSession can affect the behavior of all network requests in the application. Use with caution and ensure you understand the implications of your custom configurations.

This README provides an overview of the code and its basic usage. Make sure to provide additional documentation, examples, and implementation details as needed so that users can effectively use the ServiceCoordinator class in their own application.
