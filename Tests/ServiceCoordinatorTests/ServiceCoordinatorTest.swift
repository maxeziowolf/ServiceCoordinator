//
//  ServiceCoordinatorTest.swift
//  PokemonMasterTests
//
//  Created by Maximiliano Ovando Ramírez on 22/06/23.
//

import XCTest
@testable import ServiceCoordinator

final class ServiceCoordinatorTest: XCTestCase {

    override func setUp() {
        
        // Iniciar el mock de servicios
        MockURLProtocol.error = nil
        MockURLProtocol.requestHandler = nil
        URLProtocol.registerClass(MockURLProtocol.self)
        ServiceCoordinator.shared.removeConfiguration()
    }

    func testAddConfiguration() {
        
        ServiceCoordinator.shared.setConfiguration(
            timeOutRequest: 10,
            timeOutResourse: 20,
            allowsCellular: false,
            urlCache: URLCache.shared,
            connectionProxy: ["ProxyKey": "ProxyValue"],
            httpCookieStorage: HTTPCookieStorage.shared,
            httpAdditionalHeaders: ["HeaderKey": "HeaderValue"],
            httpMaximumConnectionsPerHost: 3,
            isDiscretionary: true,
            networkServiceType: .background
        )
        
        let configuration = ServiceCoordinator.shared.getConfiguration()
        
        // Verifica que la instancia de URLSessionConfiguration se haya creado correctamente
        XCTAssertNotNil(configuration)
        
        // Verifica que las propiedades de URLSessionConfiguration se hayan configurado correctamente
        XCTAssertEqual(configuration?.timeoutIntervalForRequest, 10)
        XCTAssertEqual(configuration?.timeoutIntervalForResource, 20)
        XCTAssertFalse(configuration?.allowsCellularAccess ?? true)
        XCTAssertEqual(configuration?.connectionProxyDictionary as? [String: String], ["ProxyKey": "ProxyValue"])
        XCTAssertNotNil(configuration?.urlCache)
        XCTAssertEqual(configuration?.httpCookieStorage, HTTPCookieStorage.shared)
        XCTAssertEqual(configuration?.httpAdditionalHeaders as? [String: String], ["HeaderKey": "HeaderValue"])
        XCTAssertEqual(configuration?.httpMaximumConnectionsPerHost, 3)
        XCTAssertTrue(configuration?.isDiscretionary ?? true)
        XCTAssertEqual(configuration?.networkServiceType, .background)
    }

    func testRequestWithConfiguration() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 100 a 199")

        ServiceCoordinator.shared.setConfiguration(
            timeOutRequest: 10,
            timeOutResourse: 20,
            allowsCellular: false,
            urlCache: URLCache.shared,
            connectionProxy: ["ProxyKey": "ProxyValue"],
            httpCookieStorage: HTTPCookieStorage.shared,
            httpAdditionalHeaders: ["HeaderKey": "HeaderValue"],
            httpMaximumConnectionsPerHost: 3,
            isDiscretionary: true,
            networkServiceType: .background,
            urlProtocol: MockURLProtocol.self
        )

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 100,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!
            return(response, nil)
        }

        Task {
            let response: ServiceStatus<[MockModel]?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar informacion. \(String(describing: data))")
            case .failed(error: let error):
                XCTFail("No debio regresar este error \(error)")
            case .information(code: let code):
                XCTAssertEqual(code, 100, "El error no es el correcto")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testInvalidURL() {
        let invalidURL = "Esto no es una url valida"
        let errorExpected = XCTestExpectation(description: "URL Invalid")

        MockURLProtocol.requestHandler = { _ in
            let response = HTTPURLResponse(
                url: URL(string: "https://example.com")!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: ["Content-Type": "aplication/json"])!

            return(response, nil)
        }
        
        Task {
            let response: ServiceStatus<Data?> = await ServiceCoordinator.shared.sendRequest(url: invalidURL)
            
            switch response {
            case .success(data: let data):
                XCTFail("Debió votar un error de URL Invalida y regreso una de \(data?.toString() ?? "vacio")")
            case .failed(error: let error):
                XCTAssertEqual(error, NetworkError.invalidURL, "Debió votar un error de URL Invalida")
            case .information(code: let code):
                XCTFail("Debió votar un error de URL Invalida y salio con error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testSendRequestWithHeaderFields() {
        let url = "https://example.com"
        let headers = ["auth": "TestAuth"]
        let errorExpected = XCTestExpectation(description: "Request with Parameters")

        MockURLProtocol.requestHandler = { response in
            XCTAssertEqual(response.allHTTPHeaderFields, headers, "La cabeceras deben de ser iguales")
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!

            let jsonData =
                  """
                  [
                      {
                          "firstName": "Lee",
                          "lastName": "Burrows"
                      },
                      {
                          "firstName": "Dolly",
                          "lastName": "Burrows"
                      }
                  ]
                  """

            let data = jsonData.data(using: .utf8)

            return(response, data)
        }
        
        Task {
            let response: ServiceStatus<Data?> = await ServiceCoordinator.shared.sendRequest(url: url, headerFields: headers)
            
            switch response {
            case .success(data: let data):
                XCTAssertNotNil(data, "debio regresar informacion.")
            case .failed(error: let error):
                XCTFail("No debió votar un error \(error)")
            case .information(code: let code):
                XCTFail("No debió votar un error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testSendRequestWithBody() {
        let url = "http://example.com"
        let body = ["body": "TestBody"]
        let errorExpected = XCTestExpectation(description: "Resquest con body")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!

            let jsonData =
                  """
                  [
                      {
                          "firstName": "Lee",
                          "lastName": "Burrows"
                      },
                      {
                          "firstName": "Dolly",
                          "lastName": "Burrows"
                      }
                  ]
                  """

            let data = jsonData.data(using: .utf8)

            return(response, data)
        }
        
        Task {
            let response: ServiceStatus<[MockModel]?> = await ServiceCoordinator.shared.sendRequest(url: url, httpMethod: .post, body: body)
            
            switch response {
            case .success(data: let data):
                XCTAssertNotNil(data, "debio regresar informacion.")
            case .failed(error: let error):
                XCTFail("Debió votar un error de URL Invalida y salio con error \(error)")
            case .information(code: let code):
                XCTFail("Debió votar un error de URL Invalida y salio con error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithError() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Response con error")
        let error = NSError(domain: "Error para pruebas", code: -99)
        let validError = NetworkError.other(message: error.localizedDescription)

        MockURLProtocol.error = error
        
        Task {
            let response: ServiceStatus<[MockModel]?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("Debió dar un error personalizado, pero regreso la siguiente informacion\(String(describing: data))")
            case .failed(error: let error):
                XCTAssertEqual(error.localizedDescription, validError.localizedDescription, "Los errores no conciden con el probocado")
            case .information(code: let code):
                XCTFail("Debió dar un error personalizado\(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode100To200() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 100 a 199")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 100,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!
            return(response, nil)
        }

        Task {
            let response: ServiceStatus<[MockModel]?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar informacion. \(String(describing: data))")
            case .failed(error: let error):
                XCTFail("No debio regresar este error \(error)")
            case .information(code: let code):
                XCTAssertEqual(code, 100, "El error no es el correcto")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode200WithCorrectBody() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 200 a 299")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!

            let jsonData =
                  """
                  [
                      {
                          "firstName": "Lee",
                          "lastName": "Burrows"
                      },
                      {
                          "firstName": "Dolly",
                          "lastName": "Burrows"
                      }
                  ]
                  """

            let data = jsonData.data(using: .utf8)

            return(response, data)
        }

        Task {
            let response: ServiceStatus<[MockModel]?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTAssertNotNil(data, "Debio regresar ingormacion.")
            case .failed(error: let error):
                XCTFail("No debio regresar este error \(error)")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode200WithData() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 200 a 299")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!

            let jsonData =
                  """
                  [
                      {
                          "firstName": "Lee",
                          "lastName": "Burrows"
                      },
                      {
                          "firstName": "Dolly",
                          "lastName": "Burrows"
                      }
                  ]
                  """

            let data = jsonData.data(using: .utf8)

            return(response, data)
        }

        Task {
            let response: ServiceStatus<Data?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTAssertNotNil(data, "Debio regresar ingormacion.")
            case .failed(error: let error):
                XCTFail("No debio regresar este error \(error)")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode200WithIncorrectBody() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 200 a 299")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!

            let jsonData =
                  """
                  [
                      {
                          "firstName": "Lee",
                          "lastName": 0
                      },
                      {
                          "firstName": "Dolly",
                          "lastName": "Burrows"
                      }
                  ]
                  """

            let data = jsonData.data(using: .utf8)

            return(response, data)
        }

        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar este informacion \(String(describing: data))")
            case .failed(error: let error):
                XCTAssertEqual(error, .decodingError, "Regreso otro error diferente")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode200WithoutBody() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 200 a 299")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 200,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!

            return(response, nil)
        }

        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar este informacion \(String(describing: data))")
            case .failed(error: let error):
                XCTAssertEqual(error, .invalidResponse, "Regreso otro error diferente")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode201to204WithoutBody() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 200 a 299")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 201,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!

            return(response, nil)
        }

        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTAssertNil(data,"No debio regresar este informacion \(String(describing: data))")
            case .failed(error: let error):
                XCTFail("No debio regresar este error \(error)")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode300To400() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 100 a 199")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 300,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!
            return(response, nil)
        }
        
        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar informacion. \(String(describing: data))")
            case .failed(error: let error):
                XCTFail("No debio regresar informacion. \(error)")
            case .information(code: let code):
                XCTAssertNotNil(code, "Se quiere redireccionar al usuario a una nueva url")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode400() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 100 a 199")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 400,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!
            return(response, nil)
        }
        
        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar informacion. \(String(describing: data))")
            case .failed(error: let error):
                XCTAssertEqual(error, .badRequest, "El error no es el correcto")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode401() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 100 a 199")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 401,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!
            return(response, nil)
        }
        
        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar informacion. \(String(describing: data))")
            case .failed(error: let error):
                XCTAssertEqual(error, .unauthorized, "El error no es el correcto")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode404() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 100 a 199")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 404,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!
            return(response, nil)
        }
        
        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar informacion. \(String(describing: data))")
            case .failed(error: let error):
                XCTAssertEqual(error, .notFound, "El error no es el correcto")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCode500To600() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 100 a 199")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 500,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!
            return(response, nil)
        }
        
        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar informacion. \(String(describing: data))")
            case .failed(error: let error):
                XCTAssertEqual(error, .serverError(statusCode: 500), "El error no es el correcto")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testResponseWithCodeOutRange() {
        let url = "http://example.com"
        let errorExpected = XCTestExpectation(description: "Resquest con codigo 100 a 199")

        MockURLProtocol.requestHandler = { response in
            let response = HTTPURLResponse(
                url: response.url!,
                statusCode: 1000,
                httpVersion: nil,
                headerFields: response.allHTTPHeaderFields)!
            return(response, nil)
        }

        Task {
            let response: ServiceStatus<MockModel?> = await ServiceCoordinator.shared.sendRequest(url: url)
            
            switch response {
            case .success(data: let data):
                XCTFail("No debio regresar informacion. \(String(describing: data))")
            case .failed(error: let error):
                XCTAssertEqual(error, .otherCode(code: 1000), "El error no es el correcto")
            case .information(code: let code):
                XCTFail("No debio regresar este error \(code)")
            }
            errorExpected.fulfill()
        }

        wait(for: [errorExpected], timeout: 5.0)
    }

    func testURLIncorrect() {
        let badURL = "https://prueba simple"

        let url = ServiceCoordinator.shared.getURL(url: badURL, parameters: nil)

        XCTAssertNil(url, "si obtuvo una url")
    }

    func testURLWithParams() {
        let correctURLWithParamas = "https://example.com?limit=100000"
        let baseURL = "https://example.com"
        let params: [String: Any] = ["limit": 100000]

        let url = ServiceCoordinator.shared.getURL(url: baseURL, parameters: params)

        XCTAssertEqual(correctURLWithParamas, url?.absoluteString, "Las URL no son iguales")
    }

    func testURLBasic() {
        let correctURLWithParamas = "https://example.com"
        let baseURL = "https://example.com"

        let url = ServiceCoordinator.shared.getURL(url: baseURL, parameters: nil)

        XCTAssertEqual(correctURLWithParamas, url?.absoluteString, "Las URL no son iguales")
    }

    func testCodingBody() {
        let invalidData = ["key": "prueba"]

        let data = ServiceCoordinator.shared.codingBody(body: invalidData)

        XCTAssertNotNil(data, "Fallo al codificar algo correcto")
    }

    func testErrorInCodingBody() {
        let invalidData = ["key": MockModelEmpty()]

        let data = ServiceCoordinator.shared.codingBody(body: invalidData)

        XCTAssertNil(data, "Si codifico bien la funcion")
    }

    func testDecodingRequest() {
        let jsonData =
              """
              [
                  {
                      "firstName": "Lee",
                      "lastName": "Burrows"
                  },
                  {
                      "firstName": "Dolly",
                      "lastName": "Burrows"
                  }
              ]
              """

        let data = jsonData.data(using: .utf8)

        guard let data = data else {
            XCTFail("La data esta mal configurada")
            return
        }

        let object: [MockModel]? = ServiceCoordinator.shared.decodingRequest(data: data)

        XCTAssertNotNil(object, "No decodifico correctamente")
    }

    func testErrorInDecodingRequest() {
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

        let data = jsonData.data(using: .utf8)

        guard let data = data else {
            XCTFail("La data esta mal configurada")
            return
        }

        let object: MockModel? = ServiceCoordinator.shared.decodingRequest(data: data)

        XCTAssertNil(object, "Si decodifico correctamente")
    }

}
