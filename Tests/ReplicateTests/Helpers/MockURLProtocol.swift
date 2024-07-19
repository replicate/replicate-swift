import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
        case "Bearer \(Self.validToken)":
            switch (request.httpMethod, request.url?.absoluteString) {
            case ("GET", "https://api.replicate.com/v1/account"?):
                statusCode = 200
                json = #"""
                    {
                      "type": "organization",
                      "username": "replicate",
                      "name": "Replicate",
                      "github_url": "https://github.com/replicate"
                    }
                  """#
            case ("GET", "https://api.replicate.com/v1/predictions"?):
                statusCode = 200
                json = #"""
                    {
                      "previous": null,
                      "next": "https://api.replicate.com/v1/predictions?cursor=cD0yMDIyLTAxLTIxKzIzJTNBMTglM0EyNC41MzAzNTclMkIwMCUzQTAw",
                      "results": [
                        {
                          "id": "ufawqhfynnddngldkgtslldrkq",
                          "model": "replicate/hello-world",
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
            case ("POST", "https://api.replicate.com/v1/predictions"?),
                 ("POST", "https://api.replicate.com/v1/deployments/replicate/deployment/predictions"?):

                if let body = request.json,
                   body["version"] as? String == "invalid"
                {
                    statusCode = 400
                    json = #"{ "detail" : "Invalid version" }"#
                } else {
                    statusCode = 201

                    json = #"""
                        {
                          "id": "ufawqhfynnddngldkgtslldrkq",
                          "model": "replicate/hello-world",
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
                }
            case ("POST", "https://api.replicate.com/v1/models/meta/llama-2-70b-chat/predictions"?):
                statusCode = 201
                json = #"""
                    {
                      "id": "heat2o3bzn3ahtr6bjfftvbaci",
                      "model": "meta/llama-2-70b-chat",
                      "version": "02e509c789964a7ea8736978a43525956ef40397be9033abf9fd2badfe68c9e3",
                      "input": {
                            "prompt": "Please write a haiku about llamas."
                      },
                      "logs": "",
                      "error": null,
                      "status": "starting",
                      "created_at": "2023-11-27T13:35:45.99397566Z",
                      "urls": {
                            "cancel": "https://api.replicate.com/v1/predictions/heat2o3bzn3ahtr6bjfftvbaci/cancel",
                            "get": "https://api.replicate.com/v1/predictions/heat2o3bzn3ahtr6bjfftvbaci"
                      }
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq"?):
                statusCode = 200
                json = #"""
                    {
                      "id": "ufawqhfynnddngldkgtslldrkq",
                      "model": "replicate/hello-world",
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
            case ("GET", "https://api.replicate.com/v1/predictions/heat2o3bzn3ahtr6bjfftvbaci"?):
                statusCode = 200
                json = #"""
                    {
                      "id": "heat2o3bzn3ahtr6bjfftvbaci",
                      "model": "meta/llama-2-70b-chat",
                      "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                      "urls": {
                        "get": "https://api.replicate.com/v1/predictions/heat2o3bzn3ahtr6bjfftvbaci",
                        "cancel": "https://api.replicate.com/v1/predictions/heat2o3bzn3ahtr6bjfftvbaci/cancel"
                      },
                      "created_at": "2022-04-26T22:13:06.224088Z",
                      "completed_at": "2022-04-26T22:15:06.224088Z",
                      "source": "web",
                      "status": "succeeded",
                      "input": {
                          "prompt": "Please write a haiku about llamas."
                      },
                      "output": ["I'm sorry, I'm afraid I can't do that"],
                      "error": null,
                      "logs": "",
                      "metrics": {
                        "predict_time": 1.0
                      }
                    }
                """#
            case ("POST", "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq/cancel"?):
                statusCode = 200
                json = #"""
                    {
                      "id": "ufawqhfynnddngldkgtslldrkq",
                      "model": "replicate/hello-world",
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
            case ("GET", "https://api.replicate.com/v1/hardware"?):
                statusCode = 200
                json = #"""
                    [
                      { "name": "CPU", "sku": "cpu" },
                      { "name": "Nvidia T4 GPU", "sku": "gpu-t4" },
                      { "name": "Nvidia A40 GPU", "sku": "gpu-a40-small" },
                      { "name": "Nvidia A40 (Large) GPU", "sku": "gpu-a40-large" }
                    ]
                """#
            case ("GET", "https://api.replicate.com/v1/models"?):
                statusCode = 200
                json = #"""
                {
                  "next": null,
                  "previous": null,
                  "results": [
                    {
                      "url": "https://replicate.com/replicate/hello-world",
                      "owner": "replicate",
                      "name": "hello-world",
                      "description": "A tiny model that says hello",
                      "visibility": "public",
                      "github_url": "https://github.com/replicate/cog-examples",
                      "paper_url": null,
                      "license_url": null,
                      "run_count": 930512,
                      "cover_image_url": "https://tjzk.replicate.delivery/models_models_cover_image/9c1f748e-a9fc-4cfd-a497-68262ee6151a/replicate-prediction-caujujsgrng7.png",
                      "default_example": {
                        "completed_at": "2022-04-26T19:30:10.926419Z",
                        "created_at": "2022-04-26T19:30:10.761396Z",
                        "error": null,
                        "id": "3s2vyrb3pfblrnyp2smdsxxjvu",
                        "input": {
                          "text": "Alice"
                        },
                        "logs": null,
                        "metrics": {
                          "predict_time": 2e-06
                        },
                        "output": "hello Alice",
                        "started_at": "2022-04-26T19:30:10.926417Z",
                        "status": "succeeded",
                        "urls": {
                          "get": "https://api.replicate.com/v1/predictions/3s2vyrb3pfblrnyp2smdsxxjvu",
                          "cancel": "https://api.replicate.com/v1/predictions/3s2vyrb3pfblrnyp2smdsxxjvu/cancel"
                        },
                        "model": "replicate/hello-world",
                        "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                        "webhook_completed": null
                      },
                      "latest_version": {
                        "id": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                        "created_at": "2022-04-26T19:29:04.418669Z",
                        "cog_version": "0.3.0",
                        "openapi_schema": {
                          "openapi": "3.1.0",
                          "components": {
                            "schemas": {
                              "Input": {
                                "type": "object",
                                "title": "Input",
                                "required": [
                                  "text"
                                ],
                                "properties": {
                                  "text": {
                                    "type": "string",
                                    "title": "Text",
                                    "x-order": 0,
                                    "description": "Text to prefix with 'hello '"
                                  }
                                }
                              },
                              "Output": {
                                "type": "string",
                                "title": "Output"
                              }
                            }
                          }
                        }
                      }
                    }
                  ]
                }
                """#
            case ("QUERY", "https://api.replicate.com/v1/models"?):
                statusCode = 200
                json = #"""
                {
                  "next": null,
                  "previous": null,
                  "results": [
                    {
                      "url": "https://replicate.com/replicate/hello-world",
                      "owner": "replicate",
                      "name": "hello-world",
                      "description": "A tiny model that says hello",
                      "visibility": "public",
                      "github_url": "https://github.com/replicate/cog-examples",
                      "paper_url": null,
                      "license_url": null,
                      "run_count": 930512,
                      "cover_image_url": "https://tjzk.replicate.delivery/models_models_cover_image/9c1f748e-a9fc-4cfd-a497-68262ee6151a/replicate-prediction-caujujsgrng7.png",
                      "default_example": {
                        "completed_at": "2022-04-26T19:30:10.926419Z",
                        "created_at": "2022-04-26T19:30:10.761396Z",
                        "error": null,
                        "id": "3s2vyrb3pfblrnyp2smdsxxjvu",
                        "input": {
                          "text": "Alice"
                        },
                        "logs": null,
                        "metrics": {
                          "predict_time": 2e-06
                        },
                        "output": "hello Alice",
                        "started_at": "2022-04-26T19:30:10.926417Z",
                        "status": "succeeded",
                        "urls": {
                          "get": "https://api.replicate.com/v1/predictions/3s2vyrb3pfblrnyp2smdsxxjvu",
                          "cancel": "https://api.replicate.com/v1/predictions/3s2vyrb3pfblrnyp2smdsxxjvu/cancel"
                        },
                        "model": "replicate/hello-world",
                        "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                        "webhook_completed": null
                      },
                      "latest_version": {
                        "id": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                        "created_at": "2022-04-26T19:29:04.418669Z",
                        "cog_version": "0.3.0",
                        "openapi_schema": {
                          "openapi": "3.1.0",
                          "components": {
                            "schemas": {
                              "Input": {
                                "type": "object",
                                "title": "Input",
                                "required": [
                                  "text"
                                ],
                                "properties": {
                                  "text": {
                                    "type": "string",
                                    "title": "Text",
                                    "x-order": 0,
                                    "description": "Text to prefix with 'hello '"
                                  }
                                }
                              },
                              "Output": {
                                "type": "string",
                                "title": "Output"
                              }
                            }
                          }
                        }
                      }
                    }
                  ]
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
                      "run_count": 930512,
                      "cover_image_url": "https://tjzk.replicate.delivery/models_models_cover_image/9c1f748e-a9fc-4cfd-a497-68262ee6151a/replicate-prediction-caujujsgrng7.png",
                      "default_example": {
                        "completed_at": "2022-04-26T19:30:10.926419Z",
                        "created_at": "2022-04-26T19:30:10.761396Z",
                        "error": null,
                        "id": "3s2vyrb3pfblrnyp2smdsxxjvu",
                        "input": {
                          "text": "Alice"
                        },
                        "logs": null,
                        "metrics": {
                          "predict_time": 2e-06
                        },
                        "output": "hello Alice",
                        "started_at": "2022-04-26T19:30:10.926417Z",
                        "status": "succeeded",
                        "urls": {
                          "get": "https://api.replicate.com/v1/predictions/3s2vyrb3pfblrnyp2smdsxxjvu",
                          "cancel": "https://api.replicate.com/v1/predictions/3s2vyrb3pfblrnyp2smdsxxjvu/cancel"
                        },
                        "model": "replicate/hello-world",
                        "version": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                        "webhook_completed": null
                      },
                      "latest_version": {
                        "id": "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa",
                        "created_at": "2022-04-26T19:29:04.418669Z",
                        "cog_version": "0.3.0",
                        "openapi_schema": {
                          "info": {
                            "title": "Cog",
                            "version": "0.1.0"
                          },
                          "paths": {
                            "/": {
                              "get": {
                                "summary": "Root",
                                "responses": {
                                  "200": {
                                    "content": {
                                      "application/json": {
                                        "schema": {}
                                      }
                                    },
                                    "description": "Successful Response"
                                  }
                                },
                                "operationId": "root__get"
                              }
                            },
                            "/predictions": {
                              "post": {
                                "summary": "Predict",
                                "responses": {
                                  "200": {
                                    "content": {
                                      "application/json": {
                                        "schema": {
                                          "$ref": "#/components/schemas/Response"
                                        }
                                      }
                                    },
                                    "description": "Successful Response"
                                  },
                                  "422": {
                                    "content": {
                                      "application/json": {
                                        "schema": {
                                          "$ref": "#/components/schemas/HTTPValidationError"
                                        }
                                      }
                                    },
                                    "description": "Validation Error"
                                  }
                                },
                                "description": "Run a single prediction on the model",
                                "operationId": "predict_predictions_post",
                                "requestBody": {
                                  "content": {
                                    "application/json": {
                                      "schema": {
                                        "$ref": "#/components/schemas/Request"
                                      }
                                    }
                                  }
                                }
                              }
                            }
                          },
                          "openapi": "3.0.2",
                          "components": {
                            "schemas": {
                              "Input": {
                                "type": "object",
                                "title": "Input",
                                "required": [
                                  "text"
                                ],
                                "properties": {
                                  "text": {
                                    "type": "string",
                                    "title": "Text",
                                    "x-order": 0,
                                    "description": "Text to prefix with 'hello '"
                                  }
                                }
                              },
                              "Output": {
                                "type": "string",
                                "title": "Output"
                              },
                              "Status": {
                                "enum": [
                                  "processing",
                                  "succeeded",
                                  "failed"
                                ],
                                "type": "string",
                                "title": "Status",
                                "description": "An enumeration."
                              },
                              "Request": {
                                "type": "object",
                                "title": "Request",
                                "properties": {
                                  "input": {
                                    "$ref": "#/components/schemas/Input"
                                  },
                                  "output_file_prefix": {
                                    "type": "string",
                                    "title": "Output File Prefix"
                                  }
                                },
                                "description": "The request body for a prediction"
                              },
                              "Response": {
                                "type": "object",
                                "title": "Response",
                                "required": [
                                  "status"
                                ],
                                "properties": {
                                  "error": {
                                    "type": "string",
                                    "title": "Error"
                                  },
                                  "output": {
                                    "$ref": "#/components/schemas/Output"
                                  },
                                  "status": {
                                    "$ref": "#/components/schemas/Status"
                                  }
                                },
                                "description": "The response body for a prediction"
                              },
                              "ValidationError": {
                                "type": "object",
                                "title": "ValidationError",
                                "required": [
                                  "loc",
                                  "msg",
                                  "type"
                                ],
                                "properties": {
                                  "loc": {
                                    "type": "array",
                                    "items": {
                                      "anyOf": [
                                        {
                                          "type": "string"
                                        },
                                        {
                                          "type": "integer"
                                        }
                                      ]
                                    },
                                    "title": "Location"
                                  },
                                  "msg": {
                                    "type": "string",
                                    "title": "Message"
                                  },
                                  "type": {
                                    "type": "string",
                                    "title": "Error Type"
                                  }
                                }
                              },
                              "HTTPValidationError": {
                                "type": "object",
                                "title": "HTTPValidationError",
                                "properties": {
                                  "detail": {
                                    "type": "array",
                                    "items": {
                                      "$ref": "#/components/schemas/ValidationError"
                                    },
                                    "title": "Detail"
                                  }
                                }
                              }
                            }
                          }
                        }
                      }
                    }
                """#
            case ("POST", "https://api.replicate.com/v1/models"?):
                statusCode = 200
                json = #"""
                    {
                      "url": "https://replicate.com/replicate/hello-world",
                      "owner": "replicate",
                      "name": "hello-world",
                      "description": "A tiny model that says hello",
                      "visibility": "public",
                      "github_url": null,
                      "paper_url": null,
                      "license_url": null,
                      "run_count": 0,
                      "cover_image_url": null,
                      "default_example": null
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
            case ("GET", "https://api.replicate.com/v1/collections"?):
                statusCode = 200
                json = #"""
                    {
                      "results": [
                        {
                          "name": "Super resolution",
                          "slug": "super-resolution",
                          "description": "Upscaling models that create high-quality images from low-quality images.",
                        }
                      ],
                      "next": null,
                      "previous": null
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/collections/super-resolution"?),
                ("GET", "https://v1.replicate.proxy/collections/super-resolution"?):
                statusCode = 200
                json = #"""
                    {
                      "name": "Super resolution",
                      "slug": "super-resolution",
                      "description": "Upscaling models that create high-quality images from low-quality images.",
                      "models": []
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/trainings"?):
                statusCode = 200
                json = #"""
                    {
                      "previous": null,
                      "next": "https://api.replicate.com/v1/trainings?cursor=g5FWfcbO0EdVeR27rkXr0Z6tI0MjrW34ZejxnGzDeND3phpWWsyMGCQD",
                      "results": [
                        {
                          "id": "zz4ibbonubfz7carwiefibzgga",
                          "model": "replicate/hello-world",
                          "version": "4a056052b8b98f6db8d011a450abbcd09a408ec9280c29f22d3538af1099646a",
                          "urls": {
                            "get": "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga",
                            "cancel": "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga/cancel"
                          },
                          "created_at": "2022-04-26T22:13:06.224088Z",
                          "completed_at": "2022-04-26T22:13:06.580379Z",
                          "source": "web",
                          "status": "starting",
                          "input": {
                            "data": "..."
                          },
                          "output": null,
                          "error": null,
                          "logs": null,
                          "metrics": {}
                        }
                      ]
                    }
                """#
            case ("POST", "https://api.replicate.com/v1/models/example/base/versions/4a056052b8b98f6db8d011a450abbcd09a408ec9280c29f22d3538af1099646a/trainings"?):
                statusCode = 201

                json = #"""
                    {
                      "id": "zz4ibbonubfz7carwiefibzgga",
                      "version": "4a056052b8b98f6db8d011a450abbcd09a408ec9280c29f22d3538af1099646a",
                      "urls": {
                        "get": "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga",
                        "cancel": "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga/cancel"
                      },
                      "created_at": "2022-04-26T22:13:06.224088Z",
                      "completed_at": "2022-04-26T22:13:06.580379Z",
                      "source": "web",
                      "status": "starting",
                      "input": {
                        "data": "..."
                      },
                      "output": null,
                      "error": null,
                      "logs": null,
                      "metrics": {}
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga"?):
                statusCode = 200
                json = #"""
                    {
                      "id": "zz4ibbonubfz7carwiefibzgga",
                      "model": "replicate/hello-world",
                      "version": "4a056052b8b98f6db8d011a450abbcd09a408ec9280c29f22d3538af1099646a",
                      "urls": {
                        "get": "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga",
                        "cancel": "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga/cancel"
                      },
                      "created_at": "2023-04-23T22:13:06.224088Z",
                      "completed_at": "2023-04-23T22:15:06.224088Z",
                      "source": "web",
                      "status": "succeeded",
                      "input": {
                        "data": "..."
                      },
                      "output": {
                        "version": "b024d792ace1084d2504b2fc3012f013cef3b99842add1e7d82d2136ea1b78ac",
                        "weights": "https://relicate.delivery/example-weights.tar.gz"
                      },
                      "error": null,
                      "logs": "",
                      "metrics": {}
                    }
                """#
            case ("POST", "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga/cancel"?):
                statusCode = 200
                json = #"""
                    {
                      "id": "zz4ibbonubfz7carwiefibzgga",
                      "model": "replicate/hello-world",
                      "version": "4a056052b8b98f6db8d011a450abbcd09a408ec9280c29f22d3538af1099646a",
                      "urls": {
                        "get": "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga",
                        "cancel": "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga/cancel"
                      },
                      "created_at": "2023-04-23T22:13:06.224088Z",
                      "completed_at": "2023-04-23T22:15:06.224088Z",
                      "source": "web",
                      "status": "canceled",
                      "input": {
                        "data": "..."
                      },
                      "output": null,
                      "error": null,
                      "logs": "",
                      "metrics": {}
                    }
                """#
            case ("GET", "https://api.replicate.com/v1/deployments/replicate/my-app-image-generator"?):
                statusCode = 200
                json = #"""
                {
                  "owner": "replicate",
                  "name": "my-app-image-generator",
                  "current_release": {
                    "number": 1,
                    "model": "stability-ai/sdxl",
                    "version": "da77bc59ee60423279fd632efb4795ab731d9e3ca9705ef3341091fb989b7eaf",
                    "created_at": "2024-02-15T16:32:57.018467Z",
                    "created_by": {
                      "type": "organization",
                      "username": "replicate",
                      "name": "Replicate, Inc.",
                      "github_url": "https://github.com/replicate",
                    },
                    "configuration": {
                      "hardware": "gpu-t4",
                      "scaling": {
                        "min_instances": 1,
                        "max_instances": 5
                      }
                    }
                  }
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

    static var invalid: Client {
        return Client(token: "<invalid>").mocked
    }

    static var unauthenticated: Client {
        return Client(token: "").mocked
    }

    var mocked: Self {
        let configuration = session.configuration
        configuration.protocolClasses = [MockURLProtocol.self]
        session = URLSession(configuration: configuration)
        return self
    }
}

private extension URLRequest {
    var json: [String: Any]? {
        var data = httpBody
        if let stream = httpBodyStream {
            let bufferSize = 1024
            data = Data()
            stream.open()
            
            while stream.hasBytesAvailable {
                var buffer = [UInt8](repeating: 0, count: bufferSize)
                let bytesRead = stream.read(&buffer, maxLength: bufferSize)
                if bytesRead > 0 {
                    data?.append(buffer, count: bytesRead)
                } else {
                    break
                }
            }
        }
        
        guard let data = data else { return nil }
        return try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
    }
}
