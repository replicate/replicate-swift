import XCTest
@testable import Replicate

final class ClientTests: XCTestCase {
    var client = Client.valid

    static override func setUp() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    func testRun() async throws {
        let identifier: Identifier = "test/example:5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
        let output = try await client.run(identifier, input: ["text": "Alice"])
        XCTAssertEqual(output, ["Hello, Alice!"])
    }

    func testRunWithInvalidVersion() async throws {
        let identifier: Identifier = "test/example:invalid"
        do {
            _ = try await client.run(identifier, input: ["text": "Alice"])
            XCTFail()
        } catch {
            XCTAssertEqual(error.localizedDescription, "Invalid version")
        }
    }

    func testCreatePrediction() async throws {
        let version: Model.Version.ID = "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
        let prediction = try await client.createPrediction(version: version, input: ["text": "Alice"])
        XCTAssertEqual(prediction.id, "ufawqhfynnddngldkgtslldrkq")
        XCTAssertEqual(prediction.versionID, version)
        XCTAssertEqual(prediction.status, .starting)
    }

    func testCreatePredictionUsingDeployment() async throws {
        let deployment: Deployment.ID = "replicate/deployment"
        let version: Model.Version.ID = "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
        let prediction = try await client.createPrediction(deployment: deployment, input: ["text": "Alice"])
        XCTAssertEqual(prediction.id, "ufawqhfynnddngldkgtslldrkq")
        XCTAssertEqual(prediction.versionID, version)
        XCTAssertEqual(prediction.status, .starting)
    }

    func testCreatePredictionWithInvalidVersion() async throws {
        let version: Model.Version.ID = "invalid"
        let prediction = try await client.createPrediction(version: version, input: ["text": "Alice"])
        XCTAssertEqual(prediction.status, .failed)
        XCTAssertEqual(prediction.error?.localizedDescription, "Invalid version")
    }

    func testCreatePredictionAndWait() async throws {
        let version: Model.Version.ID = "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
        var prediction = try await client.createPrediction(version: version, input: ["text": "Alice"])
        try await prediction.wait(with: client)
        XCTAssertEqual(prediction.id, "ufawqhfynnddngldkgtslldrkq")
        XCTAssertEqual(prediction.versionID, version)
        XCTAssertEqual(prediction.status, .succeeded)
    }

    func testGetPrediction() async throws {
        let prediction = try await client.getPrediction(id: "ufawqhfynnddngldkgtslldrkq")
        XCTAssertEqual(prediction.id, "ufawqhfynnddngldkgtslldrkq")
        XCTAssertEqual(prediction.versionID, "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa")
        XCTAssertEqual(prediction.source, .web)
        XCTAssertEqual(prediction.status, .succeeded)
        XCTAssertEqual(prediction.createdAt.timeIntervalSinceReferenceDate, 672703986.224, accuracy: 1)
        XCTAssertEqual(prediction.urls["cancel"]?.absoluteString, "https://api.replicate.com/v1/predictions/ufawqhfynnddngldkgtslldrkq/cancel")
    }

    func testCancelPrediction() async throws {
        let prediction = try await client.cancelPrediction(id: "ufawqhfynnddngldkgtslldrkq")
        XCTAssertEqual(prediction.id, "ufawqhfynnddngldkgtslldrkq")
    }

    func testGetPredictions() async throws {
        let predictions = try await client.listPredictions()
        XCTAssertNil(predictions.previous)
        XCTAssertEqual(predictions.next, "cD0yMDIyLTAxLTIxKzIzJTNBMTglM0EyNC41MzAzNTclMkIwMCUzQTAw")
        XCTAssertEqual(predictions.results.count, 1)
    }

    func testListModels() async throws {
        let models = try await client.listModels()
        XCTAssertEqual(models.results.count, 1)
        XCTAssertEqual(models.results.first?.owner, "replicate")
        XCTAssertEqual(models.results.first?.name, "hello-world")
    }

    func testGetModel() async throws {
        let model = try await client.getModel("replicate/hello-world")
        XCTAssertEqual(model.owner, "replicate")
        XCTAssertEqual(model.name, "hello-world")
    }

    func testGetModelVersions() async throws {
        let versions = try await client.listModelVersions("replicate/hello-world")
        XCTAssertNil(versions.previous)
        XCTAssertNil(versions.next)
        XCTAssertEqual(versions.results.count, 2)
        XCTAssertEqual(versions.results.first?.id, "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa")
    }

    func testGetModelVersion() async throws {
        let version = try await client.getModelVersion("replicate/hello-world", version: "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa")
        XCTAssertEqual(version.id, "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa")
    }

    func testListModelCollections() async throws {
        let collections = try await client.listModelCollections()
        XCTAssertEqual(collections.results.count, 1)

        XCTAssertEqual(collections.results.first?.slug, "super-resolution")
        XCTAssertEqual(collections.results.first?.models, nil)

        let collection = try await client.getModelCollection(collections.results.first!.slug)
        XCTAssertEqual(collection.slug, "super-resolution")
        XCTAssertEqual(collection.models, [])
    }

    func testGetModelCollection() async throws {
        let collection = try await client.getModelCollection("super-resolution")
        XCTAssertEqual(collection.slug, "super-resolution")
    }

    func testCreateTraining() async throws {
        let base: Model.ID = "example/base"
        let version: Model.Version.ID = "4a056052b8b98f6db8d011a450abbcd09a408ec9280c29f22d3538af1099646a"
        let destination: Model.ID = "my/fork"
        let training = try await client.createTraining(model: base, version: version, destination: destination, input: ["data": "..."])
        XCTAssertEqual(training.id, "zz4ibbonubfz7carwiefibzgga")
        XCTAssertEqual(training.versionID, version)
        XCTAssertEqual(training.status, .starting)
    }

    func testGetTraining() async throws {
        let training = try await client.getTraining(id: "zz4ibbonubfz7carwiefibzgga")
        XCTAssertEqual(training.id, "zz4ibbonubfz7carwiefibzgga")
        XCTAssertEqual(training.versionID, "4a056052b8b98f6db8d011a450abbcd09a408ec9280c29f22d3538af1099646a")
        XCTAssertEqual(training.source, .web)
        XCTAssertEqual(training.status, .succeeded)
        XCTAssertEqual(training.createdAt.timeIntervalSinceReferenceDate, 703980786.224, accuracy: 1)
        XCTAssertEqual(training.urls["cancel"]?.absoluteString, "https://api.replicate.com/v1/trainings/zz4ibbonubfz7carwiefibzgga/cancel")
    }

    func testCancelTraining() async throws {
        let training = try await client.cancelTraining(id: "zz4ibbonubfz7carwiefibzgga")
        XCTAssertEqual(training.id, "zz4ibbonubfz7carwiefibzgga")
    }

    func testGetTrainings() async throws {
        let trainings = try await client.listTrainings()
        XCTAssertNil(trainings.previous)
        XCTAssertEqual(trainings.next, "g5FWfcbO0EdVeR27rkXr0Z6tI0MjrW34ZejxnGzDeND3phpWWsyMGCQD")
        XCTAssertEqual(trainings.results.count, 1)
    }

    func testCustomBaseURL() async throws {
        let client = Client(baseURLString: "https://v1.replicate.proxy", token: MockURLProtocol.validToken).mocked
        let collection = try await client.getModelCollection("super-resolution")
        XCTAssertEqual(collection.slug, "super-resolution")
    }

    func testInvalidToken() async throws {
        do {
            let _ = try await Client.invalid.listPredictions()
            XCTFail("unauthenticated requests should fail")
        } catch {
            guard let error = error as? Replicate.Error else {
                return XCTFail("invalid error")
            }

            XCTAssertEqual(error.detail, "Invalid token.")
        }
    }

    func testUnauthenticated() async throws {
        do {
            let _ = try await Client.unauthenticated.listPredictions()
            XCTFail("unauthenticated requests should fail")
        } catch {
            guard let error = error as? Replicate.Error else {
                return XCTFail("invalid error")
            }

            XCTAssertEqual(error.detail, "Authentication credentials were not provided.")
        }
    }
}
