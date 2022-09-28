# Replicate Swift client

This is a Swift client for [Replicate]. 
It lets you run models from your Swift code, 
and do various other things on Replicate.

Grab your token from [replicate.com/account](https://replicate.com/account) 
and passing it to `Client(token:)`:

```swift
import Foundation
import Replicate

let client = Client(token: <#token#>)
```

You can run a model and get its output:

```swift
let model = try await client.getModel("stability-ai/stable-diffusion")
if let latestVersion = model.latestVersion {
    let prompt = """
        a 19th century portrait of a wombat gentleman
    """
    let prediction = try await client.createPrediction(latestVersion,
                                                       input: ["prompt": "\(prompt)"])
    print(prediction.output)
    // https://replicate.com/api/models/stability-ai/stable-diffusion/files/50fcac81-865d-499e-81ac-49de0cb79264/out-0.png
}
```

Some models, 
like [tencentarc/gfpgan](https://replicate.com/tencentarc/gfpgan), 
receive images as inputs. 
To pass a file as an input,
read the contents of the file into a `Data` object,
and use the `uriEncoded(mimeType:) helper method to create a URI-encoded string.

```swift
let model = try await client.getModel("tencentarc/gfpgan")
if let latestVersion = model.latestVersion {
    let data = try! Data(contentsOf: URL(fileURLWithPath: "/path/to/image.jpg"))
    let mimeType = "image/jpeg"
    let prediction = try await client.createPrediction(latestVersion,
                                                       input: ["img": "\(data.uriEncoded(mimeType: mimeType))"])
    print(prediction.output)
    // https://replicate.com/api/models/tencentarc/gfpgan/files/85f53415-0dc7-4703-891f-1e6f912119ad/output.png
}
```

You can start a model and run it in the background:

```swift
let model = client.getModel("kvfrans/clipdraw")

let prompt = """
    Watercolor painting of an underwater submarine
"""
var prediction = client.createPrediction(model.latestVersion!,
                                         input: ["prompt": "\(prompt)"])
print(prediction.status)
// "starting"

sleep(10)

prediction = try await client.getPrediction(prediction.id)
print(prediction.status)
// "succeeded"
```

You can cancel a running prediction:

```swift
let model = client.getModel("kvfrans/clipdraw")

let prompt = """
    Watercolor painting of an underwater submarine
"""
var prediction = client.createPrediction(model.latestVersion!,
                                         input: ["prompt": "\(prompt)"])
print(prediction.status)
// "starting"

prediction = try await client.cancelPrediction(prediction.id)
print(prediction.status)
// "canceled"
```

You can list all the predictions you've run:

```swift
var predictions: [Prediction] = []
var cursor: Client.Pagination<Prediction>.Cursor?
let limit = 100

repeat {
    let page = try await client.getPredictions(cursor: cursor)
    predictions.append(contentsOf: page.results)
    cursor = page.next
} while predictions.count < limit && cursor != nil
```

## Adding `Replicate` as a Dependency

To use the `Replicate` library in a Swift project, 
add it to the dependencies for your package and your target:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/mattt/replicate-swift", from: "0.1.0"),
    ],
    targets: [
        .target(name: "<target>", dependencies: [
            // other dependencies
            .product(name: "Replicate", package: "replicate-swift"),
        ]),
        // other targets
    ]
)
```

[Replicate]: https://replicate.com
