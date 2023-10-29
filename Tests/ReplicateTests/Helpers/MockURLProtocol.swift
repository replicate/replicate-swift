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
            case ("POST", "https://api.replicate.com/v1/predictions"?),
                 ("POST", "https://api.replicate.com/v1/deployments/replicate/deployment/predictions"?):
                statusCode = 201
                
                if let body = request.json,
                   body["version"] as? String == "invalid"
                {
                    json = #"""
                        {
                          "id": "ufawqhfynnddngldkgtslldrkq",
                          "version": "invalid",
                          "urls": {
                            "get": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq",
                            "cancel": "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq/cancel"
                          },
                          "created_at": "2022-04-26T22:13:06.224088Z",
                          "completed_at": "2022-04-26T22:13:06.580379Z",
                          "source": "web",
                          "status": "failed",
                          "input": {
                            "text": "Alice"
                          },
                          "output": null,
                          "error": {
                            "detail": "Invalid version"
                          },
                          "logs": null,
                          "metrics": {}
                        }
                    """#
                } else {
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
                }
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
            case ("GET", "https://api.replicate.com/v1/models/prompthero/openjourney"?):
                statusCode = 200
                json = #"""
                    {
                      "url": "https://replicate.com/prompthero/openjourney",
                      "owner": "prompthero",
                      "name": "openjourney",
                      "description": "Stable Diffusion fine tuned on Midjourney v4 images.",
                      "visibility": "public",
                      "github_url": null,
                      "paper_url": "https://huggingface.co/prompthero/midjourney-v4-diffusion",
                      "license_url": null,
                      "run_count": 10831736,
                      "cover_image_url": "https://tjzk.replicate.delivery/models_models_cover_image/6584177a-6dbb-4de4-9858-9546ed9390eb/out-0.png",
                      "default_example": {
                        "completed_at": "2022-11-15T02:17:31Z",
                        "created_at": "2022-11-15T02:17:27.218186Z",
                        "error": "",
                        "id": "hnv34qbn5nc2fkhfgxa2nhe5ka",
                        "input": {
                          "seed": null,
                          "width": 512,
                          "height": 512,
                          "prompt": "mdjrny-v4 style portrait of female elf, intricate, elegant, highly detailed, digital painting, artstation, concept art, smooth, sharp focus, illustration, art by artgerm and greg rutkowski and alphonse mucha, 8k",
                          "num_outputs": 1,
                          "guidance_scale": "7",
                          "num_inference_steps": 50
                        },
                        "logs": null,
                        "metrics": {
                          "predict_time": 4
                        },
                        "output": [
                          "https://replicate.delivery/pbxt/LHh12rAtngYkItdmraLbWntEODUjeCI4g9wn9pXfiMO7iKAQA/out-0.png"
                        ],
                        "started_at": "2022-11-15T02:17:27Z",
                        "status": "succeeded",
                        "urls": {
                          "get": "https://api.replicate.com/v1/predictions/hnv34qbn5nc2fkhfgxa2nhe5ka",
                          "cancel": "https://api.replicate.com/v1/predictions/hnv34qbn5nc2fkhfgxa2nhe5ka/cancel"
                        },
                        "version": "9936c2001faa2194a261c01381f90e65261879985476014a0a37a334593a05eb",
                        "webhook_completed": null
                      },
                      "latest_version": {
                        "id": "ad59ca21177f9e217b9075e7300cf6e14f7e5b4505b87b9689dbd866e9768969",
                        "created_at": "2023-06-07T00:56:47.548252Z",
                        "cog_version": "0.7.2",
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
                                        "schema": {
                                          "title": "Response Root  Get"
                                        }
                                      }
                                    },
                                    "description": "Successful Response"
                                  }
                                },
                                "operationId": "root__get"
                              }
                            },
                            "/shutdown": {
                              "post": {
                                "summary": "Start Shutdown",
                                "responses": {
                                  "200": {
                                    "content": {
                                      "application/json": {
                                        "schema": {
                                          "title": "Response Start Shutdown Shutdown Post"
                                        }
                                      }
                                    },
                                    "description": "Successful Response"
                                  }
                                },
                                "operationId": "start_shutdown_shutdown_post"
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
                                          "$ref": "#/components/schemas/PredictionResponse"
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
                                "parameters": [
                                  {
                                    "in": "header",
                                    "name": "prefer",
                                    "schema": {
                                      "type": "string",
                                      "title": "Prefer"
                                    },
                                    "required": false
                                  }
                                ],
                                "description": "Run a single prediction on the model",
                                "operationId": "predict_predictions_post",
                                "requestBody": {
                                  "content": {
                                    "application/json": {
                                      "schema": {
                                        "$ref": "#/components/schemas/PredictionRequest"
                                      }
                                    }
                                  }
                                }
                              }
                            },
                            "/health-check": {
                              "get": {
                                "summary": "Healthcheck",
                                "responses": {
                                  "200": {
                                    "content": {
                                      "application/json": {
                                        "schema": {
                                          "title": "Response Healthcheck Health Check Get"
                                        }
                                      }
                                    },
                                    "description": "Successful Response"
                                  }
                                },
                                "operationId": "healthcheck_health_check_get"
                              }
                            },
                            "/predictions/{prediction_id}": {
                              "put": {
                                "summary": "Predict Idempotent",
                                "responses": {
                                  "200": {
                                    "content": {
                                      "application/json": {
                                        "schema": {
                                          "$ref": "#/components/schemas/PredictionResponse"
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
                                "parameters": [
                                  {
                                    "in": "path",
                                    "name": "prediction_id",
                                    "schema": {
                                      "type": "string",
                                      "title": "Prediction ID"
                                    },
                                    "required": true
                                  },
                                  {
                                    "in": "header",
                                    "name": "prefer",
                                    "schema": {
                                      "type": "string",
                                      "title": "Prefer"
                                    },
                                    "required": false
                                  }
                                ],
                                "description": "Run a single prediction on the model (idempotent creation).",
                                "operationId": "predict_idempotent_predictions__prediction_id__put",
                                "requestBody": {
                                  "content": {
                                    "application/json": {
                                      "schema": {
                                        "allOf": [
                                          {
                                            "$ref": "#/components/schemas/PredictionRequest"
                                          }
                                        ],
                                        "title": "Prediction Request"
                                      }
                                    }
                                  },
                                  "required": true
                                }
                              }
                            },
                            "/predictions/{prediction_id}/cancel": {
                              "post": {
                                "summary": "Cancel",
                                "responses": {
                                  "200": {
                                    "content": {
                                      "application/json": {
                                        "schema": {
                                          "title": "Response Cancel Predictions  Prediction Id  Cancel Post"
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
                                "parameters": [
                                  {
                                    "in": "path",
                                    "name": "prediction_id",
                                    "schema": {
                                      "type": "string",
                                      "title": "Prediction ID"
                                    },
                                    "required": true
                                  }
                                ],
                                "description": "Cancel a running prediction",
                                "operationId": "cancel_predictions__prediction_id__cancel_post"
                              }
                            }
                          },
                          "openapi": "3.0.2",
                          "components": {
                            "schemas": {
                              "Input": {
                                "type": "object",
                                "title": "Input",
                                "properties": {
                                  "mask": {
                                    "type": "string",
                                    "title": "Mask",
                                    "format": "uri",
                                    "x-order": 1,
                                    "description": "Optional Mask to use for legacy inpainting"
                                  },
                                  "seed": {
                                    "type": "integer",
                                    "title": "Seed",
                                    "x-order": 11,
                                    "description": "Random seed. Leave blank to randomize the seed"
                                  },
                                  "image": {
                                    "type": "string",
                                    "title": "Image",
                                    "format": "uri",
                                    "x-order": 0,
                                    "description": "Optional Image to use for img2img guidance"
                                  },
                                  "width": {
                                    "allOf": [
                                      {
                                        "$ref": "#/components/schemas/width"
                                      }
                                    ],
                                    "default": 512,
                                    "x-order": 4,
                                    "description": "Width of output image. Maximum size is 1024x768 or 768x1024 because of memory limits"
                                  },
                                  "height": {
                                    "allOf": [
                                      {
                                        "$ref": "#/components/schemas/height"
                                      }
                                    ],
                                    "default": 512,
                                    "x-order": 5,
                                    "description": "Height of output image. Maximum size is 1024x768 or 768x1024 because of memory limits"
                                  },
                                  "prompt": {
                                    "type": "string",
                                    "title": "Prompt",
                                    "default": "a photo of an astronaut riding a horse on mars",
                                    "x-order": 2,
                                    "description": "Input prompt"
                                  },
                                  "scheduler": {
                                    "allOf": [
                                      {
                                        "$ref": "#/components/schemas/scheduler"
                                      }
                                    ],
                                    "default": "DPMSolverMultistep",
                                    "x-order": 10,
                                    "description": "Choose a scheduler."
                                  },
                                  "num_outputs": {
                                    "type": "integer",
                                    "title": "Num Outputs",
                                    "default": 1,
                                    "maximum": 10,
                                    "minimum": 1,
                                    "x-order": 6,
                                    "description": "Number of images to output."
                                  },
                                  "guidance_scale": {
                                    "type": "number",
                                    "title": "Guidance Scale",
                                    "default": 7.5,
                                    "maximum": 20,
                                    "minimum": 1,
                                    "x-order": 8,
                                    "description": "Scale for classifier-free guidance"
                                  },
                                  "negative_prompt": {
                                    "type": "string",
                                    "title": "Negative Prompt",
                                    "x-order": 3,
                                    "description": "Specify things to not see in the output"
                                  },
                                  "prompt_strength": {
                                    "type": "number",
                                    "title": "Prompt Strength",
                                    "default": 0.8,
                                    "x-order": 9,
                                    "description": "Prompt strength when using init image. 1.0 corresponds to full destruction of information in init image"
                                  },
                                  "num_inference_steps": {
                                    "type": "integer",
                                    "title": "Num Inference Steps",
                                    "default": 50,
                                    "maximum": 500,
                                    "minimum": 1,
                                    "x-order": 7,
                                    "description": "Number of denoising steps"
                                  }
                                }
                              },
                              "width": {
                                "enum": [
                                  128,
                                  256,
                                  384,
                                  448,
                                  512,
                                  576,
                                  640,
                                  704,
                                  768,
                                  832,
                                  896,
                                  960,
                                  1024
                                ],
                                "type": "integer",
                                "title": "width",
                                "description": "An enumeration."
                              },
                              "Output": {
                                "type": "array",
                                "items": {
                                  "type": "string",
                                  "format": "uri"
                                },
                                "title": "Output",
                                "x-cog-array-type": "iterator"
                              },
                              "Status": {
                                "enum": [
                                  "starting",
                                  "processing",
                                  "succeeded",
                                  "canceled",
                                  "failed"
                                ],
                                "type": "string",
                                "title": "Status",
                                "description": "An enumeration."
                              },
                              "height": {
                                "enum": [
                                  128,
                                  256,
                                  384,
                                  448,
                                  512,
                                  576,
                                  640,
                                  704,
                                  768,
                                  832,
                                  896,
                                  960,
                                  1024
                                ],
                                "type": "integer",
                                "title": "height",
                                "description": "An enumeration."
                              },
                              "scheduler": {
                                "enum": [
                                  "DDIM",
                                  "DPMSolverMultistep",
                                  "HeunDiscrete",
                                  "K_EULER_ANCESTRAL",
                                  "K_EULER",
                                  "KLMS",
                                  "PNDM",
                                  "UniPCMultistep"
                                ],
                                "type": "string",
                                "title": "scheduler",
                                "description": "An enumeration."
                              },
                              "WebhookEvent": {
                                "enum": [
                                  "start",
                                  "output",
                                  "logs",
                                  "completed"
                                ],
                                "type": "string",
                                "title": "WebhookEvent",
                                "description": "An enumeration."
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
                              "PredictionRequest": {
                                "type": "object",
                                "title": "PredictionRequest",
                                "properties": {
                                  "id": {
                                    "type": "string",
                                    "title": "Id"
                                  },
                                  "input": {
                                    "$ref": "#/components/schemas/Input"
                                  },
                                  "webhook": {
                                    "type": "string",
                                    "title": "Webhook",
                                    "format": "uri",
                                    "maxLength": 65536,
                                    "minLength": 1
                                  },
                                  "created_at": {
                                    "type": "string",
                                    "title": "Created At",
                                    "format": "date-time"
                                  },
                                  "output_file_prefix": {
                                    "type": "string",
                                    "title": "Output File Prefix"
                                  },
                                  "webhook_events_filter": {
                                    "type": "array",
                                    "items": {
                                      "$ref": "#/components/schemas/WebhookEvent"
                                    },
                                    "default": [
                                      "output",
                                      "start",
                                      "completed",
                                      "logs"
                                    ],
                                    "uniqueItems": true
                                  }
                                }
                              },
                              "PredictionResponse": {
                                "type": "object",
                                "title": "PredictionResponse",
                                "properties": {
                                  "id": {
                                    "type": "string",
                                    "title": "Id"
                                  },
                                  "logs": {
                                    "type": "string",
                                    "title": "Logs",
                                    "default": ""
                                  },
                                  "error": {
                                    "type": "string",
                                    "title": "Error"
                                  },
                                  "input": {
                                    "$ref": "#/components/schemas/Input"
                                  },
                                  "output": {
                                    "$ref": "#/components/schemas/Output"
                                  },
                                  "status": {
                                    "$ref": "#/components/schemas/Status"
                                  },
                                  "metrics": {
                                    "type": "object",
                                    "title": "Metrics"
                                  },
                                  "version": {
                                    "type": "string",
                                    "title": "Version"
                                  },
                                  "created_at": {
                                    "type": "string",
                                    "title": "Created At",
                                    "format": "date-time"
                                  },
                                  "started_at": {
                                    "type": "string",
                                    "title": "Started At",
                                    "format": "date-time"
                                  },
                                  "completed_at": {
                                    "type": "string",
                                    "title": "Completed At",
                                    "format": "date-time"
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
            case ("POST", "https://api.replicate.com/v1/trainings"?):
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
