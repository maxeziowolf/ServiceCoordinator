import Foundation
import Combine

public final class ServiceCoordinator {

    // MARK: Shared Instance
    /// A shared singleton instance of the `ServiceCoordinator` class.
    public static let shared = ServiceCoordinator()

    // MARK: - Attributes
    /// The URL session used for making network requests.
    private var sessionURL = URLSession.shared
    /// The custom configuration options for the URL session.
    private var sessionConfiguration: URLSessionConfiguration?
    /// The delegate responsible for handling events during network requests.
    public var sessionDelegate: URLSessionDelegate?
    /// The custom operation queue for managing URL session tasks.
    public var sessionQueue: OperationQueue?

    // MARK: - Init
    private init() {}

    // MARK: - Configuration function
    /**
     Configures the shared URLSession's network session with custom options.

     - Parameters:
        - timeOutRequest: The maximum timeout in seconds for an individual request (default: 30 seconds).
        - timeOutResource: The maximum timeout in seconds for the entire data transfer (default: 30 seconds).
        - allowsCellular: Indicates whether cellular network usage is allowed (default: true).
        - urlCache: The custom URLCache to be used (default: shared).
        - connectionProxy: A dictionary with custom proxy configuration details (default: nil).
        - httpCookieStorage: The custom HTTPCookieStorage to be used (default: nil).
        - httpAdditionalHeaders: Custom HTTP headers to be added to requests (default: nil).
        - httpMaximumConnectionsPerHost: The maximum number of simultaneous connections per host (default: 6).
        - isDiscretionary: Indicates whether the session can automatically optimize requests to minimize energy consumption and data costs (default: false).
        - networkServiceType: The network service type for requests (default: .default).

     - Note:
        Use this function to customize the configuration of the shared URLSession's network session in your application.

     - Warning:
        Changing the default configuration can affect the behavior of all network requests in the application. Use with caution.
     */
    public func setConfiguration(
        timeOutRequest: Double = 30,
        timeOutResourse: Double = 30,
        allowsCellular: Bool = true,
        urlCache: URLCache = .shared,
        connectionProxy: [AnyHashable : Any]? = nil,
        httpCookieStorage: HTTPCookieStorage? = nil,
        httpAdditionalHeaders: [AnyHashable : Any]? = nil,
        httpMaximumConnectionsPerHost: Int = 6,
        isDiscretionary: Bool = false,
        networkServiceType: NSURLRequest.NetworkServiceType = .default,
        urlProtocol: AnyClass? = nil
    ) {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = timeOutRequest
        configuration.timeoutIntervalForResource = timeOutResourse
        configuration.allowsCellularAccess = allowsCellular
        configuration.urlCache = urlCache
        configuration.connectionProxyDictionary = connectionProxy
        configuration.httpCookieStorage = httpCookieStorage
        configuration.httpAdditionalHeaders = httpAdditionalHeaders
        configuration.httpMaximumConnectionsPerHost = httpMaximumConnectionsPerHost
        configuration.isDiscretionary = isDiscretionary
        configuration.networkServiceType = networkServiceType
        if let urlProtocol = urlProtocol {
            configuration.protocolClasses = [urlProtocol]
        }
        
        sessionConfiguration = configuration
    }

    /// Removes the custom URLSession configuration.
    ///
    /// This function sets the `sessionConfiguration` attribute to `nil`, effectively removing any custom URLSession configuration that may have been set.
    public func removeConfiguration() {
        sessionConfiguration = nil
        sessionURL = URLSession.shared
    }

    /// Retrieves the custom URLSession configuration.
    ///
    /// - Returns: The custom URLSession configuration if set, or `nil` if no custom configuration has been specified.
    public func getConfiguration() -> URLSessionConfiguration? {
        return sessionConfiguration
    }

    // MARK: - Request Function
    /**
     Sends a network request and returns a result asynchronously.
     
     - Parameters:
        - url: The URL string for the request.
        - params: The parameters to include in the request (default: nil).
        - httpMethod: The HTTP method for the request (default: .get).
        - headerFields: Custom HTTP headers to include in the request (default: nil).
        - body: The request body as a dictionary (default: nil).
        - cachePolicy: The cache policy for the request (default: .reloadIgnoringLocalCacheData).
     
     - Returns: A `ServiceStatus` enum representing the result of the request.
     */
    public func sendRequest<T: Codable>(
        url urlString: String,
        parameters params: [String: Any]? = nil,
        httpMethod: HTTPMethod = .get,
        headerFields: [String: String]? = nil,
        body: [String: Any]? = nil,
        cachePolicy: URLRequest.CachePolicy = .reloadIgnoringLocalCacheData
    ) async -> ServiceStatus<T?> {
        
        guard let url = getURL(url: urlString, parameters: params) else {
            return .failed(error: NetworkError.invalidURL)
        }
        
        if let configuratation = sessionConfiguration {
            sessionURL = URLSession(configuration: configuratation, delegate: sessionDelegate, delegateQueue: sessionQueue)
        }
        
        var request = URLRequest(url: url)
        
        request.httpMethod = httpMethod.rawValue
        request.cachePolicy = cachePolicy
        
        if let headerFields = headerFields {
            request.allHTTPHeaderFields = headerFields
        }
        
        if let body = body, httpMethod != HTTPMethod.get, let jsonData = codingBody(body: body) {
            request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
            request.httpBody = jsonData
        }
        
        do {
            let (data, response) =  try await sessionURL.data(for: request)
            
            if let httpResponse = response as? HTTPURLResponse {
                
                switch httpResponse.statusCode {
                case 100..<200:
                    return .information(code: httpResponse.statusCode)
                case 200:
                    if !data.isEmpty {
                        
                        if let dataD: T = data as? T {
                            return .success(data: dataD)
                        } else if let dataD: T = decodingRequest(data: data) {
                            return .success(data: dataD)
                        } else {
                            return .failed(error: NetworkError.decodingError)
                        }
                        
                    } else {
                        return .failed(error: NetworkError.invalidResponse)
                    }
                case 201..<204:
                    return .success(data: nil)
                case 300..<400:
                    return .information(code: httpResponse.statusCode)
                case 400:
                    return .failed(error: NetworkError.badRequest)
                case 401:
                    return .failed(error: NetworkError.unauthorized)
                case 404:
                    return .failed(error: NetworkError.notFound)
                case 500...599:
                    return .failed(error: NetworkError.serverError(statusCode: httpResponse.statusCode))
                default:
                    return .failed(error: NetworkError.otherCode(code: httpResponse.statusCode))
                }
            }
            
            return .failed(error: NetworkError.invalidResponse)
        } catch let error {
            return .failed(error: NetworkError.other(message: error.localizedDescription))
        }
    }

    // MARK: - Internal functions
    /// Constructs a URL by combining a base URL string with optional query parameters.
    ///
    /// - Parameters:
    ///   - urlString: The base URL string.
    ///   - params: Optional query parameters as a dictionary.
    ///
    /// - Returns: A URL constructed by appending query parameters to the base URL, or `nil` if the URL cannot be formed.
    ///
    /// - Note:
    ///   This function takes a base URL string and an optional dictionary of query parameters and constructs a valid URL by appending the query parameters to the base URL. The resulting URL is returned. If the provided URL string is not valid, or if no query parameters are provided, `nil` is returned.
    ///
    /// - Warning:
    ///   It is important to ensure that the input URL string is properly formatted to avoid unexpected results. Invalid URLs may lead to `nil` being returned.
    internal func getURL(url urlString: String, parameters params: [String: Any]?) -> URL? {

        guard let url = URL(string: urlString) else { return nil }

        var urlComponets = URLComponents(url: url, resolvingAgainstBaseURL: true)

        if let params = params {

            var queryItems: [URLQueryItem] = []

            params.forEach { (key: String, value: Any) in
                let valueString = String(describing: value)
                queryItems.append(URLQueryItem(name: key, value: valueString))
            }

            urlComponets?.queryItems = queryItems

            return urlComponets?.url

        }
        return urlComponets?.url
    }

    /// Encodes a dictionary into JSON data.
    ///
    /// - Parameter body: A dictionary containing data to be encoded into JSON.
    ///
    /// - Returns: JSON data representing the encoded dictionary, or `nil` if encoding fails.
    ///
    /// - Note:
    ///   This function attempts to encode the provided dictionary into JSON data. If the encoding is successful, the resulting JSON data is returned. If the input dictionary is not a valid JSON object or if encoding fails for any reason, `nil` is returned.
    internal func codingBody(body: [String: Any]) -> Data? {
        if JSONSerialization.isValidJSONObject(body) {
            return try? JSONSerialization.data(withJSONObject: body)
        }
        return nil
    }

    /// Decodes JSON data into a specified Codable type.
    ///
    /// - Parameters:
    ///   - data: JSON data to be decoded.
    ///
    /// - Returns: An instance of the specified Codable type, or `nil` if decoding fails.
    ///
    /// - Note:
    ///   This function attempts to decode JSON data into an instance of the specified Codable type (`T`). If the decoding is successful, an instance of `T` is returned. If decoding fails due to data format mismatches or other errors, `nil` is returned.
    ///
    /// - Warning:
    ///   Ensure that the provided Codable type (`T`) matches the structure of the JSON data to avoid decoding errors.
    internal func decodingRequest<T: Codable>(data: Data) -> T? {
        do {
            return try JSONDecoder().decode(T.self, from: data)
        } catch {
            return nil
        }
    }
}
