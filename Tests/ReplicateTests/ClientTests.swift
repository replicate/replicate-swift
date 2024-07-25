import XCTest
@testable import Replicate

final class ClientTests: XCTestCase {
    var client = Client.valid

    static override func setUp() {
        URLProtocol.registerClass(MockURLProtocol.self)
    }

    func testRunWithVersion() async throws {
        let identifier: Identifier = "test/example:5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
        let output = try await client.run(identifier, input: ["text": "Alice"])
        XCTAssertEqual(output, ["Hello, Alice!"])
    }

    func testRunWithModel() async throws {
        let identifier: Identifier = "meta/llama-2-70b-chat"
        let output = try await client.run(identifier, input: ["prompt": "Please write a haiku about llamas."])
        XCTAssertEqual(output, ["I'm sorry, I'm afraid I can't do that"] )
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

    func testCreatePredictionWithVersion() async throws {
        let version: Model.Version.ID = "5c7d5dc6dd8bf75c1acaa8565735e7986bc5b66206b55cca93cb72c9bf15ccaa"
        let prediction = try await client.createPrediction(version: version, input: ["text": "Alice"])
        XCTAssertEqual(prediction.id, "ufawqhfynnddngldkgtslldrkq")
        XCTAssertEqual(prediction.versionID, version)
        XCTAssertEqual(prediction.status, .starting)
    }

    func testCreatePredictionWithModel() async throws {
        let model: Model.ID = "meta/llama-2-70b-chat"
        let prediction = try await client.createPrediction(model: model, input: ["prompt": "Please write a poem about camelids"])
        XCTAssertEqual(prediction.id, "heat2o3bzn3ahtr6bjfftvbaci")
        XCTAssertEqual(prediction.modelID, model)
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
        do {
            _ = try await client.createPrediction(version: version, input: ["text": "Alice"])
            XCTFail()
        } catch {
            XCTAssertEqual(error.localizedDescription, "Invalid version")
        }
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

    func testCreateModel() async throws {
        let model = try await client.createModel(owner: "replicate", name: "hello-world", visibility: .public, hardware: "cpu")
        XCTAssertEqual(model.owner, "replicate")
        XCTAssertEqual(model.name, "hello-world")
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

    func testListHardware() async throws {
        let hardware = try await client.listHardware() 
        XCTAssertGreaterThan(hardware.count, 1)
        XCTAssertEqual(hardware.first?.name, "CPU")
        XCTAssertEqual(hardware.first?.sku, "cpu")
    }

    func testCurrentAccount() async throws {
        let account = try await client.getCurrentAccount()
        XCTAssertEqual(account.type, .organization)
        XCTAssertEqual(account.username, "replicate")
        XCTAssertEqual(account.name, "Replicate")
        XCTAssertEqual(account.githubURL?.absoluteString, "https://github.com/replicate")
    }

    func testGetDeployment() async throws {
        let deployment = try await client.getDeployment("replicate/my-app-image-generator")
        XCTAssertEqual(deployment.owner, "replicate")
        XCTAssertEqual(deployment.name, "my-app-image-generator")
        XCTAssertEqual(deployment.currentRelease?.number, 1)
        XCTAssertEqual(deployment.currentRelease?.model, "stability-ai/sdxl")
        XCTAssertEqual(deployment.currentRelease?.version, "da77bc59ee60423279fd632efb4795ab731d9e3ca9705ef3341091fb989b7eaf")
        XCTAssertEqual(deployment.currentRelease!.createdAt.timeIntervalSinceReferenceDate, 729707577.01, accuracy: 1)
        XCTAssertEqual(deployment.currentRelease?.createdBy.type, .organization)
        XCTAssertEqual(deployment.currentRelease?.createdBy.username, "replicate")
        XCTAssertEqual(deployment.currentRelease?.createdBy.name, "Replicate, Inc.")
        XCTAssertEqual(deployment.currentRelease?.createdBy.githubURL?.absoluteString, "https://github.com/replicate")
        XCTAssertEqual(deployment.currentRelease?.configuration.hardware, "gpu-t4")
        XCTAssertEqual(deployment.currentRelease?.configuration.scaling.minInstances, 1)
        XCTAssertEqual(deployment.currentRelease?.configuration.scaling.maxInstances, 5)
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

    func testSearchModels() async throws {
        let models = try await client.searchModels(query: "greeter")
        XCTAssertEqual(models.results.count, 1)
        XCTAssertEqual(models.results[0].owner, "replicate")
        XCTAssertEqual(models.results[0].name, "hello-world")
    }
}
