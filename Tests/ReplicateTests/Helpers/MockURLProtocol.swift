import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

import AnyCodable
@testable import Replicate

class MockURLProtocol: URLProtocol {
    static let validToken = "<valid>"

    override class func canInit(with task: URLSessionTask) -> Bool {
        return true
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        let statusCode: Int
        let json: String

        switch request.value(forHTTPHeaderField: "Authorization") {
        case "Token \(Self.validToken)":
            switch (request.httpMethod, request.url?.absoluteString) {
            case ("GET", "https://api.replicate.com/v1/predictions"?):
                statusCode = 200
                json = #"""
                    {
                      "previous": null,
                      "next": "https://api.replicate.com/v1/predictions?cursor=cD0yMDIyLTAxLTIxKzIzJTNBMTglM0EyNC41MzAzNTclMkIwMCUzQTAw",
                      "results": [
                        {
                          "id": "ufawqhfynnddngldkgtslldrkq",
                          "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                          "urls": {
                            "get": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq",
                            "cancel": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq/cancel"
                          },
                          "created_at": "2022-04-26T22:13:06.224088Z",
                          "completed_at": "2022-04-26T22:13:06.580379Z",
                          "source": "web",
                          "status": "starting",
                          "input": {
                            "text": "Alice"
                          },
                          "output": null,
                          "error": null,
                          "logs": null,
                          "metrics": {}
                        }
                      ]
                    }
                """#
            case ("POST", "https://api.replicate.com/v1/predictions"?):
                statusCode = 201

                json = #"""
                    {
                      "id": "ufawqhfynnddngldkgtslldrkq",
                      "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                      "urls": {
                        "get": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq",
                        "cancel": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq/cancel"
                      },
                      "created_at": "2022-04-26T22:13:06.224088Z",
                      "completed_at": "2022-04-26T22:13:06.580379Z",
                      "source": "web",
                      "status": "starting",
                      "input": {
                        "text": "Alice"
                      },
                      "output": null,
                      "error": null,
                      "logs": null,
                      "metrics": {}
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq"?):
                statusCode = 200
                json = #"""
                    {
                      "id": "ufawqhfynnddngldkgtslldrkq",
                      "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                      "urls": {
                        "get": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq",
                        "cancel": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq/cancel"
                      },
                      "created_at": "2022-04-26T22:13:06.224088Z",
                      "completed_at": "2022-04-26T22:15:06.224088Z",
                      "source": "web",
                      "status": "succeeded",
                      "input": {
                        "text": "Alice"
                      },
                      "output": ["Hello, Alice!"],
                      "error": null,
                      "logs": "",
                      "metrics": {
                        "predict_time": 10.0
                      }
                    }
                """#
            case ("POST", "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq/cancel"?):
                statusCode = 200
                json = #"""
                    {
                      "id": "ufawqhfynnddngldkgtslldrkq",
                      "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                      "urls": {
                        "get": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq",
                        "cancel": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq/cancel"
                      },
                      "created_at": "2022-04-26T22:13:06.224088Z",
                      "completed_at": "2022-04-26T22:15:06.224088Z",
                      "source": "web",
                      "status": "canceled",
                      "input": {
                        "text": "Alice"
                      },
                      "output": null,
                      "error": null,
                      "logs": "",
                      "metrics": {}
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/models/replicate/hello-world"?):
                statusCode = 200
                json = #"""
                    {
                      "url": "https://replicate.com/replicate/hello-world",
                      "owner": "replicate",
                      "name": "hello-world",
                      "description": "A tiny model that says hello",
                      "visibility": "public",
                      "github_url": "https://github.com/replicate/cog-examples",
                      "paper_url": null,
                      "license_url": null,
                      "latest_version": null
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/models/replicate/hello-world/versions"?):
                statusCode = 200
                json = #"""
                    {
                      "previous": null,
                      "next": null,
                      "results": [
                        {
                          "id": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                          "created_at": "2022-04-26T19:29:04.418669Z",
                          "cog_version": "0.3.0",
                          "openapi_schema": {}
                        },
                        {
                          "id": "e2e8c39e0f77177381177ba8c4025421ec2d7e7d3c389a9b3d364f8de560024f",
                          "created_at": "2022-03-21T13:01:04.418669Z",
                          "cog_version": "0.3.0",
                          "openapi_schema": {}
                        }
                      ]
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/models/replicate/hello-world/versions/5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"?):
                statusCode = 200
                json = #"""
                    {
                        "id": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                        "created_at": "2022-04-26T19:29:04.418669Z",
                        "cog_version": "0.3.0",
                        "openapi_schema": {}
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/collections/super-resolution"?):
                statusCode = 200
                json = #"""
                    {
                      "name": "Super resolution",
                      "slug": "super-resolution",
                      "description": "Upscaling models that create high-quality images from low-quality images.",
                      "models": []
                    }
                """#
            default:
                client?.urlProtocol(self, didFailWithError: URLError(.badURL))
                return
            }
        case nil:
            statusCode = 401
            json = #"""
                { "detail" : "Authentication credentials were not provided." }
            """#
        default:
            statusCode = 401
            json = #"""
                { "detail" : "Invalid token." }
            """#
        }

        guard let data = json.data(using: .utf8),
              let response = HTTPURLResponse(url: request.url!,
                                             statusCode: statusCode,
                                             httpVersion: "1.1",
                                             headerFields: [
                                                "Content-Type": "application/json"
                                             ])
        else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}

// MARK: -

extension Client {
    static var valid: Client {
        return Client(token: MockURLProtocol.validToken).mocked
    }

    static var unauthenticated: Client {
        return Client(token: "").mocked
    }

    private var mocked: Self {
        let configuration = session.configuration
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        return self
    }
}

