# Replicate Swift client

This is a Swift client for [Replicate].
It lets you run models from your Swift code,
and do various other things on Replicate.

## Requirements

* macOS 12+ or iOS 15+
* Swift 5.7

## Usage

Grab your API token from [replicate.com/account](https://replicate.com/account)
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
                                                       input: ["prompt": "\(prompt)"],
                                                       wait: true)
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

try await prediction.wait(with: client)
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

try await prediction.cancel(with: client)
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

### Swift code generation for Replicate models

When working with models that are known ahead of time,
you can use the provided `generate-replicate-model` tool
to generate Swift code with fully-typed inputs and outputs.

For example, 
the following command generates code for the latest version of the 
[stability-ai/stable-diffusion](https://replicate.com/stability-ai/stable-diffusion) model 
([a9758cbfbd5f](https://replicate.com/stability-ai/stable-diffusion/versions/a9758cbfbd5f3c2094457d996681af52552901775aa2d6dd0b17fd15df959bef)):

```console
$ REPLICATE_API_TOKEN=<...> \
    generate-replicate-model stability-ai/stable-diffusion
```

```swift
import AnyCodable
import Foundation
import Replicate

/// A latent text-to-image diffusion model capable of generating photo-realistic images given any text input
public enum StableDiffusion: Predictable {

    /// The model ID.
    public static let modelID = "stability-ai/stable-diffusion"

    /// The model version ID.
    public static let versionID = "a9758cbfbd5f3c2094457d996681af52552901775aa2d6dd0b17fd15df959bef"

    /// The model input.
    public struct Input: Codable {
        /// Input prompt
        public var prompt: String?

        /// Width of output image. Maximum size is 1024x768 or 768x1024 because of memory limits
        public var width: AnyCodable?

        /// Height of output image. Maximum size is 1024x768 or 768x1024 because of memory limits
        public var height: AnyCodable?

        /// Inital image to generate variations of. Will be resized to the specified width and height
        public var initImage: URL?

        /// Black and white image to use as mask for inpainting over init_image. Black pixels are inpainted and white pixels are preserved. Experimental feature, tends to work better with prompt strength of 0.5-0.7
        public var mask: URL?

        /// Prompt strength when using init image. 1.0 corresponds to full destruction of information in init image
        public var promptStrength: Double?

        /// Number of images to output
        public var numOutputs: AnyCodable?

        /// Number of denoising steps
        public var numInferenceSteps: Int?

        /// Scale for classifier-free guidance
        public var guidanceScale: Double?

        /// Random seed. Leave blank to randomize the seed
        public var seed: Int?

        /// Creates a new Input.
        /// - Parameters:
        /// - prompt: Input prompt
        /// - width: Width of output image. Maximum size is 1024x768 or 768x1024 because of memory limits
        /// - height: Height of output image. Maximum size is 1024x768 or 768x1024 because of memory limits
        /// - initImage: Inital image to generate variations of. Will be resized to the specified width and height
        /// - mask: Black and white image to use as mask for inpainting over init_image. Black pixels are inpainted and white pixels are preserved. Experimental feature, tends to work better with prompt strength of 0.5-0.7
        /// - promptStrength: Prompt strength when using init image. 1.0 corresponds to full destruction of information in init image
        /// - numOutputs: Number of images to output
        /// - numInferenceSteps: Number of denoising steps
        /// - guidanceScale: Scale for classifier-free guidance
        /// - seed: Random seed. Leave blank to randomize the seed
        public init(
            prompt: String? = "",
            width: AnyCodable? = 512,
            height: AnyCodable? = 512,
            initImage: URL? = nil,
            mask: URL? = nil,
            promptStrength: Double? = 0.8,
            numOutputs: AnyCodable? = 1,
            numInferenceSteps: Int? = 50,
            guidanceScale: Double? = 7.5,
            seed: Int? = nil
        ) {
            self.prompt = prompt
            self.width = width
            self.height = height
            self.initImage = initImage
            self.mask = mask
            self.promptStrength = promptStrength
            self.numOutputs = numOutputs
            self.numInferenceSteps = numInferenceSteps
            self.guidanceScale = guidanceScale
            self.seed = seed
        }

        private enum CodingKeys: String, CodingKey {
            case prompt = "prompt"
            case width = "width"
            case height = "height"
            case initImage = "init_image"
            case mask = "mask"
            case promptStrength = "prompt_strength"
            case numOutputs = "num_outputs"
            case numInferenceSteps = "num_inference_steps"
            case guidanceScale = "guidance_scale"
            case seed = "seed"
        }
    }

    /// The model output.
    public typealias Output = [URL]
}
```

By adding this code to your project, 
you can now create predictions for the model with fully type-checked Swift code:

```swift
// `StableDiffusion.Input` is a struct with several properties
// which can be set through the initializer or property accessors.
var input = StableDiffusion.Input(prompt: "multicolor hyperspace")
input.numOutputs = 4

let prediction = try await StableDiffusion.predict(with: client, input: input)

// `StableDiffusion.Output` is a typealias for `[URL]`
for url in prediction.output ?? [] {
    print(url.absoluteString)
}
```

[Cog](https://github.com/replicate/cog) models hosted on Replicate 
describe their inputs and outputs using [OpenAPI](https://www.openapis.org/).
The `generate-replicate-model` parses this description
with the [`OpenAPIKit` package](https://github.com/mattpolzin/OpenAPIKit)
and generates code using [`SwiftSyntax`](https://github.com/apple/swift-syntax).

> **Note**
>
> The `Replicate` library has only one external dependency on
> the [`AnyCodable` package](https://github.com/Flight-School/AnyCodable),
> so including `Replicate` in your project won't add any other packages
> as runtime dependencies.

## Adding `Replicate` as a Dependency

To use the `Replicate` library in a Swift project,
add it to the dependencies for your package and your target:

```swift
let package = Package(
    // name, platforms, products, etc.
    dependencies: [
        // other dependencies
        .package(url: "https://github.com/mattt/replicate-swift", from: "0.3.0"),
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
