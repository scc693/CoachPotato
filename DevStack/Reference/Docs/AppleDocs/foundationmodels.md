<!--
Downloaded via https://llm.codes by @steipete on November 29, 2025 at 07:45 AM
Source URL: https://developer.apple.com/documentation/foundationmodels
Total pages processed: 200
URLs filtered: Yes
Content de-duplicated: Yes
Availability strings filtered: Yes
Code blocks only: No
-->

# https://developer.apple.com/documentation/foundationmodels/expanding-generation-with-tool-calling

- Foundation Models
- Expanding generation with tool calling

Article

# Expanding generation with tool calling

Build tools that enable the model to perform tasks that are specific to your use case.

## Overview

Tools provide a way to extend the functionality of the model for your own use cases. Tool-calling allows the model to interact with external code you create to fetch up-to-date information, ground responses in sources of truth that you provide, and perform side effects, like turning on dark mode.

You can create tools that enable the model to:

- Query entries from your app’s database and reference them in its answer.

- Perform actions within your app, like adjusting the difficulty in a game or making a web request to get additional information.

- Integrate with other frameworks, like Contacts or HealthKit, that use existing privacy and security mechanisms.

## Create a custom tool for your task

When you prompt the model with a question or make a request, the model decides whether it can provide an answer or if it needs the help of a tool. When the model determines that a tool can help, it calls the tool with additional arguments that the tool can use. After the tool completes the task, it returns control and contains the arguments that the tool accepts, and a method that the model calls when it wants to use the tool. You can call `call(arguments:)` concurrently with itself or with other tools. The following example shows a tool that accepts a search term and a number of recipes to retrieve:

struct BreadDatabaseTool: Tool {
let name = "searchBreadDatabase"
let description = "Searches a local database for bread recipes."

@Generable
struct Arguments {
@Guide(description: "The type of bread to search for")
var searchTerm: String
@Guide(description: "The number of recipes to get", .range(1...6))
var limit: Int
}

struct Recipe {
var name: String
var description: String
var link: URL
}

var recipes: [Recipe] = []

// Put your code here to retrieve a list of recipes from your database.

let formattedRecipes = recipes.map {
"Recipe for '\($0.name)': \($0.description) Link: \($0.link)"
}
return formattedRecipes
}
}

When you provide descriptions to generable properties, you help the model understand the semantics of the arguments. Keep descriptions as short as possible because long descriptions take up context size and can introduce latency. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

Tools use guided generation for the `Arguments` property. For more information about guided generation, see Generating Swift data structures with guided generation.

## Provide a session with the tool you create

When you create a session, you can provide a list of tools that are relevant to the task you want to complete. The tools you provide are available for all future interactions with the session. The following example initializes a session with a tool that the model can call when it determines that it would help satisfy the prompt:

let session = LanguageModelSession(
tools: [BreadDatabaseTool()]
)

let response = try await session.respond(
to: "Find three sourdough bread recipes"
)

Tool output can be a string, or a `GeneratedContent` object. The model can call a tool multiple times in parallel to satisfy the request, like when retrieving weather details for several cities:

struct WeatherTool: Tool {
let name = "getWeather"
let description = "Retrieve the latest weather information for a city"

@Generable
struct Arguments {
@Guide(description: "The city to get weather information for")
var city: String
}

struct Forecast: Encodable {
var city: String
var temperature: Int
}

// Get a random temperature value. Use `WeatherKit` to get
// a temperature for the city.
let temperature = Int.random(in: 30...100)
let formattedResult = """
The forecast for '\(arguments.city)' is '\(temperature)' \
degrees Fahrenheit.
"""
return formattedResult
}
}

// Create a session with default instructions that guide the requests.
let session = LanguageModelSession(
tools: [WeatherTool()],
instructions: "Help the person with getting weather information"
)

// Make a request that compares the temperature between several locations.
let response = try await session.respond(
to: "Is it hotter in Boston, Wichita, or Pittsburgh?"
)

## Handle errors thrown by a tool

When an error happens during tool calling, the session throws a `LanguageModelSession.ToolCallError` with the underlying error and includes the tool that throws the error. This helps you understand the error that happened during the tool call, and any custom error types that your tool produces. You can throw errors from your tools to escape calls when you detect something is wrong, like when the person using your app doesn’t allow access to the required data or a network call is taking longer than expected. Alternatively, your tool can return a string that briefly tells the model what didn’t work, like “Cannot access the database.”

do {
let answer = try await session.respond("Find a recipe for tomato soup.")
} catch let error as LanguageModelSession.ToolCallError {

// Access the name of the tool, like BreadDatabaseTool.
print(error.tool.name)

// Access an underlying error that your tool throws and check if the tool
// encounters a specific condition.
if case .databaseIsEmpty = error.underlyingError as? SearchBreadDatabaseToolError {
// Display an error in the UI.
}

} catch {
print("Some other error: \(error)")
}

## Inspect the call graph

A session contains an observable `transcript` property that allows you to track when, and how many times, the model calls your tools. A transcript also provides the ability to construct a representation of the call graph for debugging purposes and pairs well with SwiftUI to visualize session history.

struct MyHistoryView: View {

@State
var session = LanguageModelSession(
tools: [BreadDatabaseTool()]
)

var body: some View {
List(session.transcript) { entry in
switch entry {
case .instructions(let instructions):
// Display the instructions the model uses.
case .prompt(let prompt):
// Display the prompt made to the model.
case .toolCall(let call):
// Display the call details for a tool, like the tool name and arguments.
case .toolOutput(let output):
// Display the output that a tool provides

### Tool calling

Generate dynamic game content with guided generation and tools

Make gameplay more lively with AI generated dialog and encounters personalized to the player.

`protocol Tool`

A tool that a model can call to gather information at runtime or perform side effects.

---

# https://developer.apple.com/documentation/foundationmodels

Framework

# Foundation Models

Perform tasks with the on-device model that specializes in language understanding, structured output, and tool calling.

## Overview

The Foundation Models framework provides access to Apple’s on-device large language model that powers Apple Intelligence to help you perform intelligent tasks specific to your use case. The text-based on-device model identifies patterns that allow for generating new text that’s appropriate for the request you make, and it can make decisions to call code you write to perform specialized tasks.

Generate text content based on requests you make. The on-device model excels at a diverse range of text generation tasks, like summarization, entity extraction, text understanding, refinement, dialog for games, generating creative content, and more.

Generate entire Swift data structures with guided generation. With the `@Generable` macro, you can define custom data structures and the framework provides strong guarantees that the model generates instances of your type.

To expand what the on-device foundation model can do, use `Tool` to create custom tools that the model can call to assist with handling your request. For example, the model can call a tool that searches a local or online database for information, or calls a service in your app.

To use the on-device language model, people need to turn on Apple Intelligence on their device. For a list of supported devices, see Apple Intelligence.

For more information about acceptable usage of the Foundation Models framework, see Acceptable use requirements for the Foundation Models framework.

### Related videos

![\\
\\
Meet the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2025/286)

![\\
\\
Deep dive into the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2025/301)

![\\
\\
Code-along: Bring on-device AI to your app using the Foundation Models framework](https://developer.apple.com/videos/play/wwdc2025/259)

## Topics

### Essentials

Generating content and performing tasks with Foundation Models

Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output

Create generative experiences that appropriately handle sensitive inputs and respect people.

Support languages and locales with Foundation Models

Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models

Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

`class SystemLanguageModel`

An on-device large language model capable of text generation tasks.

`struct UseCase`

A type that represents the use case for prompting.

### Prompting

`class LanguageModelSession`

An object that represents a session that interacts with a language model.

`struct Instructions`

Details you provide that define the model’s intended behavior on prompts.

`struct Prompt`

A prompt from a person to the model.

`struct Transcript`

A linear history of entries that reflect an interaction with a session.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

### Guided generation

Generating Swift data structures with guided generation

Create robust apps by describing output you want programmatically.

`protocol Generable`

A type that the model uses when responding to prompts.

### Tool calling

Expanding generation with tool calling

Build tools that enable the model to perform tasks that are specific to your use case.

Generate dynamic game content with guided generation and tools

Make gameplay more lively with AI generated dialog and encounters personalized to the player.

`protocol Tool`

A tool that a model can call to gather information at runtime or perform side effects.

### Feedback

`struct LanguageModelFeedback`

Feedback appropriate for logging or attaching to Feedback Assistant.

---

# https://developer.apple.com/documentation/foundationmodels/generating-content-and-performing-tasks-with-foundation-models

- Foundation Models
- Generating content and performing tasks with Foundation Models

Article

# Generating content and performing tasks with Foundation Models

Enhance the experience in your app by prompting an on-device large language model.

## Overview

The Foundation Models framework lets you tap into the on-device large models at the core of Apple Intelligence. You can enhance your app by using generative models to create content or perform tasks. The framework supports language understanding and generation based on model capabilities.

## Understand model capabilities

When considering features for your app, it helps to know what the on-device language model can do. The on-device model supports text generation and understanding that you can use to:

| Capability | Prompt example |
| --- | --- |
| Summarize | “Summarize this article.” |
| Extract entities | “List the people and places mentioned in this text.” |
| Understand text | “What happens to the dog in this story?” |
| Refine or edit text | “Change this story to be in second person.” |
| Classify or judge text | “Is this text relevant to the topic ‘Swift’?” |
| Compose creative writing | “Generate a short bedtime story about a fox.” |
| Generate tags from text | “Provide two tags that describe the main topics of this text.” |
| Generate game dialog | “Respond in the voice of a friendly inn keeper.” |

The on-device language model may not be suitable for handling all requests, like:

| Capabilities to avoid | Prompt example |
| --- | --- |
| Do basic math | “How many b’s are there in bagel?” |
| Create code | “Generate a Swift navigation list.” |
| Perform logical reasoning | “If I’m at Apple Park facing Canada, what direction is Texas?” |

The model can complete complex generative tasks when you use guided generation or tool calling. For more on handling complex tasks, or tasks that require extensive world-knowledge, see Generating Swift data structures with guided generation and Expanding generation with tool calling.

## Check for availability

Before you use the on-device model in your app, check that the model is available by creating an instance of `SystemLanguageModel` with the `default` property.

Model availability depends on device factors like:

- The device must support Apple Intelligence.

- The device must have Apple Intelligence turned on in Settings.

Always verify model availability first, and plan for a fallback experience in case the model is unavailable.

struct GenerativeView: View {
// Create a reference to the system language model.
private var model = SystemLanguageModel.default

var body: some View {
switch model.availability {
case .available:
// Show your intelligence UI.
case .unavailable(.deviceNotEligible):
// Show an alternative UI.
case .unavailable(.appleIntelligenceNotEnabled):
// Ask the person to turn on Apple Intelligence.
case .unavailable(.modelNotReady):
// The model isn't ready because it's downloading or because of other system reasons.
case .unavailable(let other):
// The model is unavailable for an unknown reason.
}
}
}

## Create a session

After confirming that the model is available, create a `LanguageModelSession` object to call the model. For a single-turn interaction, create a new session each time you call the model:

// Create a session with the system model.
let session = LanguageModelSession()

For a multiturn interaction — where the model retains some knowledge of what it produced — reuse the same session each time you call the model.

## Provide a prompt to the model

A `Prompt` is an input that the model responds to. Prompt engineering is the art of designing high-quality prompts so that the model generates a best possible response for the request you make. A prompt can be as short as “hello”, or as long as multiple paragraphs. The process of designing a prompt involves a lot of exploration to discover the best prompt, and involves optimizing prompt length and writing style.

When thinking about the prompt you want to use in your app, consider using conversational language in the form of a question or command. For example, “What’s a good month to visit Paris?” or “Generate a food truck menu.”

Write prompts that focus on a single and specific task, like “Write a profile for the dog breed Siberian Husky”. When a prompt is long and complicated, the model takes longer to respond, and may respond in unpredictable ways. If you have a complex generation task in mind, break the task down into a series of specific prompts.

You can refine your prompt by telling the model exactly how much content it should generate. A prompt like, “Write a profile for the dog breed Siberian Husky” often takes a long time to process as the model generates a full multi-paragraph essay. If you specify “using three sentences”, it speeds up processing and generates a concise summary. Use phrases like “in a single sentence” or “in a few words” to shorten the generation time and produce shorter text.

// Generate a longer response for a specific command.
let simple = "Write me a story about pears."

// Quickly generate a concise response.
let quick = "Write the profile for the dog breed Siberian Husky using three sentences."

## Provide instructions to the model

`Instructions` help steer the model in a way that fits the use case of your app. The model obeys prompts at a lower priority than the instructions you provide. When you provide instructions to the model, consider specifying details like:

- What the model’s role is; for example, “You are a mentor,” or “You are a movie critic”.

- What the model should do, like “Help the person extract calendar events,” or “Help the person by recommending search suggestions”.

- What the style preferences are, like “Respond as briefly as possible”.

- What the possible safety measures are, like “Respond with ‘I can’t help with that’ if you’re asked to do something dangerous”.

Use content you trust in instructions because the model follows them more closely than the prompt itself. When you initialize a session with instructions, it affects all prompts the model responds to in that session. Instructions can also include example responses to help steer the model. When you add examples to your prompt, you provide the model with a template that shows the model what a good response looks like.

## Generate a response

To call the model with a prompt, call `respond(to:options:)` on your session. The response call is asynchronous because it may take a few seconds for the on-device foundation model to generate the response.

let instructions = """
Suggest five related topics. Keep them concise (three to seven words) and make sure they \
build naturally from the person's topic.
"""

let session = LanguageModelSession(instructions: instructions)

let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)

Instead of working with raw string output from the model, the framework offers guided generation to generate a custom Swift data structure you define. For more information about guided generation, see Generating Swift data structures with guided generation.

When you make a request to the model, you can provide custom tools to help the model complete the request. If the model determines that a `Tool` can assist with the request, the framework calls your `Tool` to perform additional actions like retrieving content from your local database. For more information about tool calling, see Expanding generation with tool calling

## Consider context size limits per session

The _context window size_ is a limit on how much data the model can process for a session instance. A token is a chunk of text the model processes, and the system model supports up to 4,096 tokens. A single token corresponds to three or four characters in languages like English, Spanish, or German, and one token per character in languages like Japanese, Chinese, or Korean. In a single session, the sum of all tokens in the instructions, all prompts, and all outputs count toward the context window size.

If your session processes a large amount of tokens that exceed the context window, the framework throws the error `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`. When you encounter the error, start a new session and try shortening your prompts. If you need to process a large amount of data that won’t fit in a single context window limit, break your data into smaller chunks, process each chunk in a separate session, and then combine the results.

For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Tune generation options and optimize performance

To get the best results for your prompt, experiment with different generation options. `GenerationOptions` affects the runtime parameters of the model, and you can customize them for every request you make.

// Customize the temperature to increase creativity.
let options = GenerationOptions(temperature: 2.0)

let session = LanguageModelSession()

let prompt = "Write me a story about coffee."
let response = try await session.respond(
to: prompt,
options: options
)

When you test apps that use the framework, use Xcode Instruments to understand more about the requests you make, like the time it takes to perform a request. When you make a request, you can access the `Transcript` entries that describe the actions the model takes during your `LanguageModelSession`.

## See Also

### Essentials

Improving the safety of generative model output

Create generative experiences that appropriately handle sensitive inputs and respect people.

Support languages and locales with Foundation Models

Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models

Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

`class SystemLanguageModel`

An on-device large language model capable of text generation tasks.

`struct UseCase`

A type that represents the use case for prompting.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.UseCase

Structure

# SystemLanguageModel.UseCase

A type that represents the use case for prompting.

struct UseCase

## Topics

### Getting the general use case

Generating content and performing tasks with Foundation Models

Enhance the experience in your app by prompting an on-device large language model.

`static let general: SystemLanguageModel.UseCase`

A use case for general prompting.

### Getting the content tagging use case

Categorizing and organizing data with content tags

Identify topics, actions, objects, and emotions in input text with a content tagging model.

`static let contentTagging: SystemLanguageModel.UseCase`

A use case for content tagging.

## Relationships

### Conforms To

- `Equatable`
- `Sendable`
- `SendableMetatype`

## See Also

### Essentials

Improving the safety of generative model output

Create generative experiences that appropriately handle sensitive inputs and respect people.

Support languages and locales with Foundation Models

Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models

Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

`class SystemLanguageModel`

An on-device large language model capable of text generation tasks.

---

# https://developer.apple.com/documentation/foundationmodels/generating-swift-data-structures-with-guided-generation

- Foundation Models
- Generating Swift data structures with guided generation

Article

# Generating Swift data structures with guided generation

Create robust apps by describing output you want programmatically.

## Overview

When you perform a request, the model returns a raw string in its natural language format. Raw strings require you to manually parse the details you want. Instead of working with raw strings, the framework provides guided generation, which gives strong guarantees that the response is in a format you expect.

To use guided generation, describe the output you want as a new Swift type. When you make a request to the model, include your custom type and the framework performs the work necessary to fill in and return an object with the parameters filled in for you. The framework uses constrained sampling when generating output, which defines the rules on what the model can generate. Constrained sampling prevents the model from producing malformed output and provides you with results as a type you define.

For more information about creating a session and prompting the model, see Generating content and performing tasks with Foundation Models.

## Conform your data type to Generable

To conform your type to `Generable`, describe the type and the parameters to guide the response of the model. The framework supports generating content with basic Swift types like `Bool`, `Int`, `Float`, `Double`, `Decimal`, and `Array`. For example, if you only want the model to return a numeric result, call `respond(to:generating:includeSchemaInPrompt:options:)` using the type `Float`:

let prompt = "How many tablespoons are in a cup?"
let session = LanguageModelSession(model: .default)

// Generate a response with the type `Float`, instead of `String`.
let response = try await session.respond(to: prompt, generating: Float.self)

A schema provides the ability to control the values of a property, and you can specify guides to control values you associate with it. The framework provides two macros that help you with schema creation. Use `Generable(description:)` on structures, actors, and enumerations; and only use `Guide(description:)` with stored properties.

When you add descriptions to `Generable` properties, you help the model understand the semantics of the properties. Keep the descriptions as short as possible — long descriptions take up additional context size and can introduce latency. The following example creates a type that describes a cat and includes a name, an age that’s constrained to a range of values, and a short profile:

@Generable(description: "Basic profile information about a cat")
struct CatProfile {
// A guide isn't necessary for basic fields.
var name: String

@Guide(description: "The age of the cat", .range(0...20))
var age: Int

@Guide(description: "A one sentence profile about the cat's personality")
var profile: String
}

You can nest custom `Generable` types inside other `Generable` types, and mark enumerations with associated values as `Generable`. The `Generable` macro ensures that all associated and nested values are themselves generable. This allows for advanced use cases like creating complex data types or dynamically generating views at runtime.

## Make a request with your custom data type

After creating your type, use it along with a `LanguageModelSession` to prompt the model. When you use a `Generable` type it prevents the model from producing malformed output and prevents the need for any manual string parsing.

// Generate a response using a custom type.
let response = try await session.respond(
to: "Generate a cute rescue cat",
generating: CatProfile.self
)

## Define a dynamic schema at runtime

If you don’t know what you want the model to produce at compile time use `DynamicGenerationSchema` to define what you need. For example, when you’re working on a restaurant app and want to restrict the model to pick from menu options that a restaurant provides. Because each restaurant provides a different menu, the schema won’t be known in its entirety until runtime.

// Create the dynamic schema at runtime.
let menuSchema = DynamicGenerationSchema(
name: "Menu",
properties: [\
DynamicGenerationSchema.Property(\
name: "dailySoup",\
schema: DynamicGenerationSchema(\
name: "dailySoup",\
anyOf: ["Tomato", "Chicken Noodle", "Clam Chowder"]\
)\
)\
\
// Add additional properties.\
]
)

After creating a dynamic schema, use it to create a `GenerationSchema` that you provide with your request. When you try to create a generation schema, it can throw an error if there are conflicting property names, undefined references, or duplicate types.

// Create the schema.
let schema = try GenerationSchema(root: menuSchema, dependencies: [])

// Pass the schema to the model to guide the output.
let response = try await session.respond(
to: "The prompt you want to make.",
schema: schema
)

The response you get is an instance of `GeneratedContent`. You can decode the outputs from schemas you define at runtime by calling `value(_:forProperty:)` for the property you want.

## See Also

### Guided generation

`protocol Generable`

A type that the model uses when responding to prompts.

---

# https://developer.apple.com/documentation/foundationmodels/instructions

- Foundation Models
- Instructions

Structure

# Instructions

Details you provide that define the model’s intended behavior on prompts.

struct Instructions

## Mentioned in

Generating content and performing tasks with Foundation Models

Improving the safety of generative model output

Support languages and locales with Foundation Models

## Overview

Instructions are typically provided by you to define the role and behavior of the model. In the code below, the instructions specify that the model replies with topics rather than, for example, a recipe:

let instructions = """
Suggest related topics. Keep them concise (three to seven words) and make sure they \
build naturally from the person's topic.
"""

let session = LanguageModelSession(instructions: instructions)

let prompt = "Making homemade bread"
let response = try await session.respond(to: prompt)

Apple trains the model to obey instructions over any commands it receives in prompts, so don’t include untrusted content in instructions. For more on how instructions impact generation quality and safety, see Improving the safety of generative model output.

All input to the model contributes tokens to the context window of the `LanguageModelSession` — including the `Instructions`, `Prompt`, `Tool`, and `Generable` types, and the model’s responses. If your session exceeds the available context size, it throws `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`.

Instructions can consume a lot of tokens that contribute to the context window size. To reduce your instruction size:

- Write shorter instructions to save tokens.

- Provide only the information necessary to perform the task.

- Use concise and imperative language instead of indirect or jargon that the model might misinterpret.

- Aim for one to three paragraphs instead of including a significant amount of background information, policy, or extra content.

For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

### Creating instructions

`init(_:)`

`struct InstructionsBuilder`

A type that represents an instructions builder.

`protocol InstructionsRepresentable`

A type that can be represented as instructions.

## Relationships

### Conforms To

- `Copyable`
- `InstructionsRepresentable`
- `Sendable`
- `SendableMetatype`

## See Also

### Prompting

`class LanguageModelSession`

An object that represents a session that interacts with a language model.

`struct Prompt`

A prompt from a person to the model.

`struct Transcript`

A linear history of entries that reflect an interaction with a session.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init(model:tools:instructions:)

#app-main)

- Foundation Models
- LanguageModelSession
- init(model:tools:instructions:)

Initializer

# init(model:tools:instructions:)

Start a new session in blank slate state with instructions builder.

convenience init(
model: SystemLanguageModel = .default,
tools: [any Tool] = [],

) rethrows

Show all declarations

## Discussion

- Parameters

- model: The language model to use for this session.

- tools: Tools to make available to the model for this session.

- instructions: Instructions that control the model’s behavior.

## See Also

### Creating a session

`class SystemLanguageModel`

An on-device large language model capable of text generation tasks.

`protocol Tool`

A tool that a model can call to gather information at runtime or perform side effects.

`struct Instructions`

Details you provide that define the model’s intended behavior on prompts.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/isresponding

- Foundation Models
- LanguageModelSession
- isResponding

Instance Property

# isResponding

A Boolean value that indicates a response is being generated.

final var isResponding: Bool { get }

## Mentioned in

Generating content and performing tasks with Foundation Models

## Discussion

Disable buttons and other interactions to prevent users from submitting a second prompt while the model is responding to their first prompt.

struct ShopView: View {
@State var session = LanguageModelSession()
@State var joke = ""

var body: some View {
Text(joke)
Button("Generate joke") {
Task {
assert(!session.isResponding, "It should not be possible to tap this button while the model is responding")
joke = try await session.respond(to: "Tell me a joke").content
}
}
.disabled(session.isResponding) // Prevent concurrent calls to respond
}
}

## See Also

### Inspecting session properties

`var transcript: Transcript`

A full history of interactions, including user inputs and model responses.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase/contenttagging

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.UseCase
- contentTagging

Type Property

# contentTagging

A use case for content tagging.

static let contentTagging: SystemLanguageModel.UseCase

## Mentioned in

Categorizing and organizing data with content tags

## Discussion

Content tagging produces a list of categorizing tags based on the input prompt. When specializing the model for the `contentTagging` use case, it always responds with tags. The tagging capabilities of the model include detecting topics, emotions, actions, and objects. For more information about content tagging, see Categorizing and organizing data with content tags.

## See Also

### Getting the content tagging use case

Identify topics, actions, objects, and emotions in input text with a content tagging model.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Guardrails

Structure

# SystemLanguageModel.Guardrails

Guardrails flag sensitive content from model input and output.

struct Guardrails

## Mentioned in

Improving the safety of generative model output

## Topics

### Getting the guardrail types

``static let `default`: SystemLanguageModel.Guardrails``

Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a `LanguageModelSession.GenerationError.guardrailViolation` error.

`static let permissiveContentTransformations: SystemLanguageModel.Guardrails`

Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.

### Handling guardrail errors

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Loading the model with a use case

`convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)`

Creates a system language model for a specific use case.

`struct UseCase`

A type that represents the use case for prompting.

---

# https://developer.apple.com/documentation/foundationmodels/generate-dynamic-game-content-with-guided-generation-and-tools

- Foundation Models
- Generate dynamic game content with guided generation and tools

Sample Code

# Generate dynamic game content with guided generation and tools

Make gameplay more lively with AI generated dialog and encounters personalized to the player.

Download

Xcode 26.0+

## Overview

This sample code project demonstrates the Foundation Models framework and its ability to generate dynamic content for a game. Instead of using the same dialog script for customer encounters, the app dynamically generates dialog so that each time a player talks to a character, they can have a different conversation.

The game combines several framework capabilities — like guided generation and tool calling — to create dynamic, personalized gameplay experiences. You interact with both scripted characters, like the head barista, and procedurally generated customers, each with unique personalities, appearances, and coffee orders. As you serve customers, you can engage in conversations, take custom coffee orders, and receive feedback on your brewing skills — all powered by an on-device foundation model.

## Generate character dialog

The sample app generates dialog for characters by using `Character` to describe the character, like the barista:

struct Barista: Character {
let id = UUID()
let displayName = "Barista"
let firstLine = "Hey there. Can you get the dream orders?"

let persona = """
Chike is the head barista at Dream Coffee, and loves serving up the perfect cup of coffee
to all the dreamers and creatures in the dream realm. Today is a particularly busy day, so
Chike is happy to have the help of a new trainee barista named Player.
"""

let errorResponse = "Maybe let's stop chatting? We've got coffee to serve."
}

A `persona` is a detailed description of the character that the model should pretend to be. The app uses a fixed error response when it encounters a generation error or content that the system blocks for safety.

The `DialogEngine` class manages conoversations for all characters in the game using `LanguageModelSession`. Each character maintains their own conversation session, allowing for persistent, contextual dialog that remembers previous interactions. When a conversation begins with a character, the dialog engine creates a new session with specific instructions that define the character’s personality and role:

let instructions = """
A multiturn conversation between a game character and the player of this game. \
You are \(character.displayName). Refer to \(character.displayName) in the first-person \
(like "I" or "me"). You must respond in the voice of \(character.persona).\

Keep your responses short and positive. Remember: Because this is the dream realm, \
everything is free at this coffee shop and the baristas are paid in creative inpiration.

You just said: "\(startWith)"
"""

When the player provides input text to _talk_ to the character, the sample app uses the input as a prompt to the session. When generating a response, the dialog engine includes safety mechanisms to keep conversations on topic. It maintains block lists for words and phrases that characters shouldn’t discuss, ensuring nonplayer characters (NPCs) focus on coffee-related topics. If the app generates content containing blocked terms, it automatically resets the conversation and provides the default error response for the character.

let response = try await session.respond(
to: userInput
)
let dialog = response.content

// Verify whether the input contains any blocked words or phrases.
if textIsOK(dialog) {
nextUtterance = dialog
isGenerating = false
} else {
nextUtterance = character.errorResponse
isGenerating = false
resetSession(character, startWith: character.resumeConversationLine)
}

If the output dialog fails the blocked phrases check, the model may break character or discuss something that’s outside of the game world. To keep the dialog immersive, set `nextUtterance` to the character’s fixed error response and reset the session.

## Generate random encounters

The `EncounterEngine` creates unique customer encounters using the `Generable` protocol to generate structured content. Each encounter produces an NPC with a name, coffee order, and visual description.

@Generable
struct NPC: Equatable {
let name: String
let coffeeOrder: String
let picture: GenerableImage
}

The process of generating an NPC uses a `LanguageModelSession` with a prompt that provide examples of the output format:

let session = LanguageModelSession {
"""
A conversation between the Player and a helpful assistant. This is a fantasy
RPG game that takes place at Dream Coffee, the beloved coffee shop of the
dream realm. Your role is to use your imagination to generate fun game characters.
"""
}
let prompt = """
Create an NPC customer with a fun personality suitable for the dream realm. Have the customer order
coffee. Here are some examples to inspire you:
{name: "Thimblefoot", imageDescription: "A horse with a rainbow mane",
coffeeOrder: "I would like a coffee that's refreshing and sweet like grass of a summer meadow"}
{name: "Spiderkid", imageDescription: "A furry spider with a cool baseball cap",
coffeeOrder: "An iced coffee please, that's as spooky as me!"}
{name: "Wise Fairy", imageDescription: "A blue glowing fairy that radiates wisdom and sparkles",
coffeeOrder: "Something simple and plant-based please, that will restore my wise energy."}
"""

// Generate the NPC using the custom generable type.
let npc = try await session.respond(
to: prompt,
generating: NPC.self,
).content

Each generated NPC includes a `GenerableImage` that creates a visual representation of the character by using Image Playground. The image generation avoids human-like appearances, focusing instead on fantastical creatures, animals, and objects that fit the dream realm aesthetic. The `GenerableImage` class shows how to use `GenerationSchema` to describe the properties and guides of the object. This allows for creating dynamic schemas when all of the details of the generable type isn’t known until runtime.

## Use a language model to judge in-game creations

The game uses the on-device model to evaluate player performance through the `judgeDrink(drink:)` method in the encounter engine. When the player creates a coffee drink for a customer, the model assumes the customer’s persona and provides feedback on whether the drink matches their original order.

The judging system creates a new `LanguageModelSession` that uses the specific customer’s personality and preferences, and a prompt that provides the drink details for the model to evaluate:

let session = LanguageModelSession {
"""
A conversation between a user and a helpful assistant. This is a fantasy RPG
game that takes place at Dream Coffee, the beloved coffee shop of the dream
realm. Your role is to pretend to be the following customer:
\(customer.name): \(customer.picture.imageDescription)
"""
}
let prompt = """
You have just ordered the following drink:
\(customer.coffeeOrder)
The barista has just made you this drink:
\(drink)
Does this drink match your expectations? Do you like it? You must respond
with helpful feedback for the barista. If you like your drink, give it a
compliment. If you dislike your drink, politely tell the barista why.
"""
return try await session.respond(to: prompt).content

The model then compares the player’s creation against the customer’s original order, providing contextual feedback that’s authentic to the character’s personality. This creates a dynamic evaluation system where the same drink might receive different reactions from different customers based on their unique preferences and personas.

## Use tools to personalize game content

For customers that the sample generates, provide the dialog engine with custom tools, like `CalendarTool` to create more personalized interactions. This allows characters to reference the player’s on-device information, making conversations feel more natural and connected to the player’s actual life.

The `CalendarTool` integrates with EventKit to access the player’s calendar events, and allows characters to reference real upcoming events that involve the customer’s name if they are an attendee:

if let customer = character as? GeneratedCustomer {
newSession = LanguageModelSession(
tools: [CalendarTool(contactName: customer.displayName)],
instructions: instructions
)
}

The tool description tells the model what it uses the tool for:

description = """
Get an event from the player's calendar with \(contactName). \
Today is \(Date().formatted(date: .complete, time: .omitted))
"""

The sample app also provides a `ContactTool` that accesses the player’s contacts to find names of people born in specific months. This allows the game to generate a coffee shop customer with names the player is familiar with.

let session = LanguageModelSession(
tools: [contactsTool],
instructions: """
Use the \(contactsTool.name) tool to get a name for a customer.
"""
)

## See Also

### Tool calling

Expanding generation with tool calling

Build tools that enable the model to perform tasks that are specific to your use case.

`protocol Tool`

A tool that a model can call to gather information at runtime or perform side effects.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init(model:tools:transcript:)

#app-main)

- Foundation Models
- LanguageModelSession
- init(model:tools:transcript:)

Initializer

# init(model:tools:transcript:)

Start a session by rehydrating from a transcript.

convenience init(
model: SystemLanguageModel = .default,
tools: [any Tool] = [],
transcript: Transcript
)

## Discussion

- Parameters

- model: The language model to use for this session.

- transcript: A transcript to resume from.

- tools: Tools to make available to the model for this session.

## See Also

### Creating a session from a transcript

`struct Transcript`

A linear history of entries that reflect an interaction with a session.

---

# https://developer.apple.com/documentation/foundationmodels/categorizing-and-organizing-data-with-content-tags

- Foundation Models
- SystemLanguageModel.UseCase
- Categorizing and organizing data with content tags

Article

# Categorizing and organizing data with content tags

Identify topics, actions, objects, and emotions in input text with a content tagging model.

## Overview

The Foundation Models framework provides an adapted on-device system language model that specializes in content tagging. A content tagging model produces a list of categorizing tags based on the input text you provide. When you prompt the content tagging model, it produces a tag that uses one to a few lowercase words. The model finds the similarity between the terms in your prompt so tags are semantically consistent. For example, the model produces the topic tag “greet” when it encounters words such as “hi,” “hello,” and “yo”. Use the content tagging model to:

- Gather statistics about popular topics and opinions in a social app.

- Customize your app’s experience by matching tags to a person’s interests.

- Help people organize their content for tasks such as email autolabeling using the tags your app detects.

- Identify trends by aggregating tags across your content.

If you’re tagging content that’s not an action, object, emotion, or topic, use `general` instead. Use the general model to generate content like hashtags for social media posts. If you adopt the tool calling API, and want to generate tags, use `general` and pass the `Tool` output to the content tagging model. For more information about tool-calling, see Expanding generation with tool calling.

## Provide instructions to the model

The content tagging model isn’t a typical language model that responds to a query from a person: instead, it evaluates and groups the input you provide. For example, if you ask the model questions, it produces tags about asking questions. Before you prompt the model, consider the instructions you want it to follow: instructions to the the model produce a more precise outcome than instructions in the prompt.

The model identifies topics, actions, objects, and emotions from the input text you provide, so include the type of tags you want in your instructions. It’s also helpful to provide the number of tags you want the model to produce. You can also specify the number of elements in your instructions.

// Create an instance of the on-device language model's content tagging use case.
let model = SystemLanguageModel(useCase: .contentTagging)

// Initialize a session with the model and instructions.
let session = LanguageModelSession(model: model, instructions: """
Provide the two tags that are most significant in the context of topics.
"""
)

You don’t need to provide a lot of custom tagging instructions; the content tagging model respects the output format you want, even in the absence of instructions. If you create a generable data type that describes properties with `GenerationGuide`, you can save context window space by not including custom instructions. If you don’t provide generation guides, the model generates topic-related tags by default.

## Create a generable type

The content tagging model supports `Generable`, so you can define a custom data type that the model uses when generating a response. Use `maximumCount(_:)` on your generable type to enforce a maximum number of tags that you want the model to return. The code below uses `Generable` guide descriptions to specify the kinds and quantities of tags the model produces:

@Generable
struct ContentTaggingResult {
@Guide(
description: "Most important actions in the input text.",
.maximumCount(2)
)
let actions: [String]

@Guide(
description: "Most important emotions in the input text.",
.maximumCount(3)
)
let emotions: [String]

@Guide(
description: "Most important objects in the input text.",
.maximumCount(5)
)
let objects: [String]

@Guide(
description: "Most important topics in the input text.",
.maximumCount(2)
)
let topics: [String]
}

Ideally, match the maximum count you use in your instructions with what you define using the `maximumCount(_:)` generation guide. If you use a different maximum for each, consider putting the larger maximum in your instructions.

Long queries can produce a large number of actions and objects, so define a maximum count to limit the number of tags. This step helps the model focus on the most relevant parts of long queries, avoids duplicate actions and objects, and improves decoding time.

If you have a complex set of constraints on tagging that are more complicated than the maximum count support of the tagging model, use `general` instead.

For more information on guided generation, see Generating Swift data structures with guided generation.

## Generate a content tagging response

Initialize your session by using the `contentTagging` model:

// Create an instance of the model with the content tagging use case.
let model = SystemLanguageModel(useCase: .contentTagging)

// Initialize a session with the model.
let session = LanguageModelSession(model: model)

The code below prompts the model to respond about a picnic at the beach with tags like “outdoor activity,” “beach,” and “picnic”:

let prompt = """
Today we had a lovely picnic with friends at the beach.
"""
let response = try await session.respond(
to: prompt,
generating: ContentTaggingResult.self
)

The prompt “Grocery list: 1. Bread flour 2. Salt 3. Instant yeast” prompts the model to respond with the topic “grocery shopping” and includes the objects “grocery list” and “bread flour”.

For some queries, lists may produce the same tag. For example, some topic and emotion tags, like humor, may overlap. When the model produces duplicates, handle it in code, and choose the tag you prefer. When you reuse the same `LanguageModelSession`, the model may produce tags related to the previous turn or a combination of turns. The model produces what it views as the most important.

## See Also

### Getting the content tagging use case

`static let contentTagging: SystemLanguageModel.UseCase`

A use case for content tagging.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/isavailable

- Foundation Models
- SystemLanguageModel
- isAvailable

Instance Property

# isAvailable

A convenience getter to check if the system is entirely ready.

final var isAvailable: Bool { get }

## See Also

### Checking model availability

`var availability: SystemLanguageModel.Availability`

The availability of the language model.

`enum Availability`

The availability status for a specific system language model.

---

# https://developer.apple.com/documentation/foundationmodels/prompt

- Foundation Models
- Prompt

Structure

# Prompt

A prompt from a person to the model.

struct Prompt

## Mentioned in

Generating content and performing tasks with Foundation Models

## Overview

Prompts can contain content written by you, an outside source, or input directly from people using your app. You can initialize a `Prompt` from a string literal:

let prompt = Prompt("What are miniature schnauzers known for?")

Use `PromptBuilder` to dynamically control the prompt’s content based on your app’s state. The code below shows that if the Boolean is `true`, the prompt includes a second line of text:

let responseShouldRhyme = true
let prompt = Prompt {
"Answer the following question from the user: \(userInput)"
if responseShouldRhyme {
"Your response MUST rhyme!"
}
}

If your prompt includes input from people, consider wrapping the input in a string template with your own prompt to better steer the model’s response. For more information on handling inputs in your prompts, see Improving the safety of generative model output.

All input to the model contributes tokens to the context window of the `LanguageModelSession` — including the `Instructions`, `Prompt`, `Tool`, and `Generable` types, and the model’s responses. If your session exceeds the available context size, it throws `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`.

Prompts can consume a lot of tokens, especially when you send multiple prompts to the same session. To reduce your prompt size when you exceed the context window size:

- Write shorter prompts to save tokens.

- Provide only the information necessary to perform the task.

- Use concise and imperative language instead of indirect or jargon that the model might misinterpret.

- Use a clear verb that tells the model what to do, like “Generate”, “List”, or “Summarize”.

- Include the target response length you want, like “In three sentences” or “List five reasons”.

Prompting the same session eventually leads to exceeding the context window size. When that happens, create a new context window by initializing a new instance of `LanguageModelSession`. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

### Creating a prompt

`init(_:)`

`struct PromptBuilder`

A type that represents a prompt builder.

`protocol PromptRepresentable`

A type whose value can represent a prompt.

## Relationships

### Conforms To

- `Copyable`
- `PromptRepresentable`
- `Sendable`
- `SendableMetatype`

## See Also

### Prompting

`class LanguageModelSession`

An object that represents a session that interacts with a language model.

`struct Instructions`

Details you provide that define the model’s intended behavior on prompts.

`struct Transcript`

A linear history of entries that reflect an interaction with a session.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback

- Foundation Models
- LanguageModelFeedback

Structure

# LanguageModelFeedback

Feedback appropriate for logging or attaching to Feedback Assistant.

struct LanguageModelFeedback

## Mentioned in

Improving the safety of generative model output

## Overview

`LanguageModelFeedback` is a namespace with structures for describing feedback in a consistent way. `LanguageModelFeedback.Sentiment` describes the sentiment of the feedback, while `LanguageModelFeedback.Issue` offers a standard template for issues.

Given a model session, use `logFeedbackAttachment(sentiment:issues:desiredOutput:)` to produce structured feedback.

let session = LanguageModelSession()
let response = try await session.respond(to: "What is the capital of France?")

// Create feedback for a problematic response.
let feedbackData = session.logFeedbackAttachment(
sentiment: LanguageModelFeedback.Sentiment.negative,
issues: [\
LanguageModelFeedback.Issue(\
category: .incorrect,\
explanation: "The model provided outdated information"\
)\
],
desiredOutput: Transcript.Entry.response(...)
)

## Topics

### Creating feedback

`struct Issue`

An issue with the model’s response.

`enum Sentiment`

A sentiment regarding the model’s response.

Logs and serializes data that includes session information that you attach when reporting feed

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(options:prompt:)

#app-main)

- Foundation Models
- LanguageModelSession
- respond(options:prompt:)

Instance Method

# respond(options:prompt:)

Produces a response to a prompt.

@discardableResult nonisolated(nonsending)
final func respond(
options: GenerationOptions = GenerationOptions(),

## Parameters

`options`

GenerationOptions that control how tokens are sampled from the distribution the model produces.

`prompt`

A prompt for the model to respond to.

## Return Value

A string composed of the tokens produced by sampling model output.

## See Also

### Generating a request

Produces a generable object as a response to a prompt.

Produces a generated content type as a response to a prompt and schema.

`func respond(to:options:)`

`func respond(to:generating:includeSchemaInPrompt:options:)`

`func respond(to:schema:includeSchemaInPrompt:options:)`

`struct Prompt`

A prompt from a person to the model.

`struct Response`

A structure that stores the output of a response call.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment(sentiment:issues:desiredresponsecontent:)

#app-main)

- Foundation Models
- LanguageModelSession
- logFeedbackAttachment(sentiment:issues:desiredResponseContent:)

Instance Method

# logFeedbackAttachment(sentiment:issues:desiredResponseContent:)

@backDeployed(before: iOS 26.1, macOS 26.1, visionOS 26.1)
@discardableResult
final func logFeedbackAttachment(
sentiment: LanguageModelFeedback.Sentiment?,
issues: [LanguageModelFeedback.Issue] = [],
desiredResponseContent: (any ConvertibleToGeneratedContent)?

## See Also

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportslocale(_:)

#app-main)

- Foundation Models
- SystemLanguageModel
- supportsLocale(\_:)

Instance Method

# supportsLocale(\_:)

Returns a Boolean indicating whether the given locale is supported by the model.

## Mentioned in

Support languages and locales with Foundation Models

## Discussion

Use this method over `supportedLanguages` to check whether the given locale qualifies a user for using this model, as this method will take into consideration language fallbacks.

---

# https://developer.apple.com/documentation/foundationmodels/generable

- Foundation Models
- Generable

Protocol

# Generable

A type that the model uses when responding to prompts.

protocol Generable : ConvertibleFromGeneratedContent, ConvertibleToGeneratedContent

## Mentioned in

Categorizing and organizing data with content tags

Generating Swift data structures with guided generation

## Overview

Annotate your Swift structure or enumeration with the `Generable` macro to allow the model to respond to prompts by generating an instance of your type. Use the `Guide` macro to provide natural language descriptions of your properties, and programmatically control the values that the model can generate.

@Generable
struct SearchSuggestions {
@Guide(description: "A list of suggested search terms.", .count(4))
var searchTerms: [SearchTerm]
@Generable
struct SearchTerm {
// Use a generation identifier for data structures the framework generates.
var id: GenerationID
@Guide(description: "A two- or three- word search term, like 'Beautiful sunsets'.")
var searchTerm: String
}
}

For every `Generable` type in a request, the framework converts its type and format information to a JSON schema and provides it to the model. This contributes to the available context window size. If the `LanguageModelSession` exceeds the available context size, it throws `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`. To reduce the size of your generable type:

- Reduce the complexity of your `Generable` type by evaluating whether properties are necessary to complete the task.

- Give your properties short and clear names.

- Use `Guide(description:)` on properties only when it improves response quality.

- Add a `Guide(description:_:)` with `maximumCount(_:)` to reduce token usage.

If the `Generable` type includes properties with clear names the model may have all it needs to generate your type, eliminating the need of `Guide(description:)`. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

### Defining a generable type

`macro Generable(description: String?)`

Conforms a type to `Generable` protocol.

### Creating a guide

`macro Guide(description: String)`

Allows for influencing the allowed values of properties of a `Generable` type.

`macro Guide(description:_:)`

`struct GenerationGuide`

Guides that control how values are generated.

### Getting the schema

`static var generationSchema: GenerationSchema`

An instance of the generation schema.

**Required**

`struct GenerationSchema`

A type that describes the properties of an object and any guides on their values.

### Generating a unique identifier

`struct GenerationID`

A unique identifier that is stable for the duration of a response, but not across responses.

### Converting to partially generated

The partially generated type of this struct.

`associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self`

A representation of partially generated content

**Required** Default implementation provided.

### Generate dynamic shemas

`struct DynamicGenerationSchema`

The dynamic counterpart to the generation schema type that you use to construct schemas at runtime.

## Relationships

### Inherits From

- `ConvertibleFromGeneratedContent`
- `ConvertibleToGeneratedContent`
- `InstructionsRepresentable`
- `PromptRepresentable`
- `SendableMetatype`

### Conforming Types

- `GeneratedContent`

## See Also

### Guided generation

Create robust apps by describing output you want programmatically.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/init(usecase:guardrails:)

#app-main)

- Foundation Models
- SystemLanguageModel
- init(useCase:guardrails:)

Initializer

# init(useCase:guardrails:)

Creates a system language model for a specific use case.

convenience init(
useCase: SystemLanguageModel.UseCase = .general,
guardrails: SystemLanguageModel.Guardrails = Guardrails.default
)

## See Also

### Loading the model with a use case

`struct UseCase`

A type that represents the use case for prompting.

`struct Guardrails`

Guardrails flag sensitive content from model input and output.

---

# https://developer.apple.com/documentation/foundationmodels/tool

- Foundation Models
- Tool

Protocol

# Tool

A tool that a model can call to gather information at runtime or perform side effects.

## Mentioned in

Generating content and performing tasks with Foundation Models

Categorizing and organizing data with content tags

Expanding generation with tool calling

## Overview

Tool calling gives the model the ability to call your code to incorporate up-to-date information like recent events and data from your app. A tool includes a name and a description that the framework puts in the prompt to let the model decide when and how often to call your tool.

A `Tool` defines a `call(arguments:)` method that takes arguments that conforms to `ConvertibleFromGeneratedContent`, and returns an output of any type that conforms to `PromptRepresentable`, allowing the model to understand and reason about in subsequent interactions. Typically, `Output` is a `String` or any `Generable` types.

struct FindContacts: Tool {
let name = "findContacts"
let description = "Find a specific number of contacts"

@Generable
struct Arguments {
@Guide(description: "The number of contacts to get", .range(1...10))
let count: Int
}

var contacts: [CNContact] = []
// Fetch a number of contacts using the arguments.
let formattedContacts = contacts.map {
"\($0.givenName) \($0.familyName)"
}
return formattedContacts
}
}

Tools must conform to `Sendable` so the framework can run them concurrently. If the model needs to pass the output of one tool as the input to another, it executes back-to-back tool calls.

You control the life cycle of your tool, so you can track the state of it between calls to the model. For example, you might store a list of database records that you don’t want to reuse between tool calls.

Prompting the model with tools contributes to the available context window size. When you provide a tool in your generation request, the framework puts the tool definitions — name, description, parameter information — in the prompt so the model can decide when and how often to call the tool. After calling your tool, the framework returns the tool’s output ) descriptions to a short phrase each.

- Limit the number of tools you use to three to five.

- Include a tool only when its necessary for the task you want to perform.

- Run an essential tool before calling the model and integrate the tool’s output in the prompt directly.

If your session exceeds the available context size, it throws `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`. When you encounter the context window limit, consider breaking up tool calls across new `LanguageModelSession` instances. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

### Invoking a tool

A language model will call this method when it wants to leverage this tool.

**Required**

`associatedtype Arguments : ConvertibleFromGeneratedContent`

The arguments that this tool should accept.

`associatedtype Output : PromptRepresentable`

The output that this tool produces for the language model to reason about in subsequent interactions.

### Getting the tool properties

`var description: String`

A natural language description of when and how to use the tool.

`var includesSchemaInInstructions: Bool`

If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

**Required** Default implementation provided.

`var name: String`

A unique name for the tool, such as “get\_weather”, “toggleDarkMode”, or “search contacts”.

`var parameters: GenerationSchema`

A schema for the parameters this tool accepts.

## Relationships

### Inherits From

- `Sendable`
- `SendableMetatype`

## See Also

### Tool calling

Build tools that enable the model to perform tasks that are specific to your use case.

Generate dynamic game content with guided generation and tools

Make gameplay more lively with AI generated dialog and encounters personalized to the player.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(to:options:)-b2re

-b2re#app-main)

- Foundation Models
- LanguageModelSession
- respond(to:options:)

Instance Method

# respond(to:options:)

Produces a response to a prompt.

@discardableResult nonisolated(nonsending)
final func respond(
to prompt: String,
options: GenerationOptions = GenerationOptions()

Show all declarations

## Parameters

`prompt`

A prompt for the model to respond to.

`options`

GenerationOptions that control how tokens are sampled from the distribution the model produces.

## Return Value

A string composed of the tokens produced by sampling model output.

## Mentioned in

Generating content and performing tasks with Foundation Models

---

# https://developer.apple.com/documentation/foundationmodels/tool/call(arguments:)

#app-main)

- Foundation Models
- Tool
- call(arguments:)

Instance Method

# call(arguments:)

A language model will call this method when it wants to leverage this tool.

**Required**

## Mentioned in

Expanding generation with tool calling

## Discussion

If errors are throw in the body of this method, they will be wrapped in a `LanguageModelSession.ToolCallError` and rethrown at the call site of `respond(to:options:)`.

## See Also

### Invoking a tool

`associatedtype Arguments : ConvertibleFromGeneratedContent`

The arguments that this tool should accept.

`associatedtype Output : PromptRepresentable`

The output that this tool produces for the language model to reason about in subsequent interactions.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/transcript

- Foundation Models
- LanguageModelSession
- transcript

Instance Property

# transcript

A full history of interactions, including user inputs and model responses.

final var transcript: Transcript { get }

## Mentioned in

Expanding generation with tool calling

## See Also

### Inspecting session properties

`var isResponding: Bool`

A Boolean value that indicates a response is being generated.

---

# https://developer.apple.com/documentation/foundationmodels/instructions/init(_:)

#app-main)

- Foundation Models
- Instructions
- init(\_:)

Initializer

# init(\_:)

Show all declarations

## See Also

### Creating instructions

`struct InstructionsBuilder`

A type that represents an instructions builder.

`protocol InstructionsRepresentable`

A type that can be represented as instructions.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(to:generating:includeschemainprompt:options:)

#app-main)

- Foundation Models
- LanguageModelSession
- respond(to:generating:includeSchemaInPrompt:options:)

Instance Method

# respond(to:generating:includeSchemaInPrompt:options:)

Produces a generable object as a response to a prompt.

@discardableResult nonisolated(nonsending)

to prompt: Prompt,
generating type: Content.Type = Content.self,
includeSchemaInPrompt: Bool = true,
options: GenerationOptions = GenerationOptions()

Show all declarations

## Parameters

`prompt`

A prompt for the model to respond to.

`type`

A type to produce as the response.

`includeSchemaInPrompt`

Inject the schema into the prompt to bias the model.

`options`

Options that control how tokens are sampled from the distribution the model produces.

## Return Value

`GeneratedContent` containing the fields and values defined in the schema.

## Discussion

Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

### Generating a request

Produces a response to a prompt.

Produces a generated content type as a response to a prompt and schema.

`func respond(to:options:)`

`func respond(to:schema:includeSchemaInPrompt:options:)`

`struct Prompt`

A prompt from a person to the model.

`struct Response`

A structure that stores the output of a response call.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/prewarm(promptprefix:)

#app-main)

- Foundation Models
- LanguageModelSession
- prewarm(promptPrefix:)

Instance Method

# prewarm(promptPrefix:)

Loads the resources required for this session into memory, and optionally caches a prefix of your prompt to reduce request latency.

final func prewarm(promptPrefix: Prompt? = nil)

## Discussion

Use this method when you know a person will launch and interact with your session within a few seconds to preload the required session resources. For example, you might call this method when a person begins typing into a text field.

If you have a prefix for a future prompt, passing it to this method allows the system to process the prompt eagerly and reduce latency for the future request.

Calling this method doesn’t guarantee that the system loads your resources immediately, particularly if your app is running in the background or the system is under load.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse(to:schema:includeschemainprompt:options:)

#app-main)

- Foundation Models
- LanguageModelSession
- streamResponse(to:schema:includeSchemaInPrompt:options:)

Instance Method

# streamResponse(to:schema:includeSchemaInPrompt:options:)

Produces a response stream to a prompt and schema.

final func streamResponse(
to prompt: Prompt,
schema: GenerationSchema,
includeSchemaInPrompt: Bool = true,
options: GenerationOptions = GenerationOptions()

Show all declarations

## Parameters

`prompt`

A prompt for the model to respond to.

`schema`

A schema to guide the output with.

`includeSchemaInPrompt`

Inject the schema into the prompt to bias the model.

`options`

Options that control how tokens are sampled from the distribution the model produces.

## Return Value

A response stream that produces `GeneratedContent` containing the fields and values defined in the schema.

## Discussion

Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment(sentiment:issues:desiredresponsetext:)

#app-main)

- Foundation Models
- LanguageModelSession
- logFeedbackAttachment(sentiment:issues:desiredResponseText:)

Instance Method

# logFeedbackAttachment(sentiment:issues:desiredResponseText:)

@backDeployed(before: iOS 26.1, macOS 26.1, visionOS 26.1)
@discardableResult
final func logFeedbackAttachment(
sentiment: LanguageModelFeedback.Sentiment?,
issues: [LanguageModelFeedback.Issue] = [],
desiredResponseText: String?

## See Also

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/usecase/general

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.UseCase
- general

Type Property

# general

A use case for general prompting.

static let general: SystemLanguageModel.UseCase

## Mentioned in

Categorizing and organizing data with content tags

## Discussion

This is the default use case for the base version of the model, so if you use `SystemLanguageModel/default`, you don’t need to specify a use case.

## See Also

### Getting the general use case

Generating content and performing tasks with Foundation Models

Enhance the experience in your app by prompting an on-device large language model.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession

- Foundation Models
- LanguageModelSession

Class

# LanguageModelSession

An object that represents a session that interacts with a language model.

final class LanguageModelSession

## Mentioned in

Generating content and performing tasks with Foundation Models

Categorizing and organizing data with content tags

Generating Swift data structures with guided generation

Improving the safety of generative model output

Support languages and locales with Foundation Models

## Overview

A session is a single context that you use to generate content with, and maintains state between requests. You can reuse the existing instance or create a new one each time you call the model. When creating a session, provide instructions that tells the model what its role is and provide guidance on how to respond.

let session = LanguageModelSession(instructions: """
You are a motivational workout coach that provides quotes to inspire \
and motivate athletes.
"""
)
let prompt = "Generate a motivational quote for my next workout."
let response = try await session.respond(to: prompt)

The framework records each call to the model in a `Transcript` that includes all prompts and responses. If your session exceeds the available context size, it throws `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`.

When you perform a task that needs a larger context size, split the task into smaller steps and run each of them in a new `LanguageModelSession`. For example, to generate a summary for a long article on device:

1. Separate the article into smaller sections.

2. Summarize each section with a new session instance.

3. Combine the sections.

4. Repeat the steps until you get a summary with the size you want, and consider adding the summary to the prompt so it conveys the contextual information.

Use Instruments to analyze token consumption while your app is running and to look for opportunities to improve performance, like with `prewarm(promptPrefix:)`. To profile your app with Instruments:

2. Select the Blank template, then click Choose.

3. In Instruments, click “+ Instrument” to open the instruments library.

4. Choose the Foundation Models instrument from the list.

Because some generation tasks can be resource intensive, consider profiling your app with other instruments — like Activity Monitor and Power Profiler — to identify where your app might be using more system resources than expected.

For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

### Creating a session

`convenience(model:tools:instructions:)`

Start a new session in blank slate state with instructions builder.

`class SystemLanguageModel`

An on-device large language model capable of text generation tasks.

`protocol Tool`

A tool that a model can call to gather information at runtime or perform side effects.

`struct Instructions`

Details you provide that define the model’s intended behavior on prompts.

### Creating a session from a transcript

[`convenience init(model: SystemLanguageModel, tools: [any Tool], transcript: Transcript)`](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/init(model:tools:transcript:))

Start a session by rehydrating from a transcript.

`struct Transcript`

A linear history of entries that reflect an interaction with a session.

### Preloading the model

`func prewarm(promptPrefix: Prompt?)`

Loads the resources required for this session into memory, and optionally caches a prefix of your prompt to reduce request latency.

### Inspecting session properties

`var isResponding: Bool`

A Boolean value that indicates a response is being generated.

`var transcript: Transcript`

A full history of interactions, including user inputs and model responses.

### Generating a request

Produces a response to a prompt.

Produces a generable object as a response to a prompt.

Produces a generated content type as a response to a prompt and schema.

`func respond(to:options:)`

`func respond(to:generating:includeSchemaInPrompt:options:)`

`func respond(to:schema:includeSchemaInPrompt:options:)`

`struct Prompt`

A prompt from a person to the model.

`struct Response`

A structure that stores the output of a response call.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream to a prompt and schema.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

### Getting the error types

`enum GenerationError`

An error that may occur while generating a response.

`struct ToolCallError`

An error that occurs while a system language model is calling a tool.

## Relationships

### Conforms To

- `Copyable`
- `Observable`
- `Sendable`
- `SendableMetatype`

## See Also

### Prompting

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(to:options:)

#app-main)

- Foundation Models
- LanguageModelSession
- respond(to:options:)

Instance Method

# respond(to:options:)

Produces a response to a prompt.

@discardableResult nonisolated(nonsending)
final func respond(
to prompt: Prompt,
options: GenerationOptions = GenerationOptions()

Show all declarations

## Parameters

`prompt`

A prompt for the model to respond to.

`options`

GenerationOptions that control how tokens are sampled from the distribution the model produces.

## Return Value

A string composed of the tokens produced by sampling model output.

## Mentioned in

Support languages and locales with Foundation Models

## See Also

### Generating a request

Produces a generable object as a response to a prompt.

Produces a generated content type as a response to a prompt and schema.

`func respond(to:generating:includeSchemaInPrompt:options:)`

`func respond(to:schema:includeSchemaInPrompt:options:)`

`struct Prompt`

A prompt from a person to the model.

`struct Response`

A structure that stores the output of a response call.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel

- Foundation Models
- SystemLanguageModel

Class

# SystemLanguageModel

An on-device large language model capable of text generation tasks.

final class SystemLanguageModel

## Mentioned in

Improving the safety of generative model output

Generating content and performing tasks with Foundation Models

Loading and using a custom adapter with Foundation Models

## Overview

The `SystemLanguageModel` refers to the on-device text foundation model that powers Apple Intelligence. Use `default` to access the base version of the model and perform general-purpose text generation tasks. To access a specialized version of the model, initialize the model with `SystemLanguageModel.UseCase` to perform tasks like `contentTagging`.

Verify the model availability before you use the model. Model availability depends on device factors like:

- The device must support Apple Intelligence.

- Apple Intelligence must be turned on in Settings.

Use `SystemLanguageModel.Availability` to change what your app shows to people based on the availability condition:

struct GenerativeView: View {
// Create a reference to the system language model.
private var model = SystemLanguageModel.default

var body: some View {
switch model.availability {
case .available:
// Show your intelligence UI.
case .unavailable(.deviceNotEligible):
// Show an alternative UI.
case .unavailable(.appleIntelligenceNotEnabled):
// Ask the person to turn on Apple Intelligence.
case .unavailable(.modelNotReady):
// The model isn't ready because it's downloading or because
// of other system reasons.
case .unavailable(let other):
// The model is unavailable for an unknown reason.
}
}
}

## Topics

### Loading the model with a use case

`convenience init(useCase: SystemLanguageModel.UseCase, guardrails: SystemLanguageModel.Guardrails)`

Creates a system language model for a specific use case.

`struct UseCase`

A type that represents the use case for prompting.

`struct Guardrails`

Guardrails flag sensitive content from model input and output.

### Loading the model with an adapter

Specialize the behavior of the system language model by using a custom adapter you train.

`com.apple.developer.foundation-model-adapter`

A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

`convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)`

Creates the base version of the model with an adapter.

`struct Adapter`

Specializes the system language model for custom use cases.

### Checking model availability

`var isAvailable: Bool`

A convenience getter to check if the system is entirely ready.

`var availability: SystemLanguageModel.Availability`

The availability of the language model.

`enum Availability`

The availability status for a specific system language model.

### Retrieving the supported languages

Languages that the model supports.

### Determining whether the model supports a locale

Returns a Boolean indicating whether the given locale is supported by the model.

### Getting the default model

``static let `default`: SystemLanguageModel``

The base version of the model.

## Relationships

### Conforms To

- `Copyable`
- `Observable`
- `Sendable`
- `SendableMetatype`

## See Also

### Essentials

Enhance the experience in your app by prompting an on-device large language model.

Create generative experiences that appropriately handle sensitive inputs and respect people.

Support languages and locales with Foundation Models

Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models

Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.property

- Foundation Models
- SystemLanguageModel
- availability

Instance Property

# availability

The availability of the language model.

final var availability: SystemLanguageModel.Availability { get }

## See Also

### Checking model availability

`var isAvailable: Bool`

A convenience getter to check if the system is entirely ready.

`enum Availability`

The availability status for a specific system language model.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(generating:includeschemainprompt:options:prompt:)

#app-main)

- Foundation Models
- LanguageModelSession
- respond(generating:includeSchemaInPrompt:options:prompt:)

Instance Method

# respond(generating:includeSchemaInPrompt:options:prompt:)

Produces a generable object as a response to a prompt.

@discardableResult nonisolated(nonsending)

generating type: Content.Type = Content.self,
includeSchemaInPrompt: Bool = true,
options: GenerationOptions = GenerationOptions(),

## Parameters

`type`

A type to produce as the response.

`includeSchemaInPrompt`

Inject the schema into the prompt to bias the model.

`options`

Options that control how tokens are sampled from the distribution the model produces.

`prompt`

A prompt for the model to respond to.

## Return Value

`GeneratedContent` containing the fields and values defined in the schema.

## Discussion

Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

### Generating a request

Produces a response to a prompt.

Produces a generated content type as a response to a prompt and schema.

`func respond(to:options:)`

`func respond(to:generating:includeSchemaInPrompt:options:)`

`func respond(to:schema:includeSchemaInPrompt:options:)`

`struct Prompt`

A prompt from a person to the model.

`struct Response`

A structure that stores the output of a response call.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/init(adapter:guardrails:)

#app-main)

- Foundation Models
- SystemLanguageModel
- init(adapter:guardrails:)

Initializer

# init(adapter:guardrails:)

Creates the base version of the model with an adapter.

convenience init(
adapter: SystemLanguageModel.Adapter,
guardrails: SystemLanguageModel.Guardrails = .default
)

## See Also

### Loading the model with an adapter

Loading and using a custom adapter with Foundation Models

Specialize the behavior of the system language model by using a custom adapter you train.

`com.apple.developer.foundation-model-adapter`

A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

`struct Adapter`

Specializes the system language model for custom use cases.

---

# https://developer.apple.com/documentation/foundationmodels/guide(description:)

#app-main)

- Foundation Models
- Guide(description:)

Macro

# Guide(description:)

Allows for influencing the allowed values of properties of a `Generable` type.

@attached(peer)
macro Guide(description: String)

## Mentioned in

Generating Swift data structures with guided generation

## Overview

## See Also

### Creating a guide

`macro Guide(description:_:)`

`struct GenerationGuide`

Guides that control how values are generated.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(schema:includeschemainprompt:options:prompt:)

#app-main)

- Foundation Models
- LanguageModelSession
- respond(schema:includeSchemaInPrompt:options:prompt:)

Instance Method

# respond(schema:includeSchemaInPrompt:options:prompt:)

Produces a generated content type as a response to a prompt and schema.

@discardableResult nonisolated(nonsending)
final func respond(
schema: GenerationSchema,
includeSchemaInPrompt: Bool = true,
options: GenerationOptions = GenerationOptions(),

## Parameters

`schema`

A schema to guide the output with.

`includeSchemaInPrompt`

Inject the schema into the prompt to bias the model.

`options`

Options that control how tokens are sampled from the distribution the model produces.

`prompt`

A prompt for the model to respond to.

## Return Value

`GeneratedContent` containing the fields and values defined in the schema.

## Discussion

Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

### Generating a request

Produces a response to a prompt.

Produces a generable object as a response to a prompt.

`func respond(to:options:)`

`func respond(to:generating:includeSchemaInPrompt:options:)`

`func respond(to:schema:includeSchemaInPrompt:options:)`

`struct Prompt`

A prompt from a person to the model.

`struct Response`

A structure that stores the output of a response call.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse(to:options:)

#app-main)

- Foundation Models
- LanguageModelSession
- streamResponse(to:options:)

Instance Method

# streamResponse(to:options:)

Produces a response stream to a prompt.

final func streamResponse(
to prompt: Prompt,
options: GenerationOptions = GenerationOptions()

Show all declarations

## Parameters

`prompt`

A specific prompt for the model to respond to.

`options`

GenerationOptions that control how tokens are sampled from the distribution the model produces.

## Return Value

A response stream that produces aggregated tokens.

## Discussion

## See Also

### Streaming a response

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream to a prompt and schema.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/default

- Foundation Models
- SystemLanguageModel
- default

Type Property

# default

The base version of the model.

static let `default`: SystemLanguageModel

## Mentioned in

Generating content and performing tasks with Foundation Models

## Discussion

The base model is a generic model that is useful for a wide variety of applications, but is not specialized to any particular use case.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse(options:prompt:)

#app-main)

- Foundation Models
- LanguageModelSession
- streamResponse(options:prompt:)

Instance Method

# streamResponse(options:prompt:)

Produces a response stream to a prompt.

final func streamResponse(
options: GenerationOptions = GenerationOptions(),

## Parameters

`options`

GenerationOptions that control how tokens are sampled from the distribution the model produces.

`prompt`

A specific prompt for the model to respond to.

## Return Value

A response stream that produces aggregated tokens.

## Discussion

## See Also

### Streaming a response

`func streamResponse(to:options:)`

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream to a prompt and schema.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(to:schema:includeschemainprompt:options:)

#app-main)

- Foundation Models
- LanguageModelSession
- respond(to:schema:includeSchemaInPrompt:options:)

Instance Method

# respond(to:schema:includeSchemaInPrompt:options:)

Produces a generated content type as a response to a prompt and schema.

@discardableResult nonisolated(nonsending)
final func respond(
to prompt: Prompt,
schema: GenerationSchema,
includeSchemaInPrompt: Bool = true,
options: GenerationOptions = GenerationOptions()

Show all declarations

## Parameters

`prompt`

A prompt for the model to respond to.

`schema`

A schema to guide the output with.

`includeSchemaInPrompt`

Inject the schema into the prompt to bias the model.

`options`

Options that control how tokens are sampled from the distribution the model produces.

## Return Value

`GeneratedContent` containing the fields and values defined in the schema.

## Discussion

Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

### Generating a request

Produces a response to a prompt.

Produces a generable object as a response to a prompt.

`func respond(to:options:)`

`func respond(to:generating:includeSchemaInPrompt:options:)`

`struct Prompt`

A prompt from a person to the model.

`struct Response`

A structure that stores the output of a response call.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/tool/arguments

- Foundation Models
- Tool
- Arguments

Associated Type

# Arguments

The arguments that this tool should accept.

associatedtype Arguments : ConvertibleFromGeneratedContent

**Required**

## Mentioned in

Expanding generation with tool calling

## Discussion

Typically arguments are either a `Generable` type or `GeneratedContent`.

## See Also

### Invoking a tool

A language model will call this method when it wants to leverage this tool.

`associatedtype Output : PromptRepresentable`

The output that this tool produces for the language model to reason about in subsequent interactions.

---

# https://developer.apple.com/documentation/foundationmodels/generable(description:)

#app-main)

- Foundation Models
- Generable(description:)

Macro

# Generable(description:)

Conforms a type to `Generable` protocol.

@attached(extension, conformances: Generable, names: named(init(_:)), named(generatedContent)) @attached(member, names: arbitrary)
macro Generable(description: String? = nil)

## Mentioned in

Generating Swift data structures with guided generation

## Overview

You can apply this macro to structures and enumerations.

@Generable
struct NovelIdea {
@Guide(description: "A short title")
let title: String

@Guide(description: "A short subtitle for the novel")
let subtitle: String

@Guide(description: "The genre of the novel")
let genre: Genre
}

@Generable
enum Genre {
case fiction
case nonFiction
}

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream

- Foundation Models
- LanguageModelSession
- LanguageModelSession.ResponseStream

Structure

# LanguageModelSession.ResponseStream

An async sequence of snapshots of partially generated content.

## Topics

### Collecting the response stream

The result from a streaming response, after it completes.

### Getting a snapshot of a partial response

`struct Snapshot`

A snapshot of partially generated content.

## Relationships

### Conforms To

- `AsyncSequence`
- `Copyable`

## See Also

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream to a prompt and schema.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/supportedlanguages

- Foundation Models
- SystemLanguageModel
- supportedLanguages

Instance Property

# supportedLanguages

Languages that the model supports.

## Mentioned in

Support languages and locales with Foundation Models

## Discussion

To check if a given locale is considered supported by the model, use `supportsLocale(_:)`, which will also take into consideration language fallbacks.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse(schema:includeschemainprompt:options:prompt:)

#app-main)

- Foundation Models
- LanguageModelSession
- streamResponse(schema:includeSchemaInPrompt:options:prompt:)

Instance Method

# streamResponse(schema:includeSchemaInPrompt:options:prompt:)

Produces a response stream to a prompt and schema.

final func streamResponse(
schema: GenerationSchema,
includeSchemaInPrompt: Bool = true,
options: GenerationOptions = GenerationOptions(),

## Parameters

`schema`

A schema to guide the output with.

`includeSchemaInPrompt`

Inject the schema into the prompt to bias the model.

`options`

Options that control how tokens are sampled from the distribution the model produces.

`prompt`

A prompt for the model to respond to.

## Return Value

A response stream that produces `GeneratedContent` containing the fields and values defined in the schema.

## Discussion

Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse(generating:includeschemainprompt:options:prompt:)

#app-main)

- Foundation Models
- LanguageModelSession
- streamResponse(generating:includeSchemaInPrompt:options:prompt:)

Instance Method

# streamResponse(generating:includeSchemaInPrompt:options:prompt:)

Produces a response stream for a type.

generating type: Content.Type = Content.self,
includeSchemaInPrompt: Bool = true,
options: GenerationOptions = GenerationOptions(),

## Parameters

`type`

A type to produce as the response.

`includeSchemaInPrompt`

Inject the schema into the prompt to bias the model.

`options`

Options that control how tokens are sampled from the distribution the model produces.

`prompt`

A prompt for the model to respond to.

## Return Value

A response stream.

## Discussion

Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream to a prompt and schema.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/support-languages-and-locales-with-foundation-models

- Foundation Models
- Support languages and locales with Foundation Models

Article

# Support languages and locales with Foundation Models

Generate content in the language people prefer when they interact with your app.

## Overview

The on-device system language model is multilingual, which means the same model understands and generates text in any language that Apple Intelligence supports. The model supports using different languages for prompts, instructions, and the output that the model produces.

When you enhance your app with multilingual support, generate content in the language people prefer to use when they interact with your app by:

- Prompting the model with the language you prefer.

- Including the target language for your app in the instructions you provide the model.

- Determining the language or languages a person wants to use when they interact with your app.

- Gracefully handling languages that Apple Intelligence doesn’t support.

For more information about the languages and locales that Apple Intelligence supports, see the “Supported languages” section in How to get Apple Intelligence.

## Prompt the model in the language you prefer

Write your app’s built-in prompts in the language with which you normally write code, if Apple Intelligence supports that language. Translate your prompts into a supported language if your preferred language isn’t supported. In the code below, _all_ inputs need to be in supported language for the model to understand, including all `Generable` types and descriptions:

@Generable(description: "Basic profile information about a cat")
struct CatProfile {
var name: String

@Guide(description: "The age of the cat", .range(0...20))
var age: Int

@Guide(description: "One sentence about this cat's personality")
var profile: String
}

#Playground {
let response = try await LanguageModelSession().respond(
to: "Generate a rescue cat",
generating: CatProfile.self
)
}

Because the framework treats `Generable` types as model inputs, the names of properties like `age` or `profile` are just as important as the `@Guide` descriptions for helping the model understand your request.

## Check a person’s language settings for your app

People can use the Settings app on their device to configure the language they prefer to use on a per-app basis, which might differ from their default language. If your app supports a language that Apple Intelligence doesn’t, you need to verify that the current language setting of your app is supported before you call the model. Keep in mind that language support improves over time in newer model and OS versions. Thus, someone using your app with an older OS may not have the latest language support.

Before you call the model, run `supportsLocale(_:)` to verify the support for a locale. By default, the method uses `current`, which takes into account a person’s current language and app-specific settings. This method returns true if the model supports this locale, or if this locale is considered similar enough to a supported locale, such as `en-AU` and `en-NZ`:

if SystemLanguageModel.default.supportsLocale() {
// Language is supported.
}

For advanced use cases where you need full language support details, use `supportedLanguages` to retrieve a list of languages supported by the on-device model.

## Handle an unsupported language or locale errors

When you call `respond(to:options:)` on a `LanguageModelSession`, the Foundation Models framework checks the language or languages of the input prompt text, and whether your prompt asks the model to respond in any specific language or languages. If the model detects a language it doesn’t support, the session throws `LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(_:)`. Handle the error by communicating to the person using your app that a language in their request is unsupported.

If your app supports languages or locales that Apple Intelligence doesn’t, help people that use your app by:

- Explaining that their language isn’t supported by Apple Intelligence in your app.

- Disabling your Foundation Models framework feature.

- Providing an alternative app experience, if possible.

## Use Instructions to set the locale and language

For locales other than United States English, you can improve response quality by telling the model which locale to use by detailing a set of `Instructions`. Start with the _exact_ phrase in English. This special phrase comes from the model’s training, and reduces the possibility of hallucinations in multilingual situations:

if Locale.Language(identifier: "en_US").isEquivalent(to: locale.language) {
// Skip the locale phrase for U.S. English.
return ""
} else {
// Specify the person's locale with the exact phrase format.
return "The person's locale is \(locale.identifier)."
}
}

After you set the locale in `Instructions`, you may need to explicitly set the model output language. By default, the model responds in the language or languages of its inputs. If your app supports multiple languages, prompts that you write and inputs from people using your app might be in different languages. For example, if you write your built-in prompts in Spanish, but someone using your app writes inputs in Dutch, the model may respond in either or both languages.

Use `Instructions` to explicity tell the model which language or languages with witch it needs to respond. You can phrase this request in different ways, for example: “You MUST respond in Italian” or “You MUST respond in Italian and be mindful of Italian spelling, vocabulary, entities, and other cultural contexts of Italy.” These instructions can be in the language you prefer.

let session = LanguageModelSession(
instructions: "You MUST respond in U.S. English."
)
let prompt = // A prompt that contains Spanish and Italian.
let response = try await session.respond(to: prompt)

Finally, thoroughly test your instructions to ensure the model is responding in the way you expect. If the model isn’t following your instructions, try capitalized words like “MUST” or “ALWAYS” to strengthen your instructions.

## See Also

### Essentials

Generating content and performing tasks with Foundation Models

Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output

Create generative experiences that appropriately handle sensitive inputs and respect people.

Adding intelligent app features with generative models

Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

`class SystemLanguageModel`

An on-device large language model capable of text generation tasks.

`struct UseCase`

A type that represents the use case for prompting.

---

# https://developer.apple.com/documentation/foundationmodels/improving-the-safety-of-generative-model-output

- Foundation Models
- Improving the safety of generative model output

Article

# Improving the safety of generative model output

Create generative experiences that appropriately handle sensitive inputs and respect people.

## Overview

Generative AI models have powerful creativity, but with this creativity comes the risk of unintended or unexpected results. For any generative AI feature, safety needs to be an essential part of your design.

The Foundation Models framework has two base layers of safety, where the framework uses:

- An on-device language model that has training to handle sensitive topics with care.

- _Guardrails_ that aim to block harmful or sensitive content, such as self-harm, violence, and adult materials, from both model input and output.

Because safety risks are often contextual, some harms might bypass both built-in framework safety layers. It’s vital to design additional safety layers specific to your app. When developing your feature, decide what’s acceptable or might be harmful in your generative AI feature, based on your app’s use case, cultural context, and audience.

## Handle guardrail errors

When you send a prompt to the model, `SystemLanguageModel.Guardrails` check the input prompt and the model’s output. If either fails the guardrail’s safety check, the model session throws a `LanguageModelSession.GenerationError.guardrailViolation(_:)` error:

do {
let session = LanguageModelSession()
let topic = // A potentially harmful topic.
let prompt = "Write a respectful and funny story about \(topic)."
let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.guardrailViolation {
// Handle the safety error.
}

If you encounter a guardrail violation error for any built-in prompt in your app, experiment with re-phrasing the prompt to determine which phrases are activating the guardrails, and avoid those phrases. If the error is thrown in response to a prompt created by someone using your app, give people a clear message that explains the issue. For example, you might say “Sorry, this feature isn’t designed to handle that kind of input” and offer people the opportunity to try a different prompt.

## Handle model refusals

The on-device language model may not be suitable for handling all requests and may refuse requests for a topic. When you generate a string response, and the model refuses a request, it generates a message that begins with a refusal like “Sorry, I can’t help with”.

Design your app experience with refusal messages in mind and present the message to the person using your app. You might not be able to programmatically determine whether a string response is a normal response or a refusal, so design the experience to anticipate both. If it’s critical to determine whether the response is a refusal message, initialize a new `LanguageModelSession` and prompt the model to classify whether the string is a refusal.

When you use guided generation to generate Swift structures or types, there’s no placeholder for a refusal message. Instead, the model throws a `LanguageModelSession.GenerationError.refusal(_:_:)` error. When you catch the error, you can ask the model to generate a string refusal message:

do {
let session = LanguageModelSession()
let topic = "" // A sensitive topic.
let response = try session.respond(
to: "List five key points about: \(topic)",
generating: [String].self
)
} catch LanguageModelSession.GenerationError.refusal(let refusal, _) {
// Generate an explanation for the refusal.
if let message = try? await refusal.explanation {
// Display the refusal message.
}
}

Display the explanation in your app to tell people why a request failed, and offer people the opportunity to try a different prompt. Retrieving an explanation message is asynchronous and takes time for the model to generate.

If you encounter a refusal message, or refusal error, for any built-in prompts in your app, experiment with re-phrasing your prompt to avoid any sensitive topics that might cause the refusal.

For more information about guided generation, see Generating Swift data structures with guided generation.

## Build boundaries on input and output

Safety risks increase when a prompt includes direct input from a person using your app, or from an unverified external source, like a webpage. An untrusted source makes it difficult to anticipate what the input contains. Whether accidentally or on purpose, someone could input sensitive content that causes the model to respond poorly.

Whenever possible, avoid open input in prompts and place boundaries for controlling what the input can be. This approach helps when you want generative content to stay within the bounds of a particular topic or task. For the highest level of safety on input, give people a fixed set of prompts to choose from. This gives you the highest certainty that sensitive content won’t make its way into your app:

enum TopicOptions {
case family
case nature
case work
}
let topicChoice = TopicOptions.nature
let prompt = """
Generate a wholesome and empathetic journal prompt that helps \
this person reflect on \(topicChoice)
"""

If your app allows people to freely input a prompt, placing boundaries on the output can also offer stronger safety guarantees. Using guided generation, create an enumeration to restrict the model’s output to a set of predefined options designed to be safe no matter what:

@Generable
enum Breakfast {
case waffles
case pancakes
case bagels
case eggs
}
let session = LanguageModelSession()
let userInput = "I want something sweet."
let prompt = "Pick the ideal breakfast for request: \(userInput)"
let response = try await session.respond(to: prompt, generating: Breakfast.self)

## Instruct the model for added safety

Consider adding detailed session `Instructions` that tell the model how to handle sensitive content. The language model prioritizes following its instructions over any prompt, so instructions are an effective tool for improving safety and overall generation quality. Use uppercase words to emphasize the importance of certain phrases for the model:

do {
let instructions = """
ALWAYS respond in a respectful way. \
If someone asks you to generate content that might be sensitive, \
you MUST decline with 'Sorry, I can't do that.'
"""
let session = LanguageModelSession(instructions: instructions)
let prompt = // Open input from a person using the app.
let response = try await session.respond(to: prompt)
} catch LanguageModelSession.GenerationError.guardrailViolation {
// Handle the safety error.
}

If you want to include open-input from people, instructions for safety are recommended. For an additional layer of safety, use a format string in normal prompts that wraps people’s input in your own content that specifies how the model should respond:

let userInput = // The input a person enters in the app.
let prompt = """
Generate a wholesome and empathetic journal prompt that helps \
this person reflect on their day. They said: \(userInput)
"""

## Add a deny list of blocked terms

If you allow prompt input from people or outside sources, consider adding your own deny list of terms. A deny list is anything you don’t want people to be able to input to your app, including unsafe terms, names of people or products, or anything that’s not relevant to the feature you provide. Implement a deny list similarly to guardrails by creating a function that checks the input and the model output:

let session = LanguageModelSession()
let userInput = // The input a person enters in the app.
let prompt = "Generate a wholesome story about: \(userInput)"

// A function you create that evaluates whether the input
// contains anything in your deny list.
if verifyText(prompt) {
let response = try await session.respond(to: prompt)

// Compare the output to evaluate whether it contains anything in your deny list.
if verifyText(response.content) {
return response
} else {
// Handle the unsafe output.
}
} else {
// Handle the unsafe input.
}

A deny list can be a simple list of strings in your code that you distribute with your app. Alternatively, you can host a deny list on a server so your app can download the latest deny list when it’s connected to the network. Hosting your deny list allows you to update your list when you need to and avoids requiring a full app update if a safety issue arise.

## Use permissive guardrail mode for sensitive content

The default `SystemLanguageModel` guardrails may throw a `LanguageModelSession.GenerationError.guardrailViolation(_:)` error for sensitive source material. For example, it may be appropriate for your app to work with certain inputs from people and unverified sources that might contain sensitive content:

- When you want the model to tag the topic of conversations in a chat app when some messages contain profanity.

- When you want to use the model to explain notes in your study app that discuss sensitive topics.

To allow the model to reason about sensitive source material, use `permissiveContentTransformations` when you initialize `SystemLanguageModel`:

let model = SystemLanguageModel(guardrails: .permissiveContentTransformations)

This mode only works for generating a string value. When you use guided generation, the framework runs the default guardrails against model input and output as usual, and generates `LanguageModelSession.GenerationError.guardrailViolation(_:)` and `LanguageModelSession.GenerationError.refusal(_:_:)` errors as usual.

Before you use permissive content mode, consider what’s appropriate for your audience. The session skips the guardrail checks in this mode, so it never throws a `LanguageModelSession.GenerationError.guardrailViolation(_:)` error when generating string responses.

However, even with the `SystemLanguageModel` guardrails off, the on-device system language model still has a layer of safety. For some content, the model may still produce a refusal message that’s similar to, “Sorry, I can’t help with.”

## Create a risk assessment

Conduct a risk assessment to proactively address what might go wrong. Risk assessment is an exercise that helps you brainstorm potential safety risks in your app and map each risk to an actionable mitigation. You can write a risk assessment in any format that includes these essential elements:

- List each AI feature in your app.

- For each feature, list possible safety risks that could occur, even if they seem unlikely.

- For each safety risk, score how serious the harm would be if that thing occurred, from mild to critical.

- For each safety risk, assign a strategy for how you’ll mitigate the risk in your app.

For example, an app might include one feature with the fixed-choice input pattern for generation and one feature with the open-input pattern for generation, which is higher safety risk:

| Feature | Harm | Severity | Mitigation |
| --- | --- | --- | --- |
| Player can input any text to chat with nonplayer characters in the coffee shop. | A character might respond in an insensitive or harmful way. | Critical | Instructions and prompting to steer characters responses to be safe; safety testing. |
| Image generation of an imaginary dream customer, like a fairy or a frog. | Generated image could look weird or scary. | Mild | Include in the prompt examples of images to generate that are cute and not scary; safety testing. |
| Player can make a coffee from a fixed menu of options. | None identified. | | |
| Generate a review of the coffee the player made, based on the customer’s order. | Review could be insulting. | Moderate | Instructions and prompting to encourage posting a polite review; safety testing. |

Besides obvious harms, like a poor-quality model output, think about how your generative AI feature might affect people, including real-world scenarios where someone might act based on information generated by your app.

## Write and maintain safety tests

Although most people will interact with your app in respectful ways, it’s important to anticipate possible failure modes where certain input or contexts could cause the model to generate something harmful. Especially if your app takes input from people, test your experience’s safety on input like:

- Input that is nonsensical, snippets of code, or random characters.

- Input that includes sensitive content.

- Input that includes controversial topics.

- Vague or unclear input that could be misinterpreted.

Create a list of potentially harmful prompt inputs that you can run as part of your app’s tests. Include every prompt in your app — even safe ones — as part of your app testing. For each prompt test, log the timestamp, full input prompt, the model’s response, and whether it activates any built-in safety or mitigations you’ve included in your app. When starting out, manually read the model’s response on all tests to ensure it meets your design and safety goals. To scale your tests, consider using a frontier LLM to auto-grade the safety of each prompt. Building a test pipeline for prompts and safety is a worthwhile investment for tracking changes in how your app responds over time.

Someone might purposefully attempt to break your feature or produce bad output — especially someone who won’t be harmed by their actions. But, keep in mind that it’s very important to identify cases where someone might _accidentally_ be harmed during normal app use.

Don’t engage in any testing that could cause you or others harm. Apple’s built-in responsible AI and safety measures, like safety guardrails, are built by experts with extensive training and support. These built-in measures aim to block egregious harms, allowing you to focus on the borderline harmful cases that need your judgement. Before conducting any safety testing, ensure that you’re in a safe location and that you have the health and well-being support you need.

## Report safety concerns

Somewhere in your app, it’s important to include a way that people can report potentially harmful content. Continuously monitor the feedback you receive, and be responsive to quickly handling any safety issues that arise. If someone reports a safety concern that you believe isn’t being properly handled by Apple’s built-in guardrails, report it to Apple with Feedback Assistant.

The Foundation Models framework offers utilities for feedback. Use `LanguageModelFeedback` to retrieve language model session transcripts from people using your app. After collecting feedback, you can serialize it into a JSON file and include it in the report you send with Feedback Assistant.

## Monitor safety for model or guardrail updates

Apple releases updates to the system model as part of regular OS updates. If you participate in the developer beta program you can test your app with new model version ahead of people using your app. When the model updates, it’s important to re-run your full prompt tests in addition to your adversarial safety tests because the model’s response may change. Your risk assessment can help you track any change to safety risks in your app.

Apple may update the built-in guardrails at any time outside of the regular OS update cycle. This is done to rapidly respond, for example, to reported safety concerns that require a fast response. Include all of the prompts you use in your app in your test suite, and run tests regularly to identify when prompts start activating the guardrails.

## See Also

### Essentials

Generating content and performing tasks with Foundation Models

Enhance the experience in your app by prompting an on-device large language model.

Support languages and locales with Foundation Models

Generate content in the language people prefer when they interact with your app.

Adding intelligent app features with generative models

Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

`class SystemLanguageModel`

An on-device large language model capable of text generation tasks.

`struct UseCase`

A type that represents the use case for prompting.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/streamresponse(to:generating:includeschemainprompt:options:)

#app-main)

- Foundation Models
- LanguageModelSession
- streamResponse(to:generating:includeSchemaInPrompt:options:)

Instance Method

# streamResponse(to:generating:includeSchemaInPrompt:options:)

Produces a response stream to a prompt and schema.

to prompt: Prompt,
generating type: Content.Type = Content.self,
includeSchemaInPrompt: Bool = true,
options: GenerationOptions = GenerationOptions()

Show all declarations

## Parameters

`prompt`

A prompt for the model to respond to.

`type`

A type to produce as the response.

`includeSchemaInPrompt`

Inject the schema into the prompt to bias the model.

`options`

Options that control how tokens are sampled from the distribution the model produces.

## Return Value

A response stream that produces `GeneratedContent` containing the fields and values defined in the schema.

## Discussion

Consider using the default value of `true` for `includeSchemaInPrompt`. The exception to the rule is when the model has knowledge about the expected response format, either because it has been trained on it, or because it has seen exhaustive examples during this session.

## See Also

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/loading-and-using-a-custom-adapter-with-foundation-models

- Foundation Models
- SystemLanguageModel
- Loading and using a custom adapter with Foundation Models

Article

# Loading and using a custom adapter with Foundation Models

Specialize the behavior of the system language model by using a custom adapter you train.

## Overview

Use an adapter to adapt the on-device foundation model to fit your specific use case without needing to retrain the entire model from scratch. Before you can load a custom adapter, you first need to train one with an adapter training toolkit. The toolkit uses Python and Pytorch, and requires familiarity with training machine-learning models. After you train an adapter, you can use the toolkit to export a package in the format that Xcode and the Foundation Models framework expects.

When you train an adapter you need to make it available for deployment into your app. An adapter file is large — 160 MB or more — so don’t bundle them in your app. Instead, use App Store Connect, or host the asset on your server, and download the correct adapter for a person’s device on-demand.

For more information about the adapter training toolkit, see Get started with Foundation Models adapter training. For more information about asset packs, see Background Assets.

## Test a local adapter in Xcode

After you train an adapter with the adapter training toolkit, store your `.fmadapter` package files in a different directory from your app. Then, open `.fmadapter` packages with Xcode to locally preview each adapter’s metadata and version compatibility before you deploy the adapter.

If you train multiple adapters:

1. Find the adapter package that’s compatible with the macOS version of the Mac on which you run Xcode.

2. Select the compatible adapter file in Finder.

3. Copy its full file path to the clipboard by pressing Option + Command + C.

4. Initialize `SystemLanguageModel.Adapter` with the file path.

// The absolute path to your adapter.
let localURL = URL(filePath: "absolute/path/to/my_adapter.fmadapter")

// Initialize the adapter by using the local URL.
let adapter = try SystemLanguageModel.Adapter(fileURL: localURL)

After you initialize an `Adapter`, create an instance of `SystemLanguageModel` with it:

// An instance of the the system language model using your adapter.
let customAdapterModel = SystemLanguageModel(adapter: adapter)

// Create a session and prompt the model.
let session = LanguageModelSession(model: customAdapterModel)
let response = try await session.respond(to: "Your prompt here")

Testing adapters requires a physical device and isn’t supported on Simulator. When you’re ready to deploy adapters in your app, you need the `com.apple.developer.foundation-model-adapter` entitlement. You don’t need this entitlement to train or locally test adapters. To request access to use the entitlement, log in to Apple Developer and see Foundation Models Framework Adapter Entitlement.

## Bundle adapters as asset packs

When people use your app they only need the specific adapter that’s compatible with their device. Host your adapter assets on a server and use Background Assets to manage downloads. For hosting, you can use your own server or have Apple host your adapter assets. For more information about Apple-hosted asset packs, see Overview of Apple-hosted asset packs.

The Background Assets framework has a type of asset pack specific to adapters that you create for the Foundation Models framework. The Foundation Models adapter training toolkit helps you bundle your adapters in the correct asset pack format. The toolkit uses the `ba-package` command line tool that’s included with Xcode 16 or later. If you train your adapters on a Linux GPU machine, see How to train adapters to set up a Python environment on your Mac. The adapter toolkit includes example code that shows how to create the asset pack in the correct format.

After you generate an asset pack for each adapter, upload the asset packs to your server. For more information about uploading Apple-hosted adapters, see Upload Apple-Hosted asset packs.

## Configure an asset-download target in Xcode

To download adapters at runtime, you need to add an asset-downloader extension target to your Xcode project:

2. Choose the Background Download template under the Application Extension section.

3. Click next.

4. Enter a descriptive name, like “AssetDownloader”, for the product name.

5. Select the type of extension.

6. Click Finish.

The type of extension depends on whether you self-host them or Apple hosts them:

Apple-Hosted, Managed

Apple hosts your adapter assets.

Self-Hosted, Managed

You use your server and make each device’s operating system automatically handle the download life cycle.

Self-Hosted, Unmanaged

You use your server and manage the download life cycle.

After you create an asset-downloader extension target, check that your app target’s info property list contains the required fields specific to your extension type:

- `BAHasManagedAssetPacks` = YES

- `BAAppGroupID` = The string ID of the app group that your app and downloader extension targets share.

- `BAUsesAppleHosting` = YES

If you use _Self-Hosted, Unmanaged_, then you don’t need additional keys. For more information about configuring background assets with an extension, see Configuring an unmanaged Background Assets project

## Choose a compatible adapter at runtime

When you create an asset-downloader extension, Xcode generates a Swift file — `BackgroundDownloadHandler.swift` — that Background Assets uses to download your adapters. Open the Swift file in Xcode and fill in the code based on your target type. For _Apple-Hosted, Managed_ or _Self-Hosted, Managed_ extension types, complete the function `shouldDownload` with the following code that chooses an adapter asset compatible with the runtime device:

// Check for any non-adapter assets your app has, like shaders. Remove the
// check if your app doesn't have any non-adapter assets.
if assetPack.id.hasPrefix("mygameshader") {
// Return false to filter out asset packs, or true to allow download.
return true
}

// Use the Foundation Models framework to check adapter compatibility with the runtime device.
return SystemLanguageModel.Adapter.isCompatible(assetPack)
}

If your extension type is _Self-Hosted, Unmanaged_, the file Xcode generates has many functions in it for manual control over the download life cycle of your assets.

## Load adapter assets in your app

After you configure an asset-downloader extension, you can start loading adapters. Before you download an adapter, remove any outdated adapters that might be on a person’s device:

SystemLanguageModel.Adapter.removeObsoleteAdapters()

Create an instance of `SystemLanguageModel.Adapter` using your adapter’s base name, but exclude the file extension. If a person’s device doesn’t have a compatible adapter downloaded, your asset-downloader extension starts downloading a compatible adapter asset pack:

let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")

Initializing a `SystemLanguageModel.Adapter` starts a download automatically when a person launches your app for the first time or their device needs an updated adapter. Because adapters can have a large data size they can take some time to download, especially if a person is on Wi-Fi or a cell network. If a person doesn’t have a network connection, they aren’t able to use your adapter right away. This method shows how to track the download status of an adapter:

// Get the ID of the compatible adapter.
let assetpackIDList = SystemLanguageModel.Adapter.compatibleAdapterIdentifiers(
name: name
)

if let assetPackID = assetpackIDList.first {
// Get the download status asynchronous sequence.
let statusUpdates = AssetPackManager.shared.statusUpdates(forAssetPackWithID: assetPackID)

// Use the current status to update any loading UI.
for await status in statusUpdates {
switch status {
case .began(let assetPack):
// The download started.
case .paused(let assetPack):
// The download is in a paused state.
case .downloading(let assetPack, let progress):
// The download in progress.
case .finished(let assetPack):
// The download is complete and the adapter is ready to use.
return true
case .failed(let assetPack, let error):
// The download failed.
return false
@unknown default:
// The download encountered an unknown status.
fatalError()
}
}
}
}

For more details on tracking downloads for general assets, see Downloading Apple-hosted asset packs.

Before you attempt to use the adapter, you need to wait for the status to be in a `AssetPackManager.DownloadStatusUpdate.finished(_:)` state. The system returns `AssetPackManager.DownloadStatusUpdate.finished(_:)` immediately if no download is necessary.

// Load the adapter.
let adapter = try SystemLanguageModel.Adapter(name: "myAdapter")

// Wait for download to complete.
if await checkAdapterDownload(name: "myAdapter") {
// Adapt the base model with your adapter.
let adaptedModel = SystemLanguageModel(adapter: adapter)

// Start a session with the adapted model.
let session = LanguageModelSession(model: adaptedModel)

// Start prompting the adapted model.
}

## Compile your draft model

A draft model is an optional step when training your adapter that can speed up inference. If your adapter includes a draft model, you can compile it for faster inference:

// Wait for download to complete.
if await checkAdapterDownload(name: "myAdapter") {
do {
// You can use your adapter without compiling the draft model, or during
// compilation, but running inference with your adapter might be slower.
try await adapter.compile()
} catch let error {
// Handle the draft model compilation error.
}
}

For more about training draft models, see the “Optionally train the draft model” section in Get started with Foundation Models adapter training.

Compiling a draft model is a computationally expensive step, so use the Background Tasks framework to configure a background task for your app. In your background task, call `compile()` on your adapter to start compilation. For more information about using background tasks, see Using background tasks to update your app.

Compilation doesn’t run every time a person uses your app:

- The first time a device downloads a new version of your adapter, a call to `compile()` fully compiles your draft model and saves it to the device.

- During subsequent launches of your app, a call to `compile()` checks for a saved compiled draft model and returns it immediately if it exists.

The full compilation process runs every time you launch your app through Xcode because Xcode assigns your app a new UUID for every launch. If you receive a rate-limiting error while testing your app, stop your app in Xcode and re-launch it to reset the rate counter.

## See Also

### Loading the model with an adapter

`com.apple.developer.foundation-model-adapter`

A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

`convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)`

Creates the base version of the model with an adapter.

`struct Adapter`

Specializes the system language model for custom use cases.

---

# https://developer.apple.com/documentation/foundationmodels/convertiblefromgeneratedcontent

- Foundation Models
- ConvertibleFromGeneratedContent

Protocol

# ConvertibleFromGeneratedContent

A type that can be initialized from generated content.

protocol ConvertibleFromGeneratedContent : SendableMetatype

## Topics

### Creating a convertable

`init(GeneratedContent) throws`

Creates an instance from content generated by a model.

**Required**

## Relationships

### Inherits From

- `SendableMetatype`

### Inherited By

- `Generable`

### Conforming Types

- `GeneratedContent`

## See Also

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream to a prompt and schema.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Availability

Enumeration

# SystemLanguageModel.Availability

The availability status for a specific system language model.

@frozen
enum Availability

## Overview

## Topics

### Checking for availability

`case available`

The system is ready for making requests.

`case unavailable(SystemLanguageModel.Availability.UnavailableReason)`

Indicates that the system is not ready for requests.

`enum UnavailableReason`

The unavailable reason.

## Relationships

### Conforms To

- `Equatable`
- `Sendable`
- `SendableMetatype`

## See Also

### Checking model availability

`var isAvailable: Bool`

A convenience getter to check if the system is entirely ready.

`var availability: SystemLanguageModel.Availability`

The availability of the language model.

---

# https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent

- Foundation Models
- ConvertibleToGeneratedContent

Protocol

# ConvertibleToGeneratedContent

A type that can be converted to generated content.

protocol ConvertibleToGeneratedContent : InstructionsRepresentable, PromptRepresentable

## Topics

### Getting the generated content

`var generatedContent: GeneratedContent`

This instance represented as generated content.

**Required**

## Relationships

### Inherits From

- `InstructionsRepresentable`
- `PromptRepresentable`

### Inherited By

- `Generable`

### Conforming Types

- `GeneratedContent`

## See Also

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream to a prompt and schema.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`struct GeneratedContent`

A type that represents structured, generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror

- Foundation Models
- LanguageModelSession
- LanguageModelSession.ToolCallError

Structure

# LanguageModelSession.ToolCallError

An error that occurs while a system language model is calling a tool.

struct ToolCallError

## Mentioned in

Expanding generation with tool calling

## Topics

### Creating a tool call error

`init(tool: any Tool, underlyingError: any Error)`

Creates a tool call error

### Getting the tool

`var tool: any Tool`

The tool that produced the error.

### Getting the error description

`var errorDescription: String?`

A string representation of the error description.

### Getting the underlying error

`var underlyingError: any Error`

The underlying error that was thrown during a tool call.

## Relationships

### Conforms To

- `Error`
- `LocalizedError`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the error types

`enum GenerationError`

An error that may occur while generating a response.

---

# https://developer.apple.com/documentation/foundationmodels/adding-intelligent-app-features-with-generative-models

- Foundation Models
- Adding intelligent app features with generative models

Sample Code

# Adding intelligent app features with generative models

Build robust apps with guided generation and tool calling by adopting the Foundation Models framework.

Download

Xcode 26.0+

## Overview

This sample project shows how to integrate generative AI capabilities into an app using the Foundation Models framework. The sample app showcases intelligent trip planning features that help people discover landmarks and generate personalized itineraries.

The app creates an interactive experience where people can:

- Browse curated landmarks with rich visual content

- Generate trip itineraries tailored to a chosen landmark

- Discover points of interest using a custom tool

- Experience real-time content generation with streaming responses

## Configure the sample code project

To run this sample, you’ll need to:

1. Set the developer team in Xcode for the app target so it automatically manages the provisioning profile. For more information, see Set the bundle ID and Assign the project to a team.

2. In the Developer portal, enable the WeatherKit app service for your bundle ID so the app can access location-based weather information.

## Check model availability

Before using the on-device model in the app, check that the model is available by creating an instance of `SystemLanguageModel` with the `default` property:

let landmark: Landmark
private let model = SystemLanguageModel.default

var body: some View {
switch model.availability {
case .available:
LandmarkTripView(landmark: landmark)
case .unavailable(.appleIntelligenceNotEnabled):
MessageView(
landmark: self.landmark,
message: """
Trip Planner is unavailable because \
Apple Intelligence hasn't been turned on.
"""
)
case .unavailable(.modelNotReady):
MessageView(
landmark: self.landmark,
message: "Trip Planner isn't ready yet. Try again later."
)
}
}

The app handles two unavailability scenarios: Apple Intelligence isn’t enabled or the model isn’t ready for usage. If Apple Intelligence is off, the app tells the person they need to turn it on and if the model isn’t ready, it tells the person the Trip Planner isn’t ready and to try the app again later.

## Define structured data for generation

The app starts by defining data structures with specific constraints to control what the model generates. The `Itinerary` type uses the `Generable` macro to create structured content that includes travel plans with activities, hotels, and restaurants.

The `@Generable` macro automatically converts Swift types into schemas that the model uses for constrained sampling, so you can specify guides to control the values you associate with it. For example, the app uses `Guide(description:)` to make sure the model creates an exciting name for the trip. It also uses `anyOf(_:)` and `count(_:)` to choose any destination from our `ModelData` and show exactly 3 `DayPlan` objects per destination, respectively.

@Generable
struct Itinerary: Equatable {
@Guide(description: "An exciting name for the trip.")
let title: String
@Guide(.anyOf(ModelData.landmarkNames))
let destinationName: String
let description: String
@Guide(description: "An explanation of how the itinerary meets the person's special requests.")
let rationale: String

@Guide(description: "A list of day-by-day plans.")
@Guide(.count(3))
let days: [DayPlan]
}

@Generable
struct DayPlan: Equatable {
@Guide(description: "A unique and exciting title for this day plan.")
let title: String
let subtitle: String
let destination: String

@Guide(.count(3))
let activities: [Activity]
}

@Generable
struct Activity: Equatable {
let type: Kind
let title: String
let description: String
}

@Generable
enum Kind {
case sightseeing
case foodAndDining
case shopping
case hotelAndLodging
}

The `@Generable` macro automatically creates two versions of each type: the complete structure and a `PartiallyGenerated` version which is a mirror of the outer structure except every property is optional. The app uses this `PartiallyGenerated` version when streaming and displaying the itinerary generation.

## Configure the model session

After checking that the model is available, the app configures a `LanguageModelSession` object with custom tools and detailed instructions in `ItineraryPlanner`. Given a location, the initializer creates the session with structured guidance for generating personalized trip recommendations.

init(landmark: Landmark) {
self.landmark = landmark
Logging.general.log("The landmark is... \(landmark.name)")
let pointOfInterestTool = FindPointsOfInterestTool(landmark: landmark)
self.session = LanguageModelSession(
tools: [pointOfInterestTool],
instructions: Instructions {
"Your job is to create an itinerary for the person."

"Each day needs an activity, hotel and restaurant."

"""
Always use the findPointsOfInterest tool to find businesses \
and activities in \(landmark.name), especially hotels \
and restaurants.

The point of interest categories may include:
"""
FindPointsOfInterestTool.categories

"""
Here is a description of \(landmark.name) for your reference \
when considering what activities to generate:
"""
landmark.description
}
)
self.pointOfInterestTool = pointOfInterestTool
}

In a generated itinerary, the model instructions ensure that each day contains an activity, hotel, and restaurant. To get the location-specific businesses and activities, the sample uses a custom tool, called `FindPointsOfInterestTool`, with the chosen landmark. The instructions also call the landmark description property as added context when generating the activities.

## Create a custom tool

You can use custom tools to extend the functionality of a model. Tool-calling allows the model to interact with external code you create to fetch up-to-date information, ground responses in sources of truth that you provide, and perform side effects.

The model in this app uses the `FindPointsOfInterestTool` tool to enable dynamic discovery of specific businesses and activities for the chosen landmark. The tool uses the `@Generable` macro to make its categories and arguments available to the model.

@Observable
final class FindPointsOfInterestTool: Tool {
let name = "findPointsOfInterest"
let description = "Finds points of interest for a landmark."

let landmark: Landmark

@MainActor var lookupHistory: [Lookup] = []

init(landmark: Landmark) {
self.landmark = landmark
}

@Generable
enum Category: String, CaseIterable {
case campground
case hotel
case cafe
case museum
case marina
case restaurant
case nationalMonument
}

@Generable
struct Arguments {
@Guide(description: "This is the type of destination to look up for.")
let pointOfInterest: Category

@Guide(description: "The natural language query of what to search for.")
let naturalLanguageQuery: String
}

When you prompt the model with a question or make a request, the model decides whether it can provide an answer or if it needs the help of a tool. The app explicitly instructs the model to always use the `findPointsOfInterestTool` in the `ItineraryPlanner` instructions. This allows the model to automatically call the tool to find relevant hotels, restaurants, and activities for the destinations.

## Stream and display partial responses in real time

The app shows real-time content generation by streaming partial responses from the model. The `ItineraryPlanner` uses `streamResponse(generating:includeSchemaInPrompt:options:prompt:)` to generate `Itinerary.PartiallyGenerated` objects so itinerary items are shown incrementally to the person.

You can opt for specific `GenerationOptions` to adjust the way the model generates these responses. For generating the itinerary, the app opts for a `greedy` sampling mode so the model always results in the same output for a given input. This ensures the prompt generates consistent recommendations for an itinerary specific to the given landmark.

private(set) var itinerary: Itinerary.PartiallyGenerated?

func suggestItinerary(dayCount: Int) async throws {
let stream = session.streamResponse(
generating: Itinerary.self,
includeSchemaInPrompt: false,
options: GenerationOptions(sampling: .greedy)
) {
"Generate a \(dayCount)-day itinerary to \(landmark.name)."

"Give it a fun title and description."

"Here is an example, but don't copy it:"
Itinerary.exampleTripToJapan
}

for try await partialResponse in stream {
itinerary = partialResponse.content
}
}

The app presents the responses in a SwiftUI view. The `ItineraryPlanningView` displays real-time visual feedback as the model searches for points of interest, showing people what’s happening when generating content:

ForEach(planner.pointOfInterestTool.lookupHistory) { element in
HStack {
Image(systemName: "location.magnifyingglass")
Text("Searching **\(element.history.pointOfInterest.rawValue)** in \(landmark.name)...")
}
.transition(.blurReplace)
}

The app displays messages like “Searching **hotel** in Yosemite…” and “Searching **restaurant** in Yosemite…” to let people know which point of interest category the model provided as input to the tool when actively searching for nearby points of interest. In the background, however, the tool executes and provides updates to the view. The view shows a blurred overlay while generating each day plan, then reveals the full itinerary after the search completes.

## Tag content dynamically

The app uses content tagging on the provided landmarks to help people quickly understand the characteristics of each destination. A content tagging model produces a list of categorizing tags based on the input text you provide. When you prompt the content tagging model, it produces a tag that uses one to a few lowercase words. The `LandmarkDescriptionView` prompts the content tagging model to automatically generate relevant hashtags for landmark descriptions, like `#nature`, `#hiking`, or `#scenic`, based on each landmark’s description. For more information on initializing content tagging, see Categorizing and organizing data with content tags.

let contentTaggingModel = SystemLanguageModel(useCase: .contentTagging)

.task {
if !contentTaggingModel.isAvailable { return }
do {
let session = LanguageModelSession(model: contentTaggingModel)
let stream = session.streamResponse(
to: landmark.description,
generating: TaggingResponse.self,
options: GenerationOptions(sampling: .greedy)
)
for try await newTags in stream {
generatedTags = newTags.content
}
} catch {
Logging.general.error("\(error.localizedDescription)")
}
}

## Integrate with other framework features

You can combine these generative model features with other Apple frameworks. For example, the `LocationLookup` class uses MapKit to search for addresses for our points of interest, showing how to combine model-generated content with weather information and location data for complete travel planning.

@Observable @MainActor
final class LocationLookup {
private(set) var item: MKMapItem?
private(set) var temperatureString: String?

func performLookup(location: String) {
Task {
let item = await self.mapItem(atLocation: location)
if let location = item?.location {
self.temperatureString = await self.weather(atLocation: location)
}
}
}

let request = MKLocalSearch.Request()
request.naturalLanguageQuery = location

let search = MKLocalSearch(request: request)
do {
return try await search.start().mapItems.first
} catch {
Logging.general.error("Failed to look up location: \(location). Error: \(error)")
}
return nil
}
}

The model generates location names as text, and the `LocationLookup` class converts them into real, mappable locations using the natural language search capabilities in MapKit.

## See Also

### Essentials

Generating content and performing tasks with Foundation Models

Enhance the experience in your app by prompting an on-device large language model.

Improving the safety of generative model output

Create generative experiences that appropriately handle sensitive inputs and respect people.

Support languages and locales with Foundation Models

Generate content in the language people prefer when they interact with your app.

`class SystemLanguageModel`

An on-device large language model capable of text generation tasks.

`struct UseCase`

A type that represents the use case for prompting.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/exceededcontextwindowsize(_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.exceededContextWindowSize(\_:)

Case

# LanguageModelSession.GenerationError.exceededContextWindowSize(\_:)

An error that signals the session reached its context window size limit.

case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)

## Mentioned in

Generating content and performing tasks with Foundation Models

## Discussion

This error occurs when you use the available tokens for the context window of 4,096 tokens. The token count includes instructions, prompts, and outputs for a session instance. A single token corresponds to approximately three to four characters in languages like English, Spanish, or German, and one token per character in languages like Japanese, Chinese, and Korean.

Start a new session when you exceed the content window size, and try again using a shorter prompt or shorter output length.

For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/generationoptions

- Foundation Models
- GenerationOptions

Structure

# GenerationOptions

Options that control how the model generates its response to a prompt.

struct GenerationOptions

## Mentioned in

Generating content and performing tasks with Foundation Models

## Overview

Generation options determine the decoding strategy the framework uses to adjust the way the model chooses output tokens. When you interact with the model, it converts your input to a token sequence, and uses it to generate the response.

Only use `maximumResponseTokens` when you need to protect against unexpectedly verbose responses. Enforcing a strict token response limit can lead to the model producing malformed results or gramatically incorrect responses.

All input to the model contributes tokens to the context window of the `LanguageModelSession` — including the `Instructions`, `Prompt`, `Tool`, and `Generable` types, and the model’s responses. If your session exceeds the available context size, it throws `LanguageModelSession.GenerationError.exceededContextWindowSize(_:)`. For more information on managing the context window size, see TN3193: Managing the on-device foundation model’s context window.

## Topics

### Creating options

`init(sampling: GenerationOptions.SamplingMode?, temperature: Double?, maximumResponseTokens: Int?)`

Creates generation options that control token sampling behavior.

### Configuring the response tokens

`var maximumResponseTokens: Int?`

The maximum number of tokens the model is allowed to produce in its response.

### Configuring the sampling mode

`var sampling: GenerationOptions.SamplingMode?`

A sampling strategy for how the model picks tokens when generating a response.

`struct SamplingMode`

A type that defines how values are sampled from a probability distribution.

### Configuring the temperature

`var temperature: Double?`

Temperature influences the confidence of the models response.

## Relationships

### Conforms To

- `Equatable`
- `Sendable`
- `SendableMetatype`

## See Also

### Prompting

`class LanguageModelSession`

An object that represents a session that interacts with a language model.

`struct Instructions`

Details you provide that define the model’s intended behavior on prompts.

`struct Prompt`

A prompt from a person to the model.

`struct Transcript`

A linear history of entries that reflect an interaction with a session.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError

Enumeration

# LanguageModelSession.GenerationError

An error that may occur while generating a response.

enum GenerationError

## Topics

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

### Getting the error description

`var errorDescription: String?`

A string representation of the error description.

### Getting the failure reason

`var failureReason: String?`

A string representation of the failure reason.

### Getting the recovery suggestion

`var recoverySuggestion: String?`

A string representation of the recovery suggestion.

## Relationships

### Conforms To

- `Error`
- `LocalizedError`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the error types

`struct ToolCallError`

An error that occurs while a system language model is calling a tool.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/logfeedbackattachment(sentiment:issues:desiredoutput:)

#app-main)

- Foundation Models
- LanguageModelSession
- logFeedbackAttachment(sentiment:issues:desiredOutput:)

Instance Method

# logFeedbackAttachment(sentiment:issues:desiredOutput:)

## Parameters

`sentiment`

A `LanguageModelFeedback.Sentiment` rating about the model’s output (positive, negative, or neutral).

`issues`

An array of specific `LanguageModelFeedback.Issue` you identify with the model’s response.

`desiredOutput`

A `Transcript` entry showing the output you expect.

## Return Value

A `Data` object containing the JSON-encoded attachment.

## Discussion

This method creates a structured attachment containing the session’s transcript and additional feedback information you provide. You can save the attachment data to a `.json` file and attach it when reporting feedback with Feedback Assistant.

If an error occurs during a previous response, the method includes any rejected entries that were rolled back from the transcript in the feedback data.

let session = LanguageModelSession()
let response = try await session.respond(to: "What is the capital of France?")

// Create feedback for a helpful response.
let helpfulFeedbackData = session.logFeedbackAttachment(sentiment: .positive)

// Create feedback for a problematic response.
let problematicFeedbackData = session.logFeedbackAttachment(
sentiment: .negative,
issues: [\
LanguageModelFeedback.Issue(\
category: .incorrect,\
explanation: "The model provided outdated information"\
)\
],
desiredOutput: Transcript.Entry.response(...)
)

If `desiredOutput` is a string, use `Transcript.Entry.response(_:)` to turn your desired output into a `Transcript` entry:

let text = Transcript.TextSegment(content: "The capital of France is Paris.")
let segment = Transcript.Segment.text(text)
let response = Transcript.Response(segments: [segment])
let entry = Transcript.Entry.response(response)

To create a transcript when `desiredOutput` is a `Generable` type:

let customType = MyCustomType(...) // A generable type.
let structure = Transcript.StructuredSegment(source: String(describing: Foo.self), content: customType.generatedContent)
let segment = Transcript.Segment.structure(structure)
let response = Transcript.Response(segments: [segment])
let entry = Transcript.Entry.response(response)

When you submit feed. You can include multiple feedback attachments in the same file:

let allFeedback = helpfulFeedbackData + problematicFeedbackData
let url = URL(fileURLWithPath: "path/to/save/feedback.jsonl")
try allFeedback.write(to: url)

## See Also

### Creating feedback

`struct Issue`

An issue with the model’s response.

`enum Sentiment`

A sentiment regarding the model’s response.

---

# https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable

- Foundation Models
- InstructionsRepresentable

Protocol

# InstructionsRepresentable

A type that can be represented as instructions.

protocol InstructionsRepresentable

## Topics

### Getting the representation

`var instructionsRepresentation: Instructions`

An instance that represents the instructions.

**Required** Default implementation provided.

## Relationships

### Inherited By

- `ConvertibleToGeneratedContent`
- `Generable`

### Conforming Types

- `GeneratedContent`
- `Instructions`

## See Also

### Creating instructions

`init(_:)`

`struct InstructionsBuilder`

A type that represents an instructions builder.

---

# https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema

- Foundation Models
- DynamicGenerationSchema

Structure

# DynamicGenerationSchema

The dynamic counterpart to the generation schema type that you use to construct schemas at runtime.

struct DynamicGenerationSchema

## Mentioned in

Generating Swift data structures with guided generation

## Overview

An individual schema may reference other schemas by name, and references are resolved when converting a set of dynamic schemas into a `GenerationSchema`.

## Topics

### Creating a dynamic schema

`init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`

Creates an array schema.

`init(name:description:anyOf:)`

Creates an any-of schema.

[`init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:))

Creates an object schema.

`init(referenceTo: String)`

Creates an refrence schema.

Creates a schema from a generable type and guides.

`struct Property`

A property that belongs to a dynamic generation schema.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response

- Foundation Models
- LanguageModelSession
- LanguageModelSession.Response

Structure

# LanguageModelSession.Response

A structure that stores the output of a response call.

## Topics

### Getting the response content

`let content: Content`

The response content.

`let rawContent: GeneratedContent`

The raw response content.

### Getting the transcript entries

The list of transcript entries.

## See Also

### Generating a request

Produces a response to a prompt.

Produces a generable object as a response to a prompt.

Produces a generated content type as a response to a prompt and schema.

`func respond(to:options:)`

`func respond(to:generating:includeSchemaInPrompt:options:)`

`func respond(to:schema:includeSchemaInPrompt:options:)`

`struct Prompt`

A prompt from a person to the model.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/generationschema

- Foundation Models
- GenerationSchema

Structure

# GenerationSchema

A type that describes the properties of an object and any guides on their values.

struct GenerationSchema

## Mentioned in

Generating Swift data structures with guided generation

## Overview

Generation schemas guide the output of a `SystemLanguageModel` to deterministically ensure the output is in the desired format.

## Topics

### Creating a generation schema

[`init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws`](https://developer.apple.com/documentation/foundationmodels/generationschema/init(root:dependencies:))

Creates a schema by providing an array of dynamic schemas.

`init(type:description:anyOf:)`

Creates a schema for a string enumeration.

[`init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/generationschema/init(type:description:properties:))

Creates a schema by providing an array of properties.

`struct Property`

A property that belongs to a generation schema.

### Getting the debug description

`var debugDescription: String`

A string representation of the debug description.

### Getting the generation schema error types

`enum SchemaError`

A error that occurs when there is a problem creating a generation schema.

## Relationships

### Conforms To

- `CustomDebugStringConvertible`
- `Decodable`
- `Encodable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the schema

`static var generationSchema: GenerationSchema`

An instance of the generation schema.

**Required**

---

# https://developer.apple.com/documentation/foundationmodels/instructionsbuilder

- Foundation Models
- InstructionsBuilder

Structure

# InstructionsBuilder

A type that represents an instructions builder.

@resultBuilder
struct InstructionsBuilder

## Topics

### Building instructions

Creates a builder with the an array of prompts.

Creates a builder with the a block.

Creates a builder with the first component.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

## See Also

### Creating instructions

`init(_:)`

`protocol InstructionsRepresentable`

A type that can be represented as instructions.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Adapter

Structure

# SystemLanguageModel.Adapter

Specializes the system language model for custom use cases.

struct Adapter

## Mentioned in

Loading and using a custom adapter with Foundation Models

## Overview

Use the base system model for most prompt engineering, guided generation, and tools. If you need to specialize the model, train a custom `Adapter` to alter the system model weights and optimize it for your custom task. Use custom adapters only if you’re comfortable training foundation models in Python.

For more on custom adapters, see Get started with Foundation Models adapter training.

## Topics

### Creating an adapter

Specialize the behavior of the system language model by using a custom adapter you train.

`com.apple.developer.foundation-model-adapter`

A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

`init(fileURL: URL) throws`

Creates an adapter from the file URL.

`init(name: String) throws`

Creates an adapter downloaded from the background assets framework.

### Prepare the adapter

`func compile() async throws`

Prepares an adapter before being used with a `LanguageModelSession`. You should call this if your adapter has a draft model.

### Getting the metadata

[`var creatorDefinedMetadata: [String : Any]`](https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/creatordefinedmetadata)

Values read from the creator defined field of the adapter’s metadata.

### Removing obsolete adapters

`static func removeObsoleteAdapters() throws`

Remove all obsolete adapters that are no longer compatible with current system models.

### Checking compatibility

Get all compatible adapter identifiers compatible with current system models.

Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.

### Getting the asset error

`enum AssetError`

## See Also

### Loading the model with an adapter

`convenience init(adapter: SystemLanguageModel.Adapter, guardrails: SystemLanguageModel.Guardrails)`

Creates the base version of the model with an adapter.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/value(_:forproperty:)-3xsez

-3xsez#app-main)

- Foundation Models
- GeneratedContent
- value(\_:forProperty:)

Instance Method

# value(\_:forProperty:)

Reads a concrete `Generable` type from named property.

_ type: Value.Type = Value.self,
forProperty property: String

Show all declarations

## Mentioned in

Generating Swift data structures with guided generation

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent

- Foundation Models
- GeneratedContent

Structure

# GeneratedContent

A type that represents structured, generated content.

struct GeneratedContent

## Mentioned in

Expanding generation with tool calling

Generating Swift data structures with guided generation

## Overview

Generated content may contain a single value, an array, or key-value pairs with unique keys.

## Topics

### Creating generated content

`init(_:)`

Creates generated content from another value.

`init(some ConvertibleToGeneratedContent, id: GenerationID)`

Creates content that contains a single value with a custom `GenerationID`.

Creates content representing an array of elements you specify.

`init(kind: GeneratedContent.Kind, id: GenerationID?)`

Creates a new `GeneratedContent` instance with the specified kind and `GenerationID`.

### Creating content from properties

Creates generated content representing a structure with the properties you specify.

Creates new generated content from the key-value pairs in the given sequence, using a combining closure to determine the value for any duplicate keys.

### Creating content from JSON

`init(json: String) throws`

Creates equivalent content from a JSON string.

### Creating content from kind

`enum Kind`

The representation of the generated content.

### Accessing instance properties

`var kind: GeneratedContent.Kind`

The kind representation of this generated content.

`var isComplete: Bool`

A Boolean that indicates whether the generated content is completed.

`var jsonString: String`

Returns a JSON string representation of the generated content.

### Getting the debug description

`var debugDescription: String`

A string representation for the debug description.

### Reads a value from the concrete type

Reads a top level, concrete partially `Generable` type from a named property.

`func value(_:forProperty:)`

Reads a concrete `Generable` type from named property.

### Retrieving the schema and content

`var generatedContent: GeneratedContent`

A representation of this instance.

### Getting the unique generation id

`var id: GenerationID?`

A unique id that is stable for the duration of a generated response.

## Relationships

### Conforms To

- `ConvertibleFromGeneratedContent`
- `ConvertibleToGeneratedContent`
- `CustomDebugStringConvertible`
- `Equatable`
- `Generable`
- `InstructionsRepresentable`
- `PromptRepresentable`
- `Sendable`
- `SendableMetatype`

## See Also

### Streaming a response

`func streamResponse(to:options:)`

Produces a response stream to a prompt.

`func streamResponse(to:generating:includeSchemaInPrompt:options:)`

Produces a response stream to a prompt and schema.

`func streamResponse(to:schema:includeSchemaInPrompt:options:)`

Produces a response stream for a type.

`struct ResponseStream`

An async sequence of snapshots of partially generated content.

`protocol ConvertibleFromGeneratedContent`

A type that can be initialized from generated content.

`protocol ConvertibleToGeneratedContent`

A type that can be converted to generated content.

---

# https://developer.apple.com/documentation/foundationmodels/transcript

- Foundation Models
- Transcript

Structure

# Transcript

A linear history of entries that reflect an interaction with a session.

struct Transcript

## Mentioned in

Generating content and performing tasks with Foundation Models

## Overview

Use a `Transcript` to visualize previous instructions, prompts and model responses. If you use tool calling, a `Transcript` includes a history of tool calls and their results.

struct HistoryView: View {
let session: LanguageModelSession

var body: some View {
ScrollView {
ForEach(session.transcript) { entry in
switch entry {
case let .instructions(instructions):
MyInstructionsView(instructions)
case let .prompt(prompt)
MyPromptView(prompt)
case let .toolCalls(toolCalls):
MyToolCallsView(toolCalls)
case let .toolOutput(toolOutput):
MyToolOutputView(toolOutput)
case let .response(response):
MyResponseView(response)
}
}
}
}
}

When you create a new `LanguageModelSession` it doesn’t contain the state of a previous session. You can initialize a new session with a list of entries you get from a session `transcript`:

// Create a new session with the first and last entries from a previous session.

let allEntries = originalSession.transcript

// Collect the entries to keep from the original session.
let entries = [allEntries.first, allEntries.last].compactMap { $0 }
let transcript = Transcript(entries: entries)

// Create a new session with the result and preload the session resources.
var session = LanguageModelSession(transcript: transcript)
session.prewarm()
return session
}

## Topics

### Creating a transcript

Creates a transcript.

`enum Entry`

An entry in a transcript.

`enum Segment`

The types of segments that may be included in a transcript entry.

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

### Conforms To

- `BidirectionalCollection`
- `Collection`
- `Copyable`
- `Decodable`
- `Encodable`
- `Equatable`
- `RandomAccessCollection`
- `Sendable`
- `SendableMetatype`
- `Sequence`

## See Also

### Prompting

`class LanguageModelSession`

An object that represents a session that interacts with a language model.

Details you provide that define the model’s intended behavior on prompts.

A prompt from a person to the model.

`struct GenerationOptions`

Options that control how the model generates its response to a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/prompt/init(_:)

#app-main)

- Foundation Models
- Prompt
- init(\_:)

Initializer

# init(\_:)

Show all declarations

## See Also

### Creating a prompt

`struct PromptBuilder`

A type that represents a prompt builder.

`protocol PromptRepresentable`

A type whose value can represent a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails/default

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Guardrails
- default

Type Property

# default

Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a `LanguageModelSession.GenerationError.guardrailViolation` error.

static let `default`: SystemLanguageModel.Guardrails

## See Also

### Getting the guardrail types

`static let permissiveContentTransformations: SystemLanguageModel.Guardrails`

Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.

---

# https://developer.apple.com/documentation/foundationmodels/tool/output

- Foundation Models
- Tool
- Output

Associated Type

# Output

The output that this tool produces for the language model to reason about in subsequent interactions.

associatedtype Output : PromptRepresentable

**Required**

## Discussion

Typically output is either a `String` or a `Generable` type.

## See Also

### Invoking a tool

A language model will call this method when it wants to leverage this tool.

`associatedtype Arguments : ConvertibleFromGeneratedContent`

The arguments that this tool should accept.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/collect()

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.ResponseStream
- collect()

Instance Method

# collect()

The result from a streaming response, after it completes.

nonisolated(nonsending)

Available when `Content` conforms to `Generable`.

## Discussion

If the streaming response was finished successfully before calling `collect()`, this method `Response` returns immediately.

If the streaming response was finished with an error before calling `collect()`, this method propagates that error.

---

# https://developer.apple.com/documentation/foundationmodels/generable/generationschema

- Foundation Models
- Generable
- generationSchema

Type Property

# generationSchema

An instance of the generation schema.

static var generationSchema: GenerationSchema { get }

**Required**

## See Also

### Getting the schema

`struct GenerationSchema`

A type that describes the properties of an object and any guides on their values.

---

# https://developer.apple.com/documentation/foundationmodels/generable/partiallygenerated

- Foundation Models
- Generable
- PartiallyGenerated

Associated Type

# PartiallyGenerated

A representation of partially generated content

associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self

**Required** Default implementation provided.

## Default Implementations

### Generable Implementations

`typealias PartiallyGenerated`

## See Also

### Converting to partially generated

The partially generated type of this struct.

---

# https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(arrayof:minimumelements:maximumelements:)

#app-main)

- Foundation Models
- DynamicGenerationSchema
- init(arrayOf:minimumElements:maximumElements:)

Initializer

# init(arrayOf:minimumElements:maximumElements:)

Creates an array schema.

init(
arrayOf itemSchema: DynamicGenerationSchema,
minimumElements: Int? = nil,
maximumElements: Int? = nil
)

## See Also

### Creating a dynamic schema

`init(name:description:anyOf:)`

Creates an any-of schema.

[`init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:))

Creates an object schema.

`init(referenceTo: String)`

Creates an refrence schema.

Creates a schema from a generable type and guides.

`struct Property`

A property that belongs to a dynamic generation schema.

---

# https://developer.apple.com/documentation/foundationmodels/promptrepresentable

- Foundation Models
- PromptRepresentable

Protocol

# PromptRepresentable

A type whose value can represent a prompt.

protocol PromptRepresentable

## Overview

For types that are not `Generable`, you may provide your own implementation.

Experiment with different representations to find one that works well for your type. Generally, any format that is easily understandable to humans will work well for the model as well.

struct FamousHistoricalFigure: PromptRepresentable {
var name: String
var biggestAccomplishment: String

var promptRepresentation: Prompt {
"""
Famous Historical Figure:
- name: \(name)
- best known for: \(biggestAccomplishment)
"""
}
}

let response = try await LanguageModelSession().respond {
"Tell me more about..."
FamousHistoricalFigure(
name: "Albert Einstein",
biggestAccomplishment: "Theory of Relativity"
)
}

## Topics

### Getting the representation

`var promptRepresentation: Prompt`

An instance that represents a prompt.

**Required** Default implementation provided.

## Relationships

### Inherited By

- `ConvertibleToGeneratedContent`
- `Generable`

### Conforming Types

- `GeneratedContent`
- `Prompt`

## See Also

### Creating a prompt

`init(_:)`

`struct PromptBuilder`

A type that represents a prompt builder.

---

# https://developer.apple.com/documentation/foundationmodels/generationid

- Foundation Models
- GenerationID

Structure

# GenerationID

A unique identifier that is stable for the duration of a response, but not across responses.

struct GenerationID

## Overview

The framework guarantees a `GenerationID` to be both present and stable when you receive it from a `LanguageModelSession`. When you create an instance of `GenerationID` there is no guarantee an identifier is present or stable.

@Generable
struct Person: Equatable {
var name: String
}

struct PeopleView: View {
@State private var session = LanguageModelSession()
@State private var people = Person.PartiallyGenerated

var body: some View {
// A person's name changes as the response is generated,
// and two people can have the same name, so it's not suitable
// for use as an id.
//
// `GenerationID` receives special treatment and is guaranteed
// to be both present and stable.
List {
// The framework generates each instance with a `GenerationID`.
ForEach(people, id: \.id) { person in
Text("Name: \(person.name ?? "")")
}
}
.task {
do {
for try await people in session.streamResponse(
to: "Who were the first 3 presidents of the US?",
generating: [Person].self
) {
withAnimation {
self.people = people.content
}
}
} catch {
// Handle the thrown error.
}
}
}
}

## Topics

### Creating an identifier

`init()`

Create a new, unique `GenerationID`.

## Relationships

### Conforms To

- `Equatable`
- `Hashable`
- `Sendable`
- `SendableMetatype`

---

# https://developer.apple.com/documentation/foundationmodels/tool/parameters

- Foundation Models
- Tool
- parameters

Instance Property

# parameters

A schema for the parameters this tool accepts.

var parameters: GenerationSchema { get }

**Required** Default implementation provided.

## Default Implementations

### Tool Implementations

`var parameters: GenerationSchema`

## See Also

### Getting the tool properties

`var description: String`

A natural language description of when and how to use the tool.

**Required**

`var includesSchemaInInstructions: Bool`

If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

`var name: String`

A unique name for the tool, such as “get\_weather”, “toggleDarkMode”, or “search contacts”.

---

# https://developer.apple.com/documentation/foundationmodels/tool/name

- Foundation Models
- Tool
- name

Instance Property

# name

A unique name for the tool, such as “get\_weather”, “toggleDarkMode”, or “search contacts”.

var name: String { get }

**Required** Default implementation provided.

## Default Implementations

### Tool Implementations

`var name: String`

## See Also

### Getting the tool properties

`var description: String`

A natural language description of when and how to use the tool.

**Required**

`var includesSchemaInInstructions: Bool`

If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

`var parameters: GenerationSchema`

A schema for the parameters this tool accepts.

---

# https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:anyof:)

#app-main)

- Foundation Models
- DynamicGenerationSchema
- init(name:description:anyOf:)

Initializer

# init(name:description:anyOf:)

Creates an any-of schema.

init(
name: String,
description: String? = nil,
anyOf choices: [DynamicGenerationSchema]
)

Show all declarations

## Parameters

`name`

A name this schema can be referenecd by.

`description`

A natural language description of this `DynamicGenerationSchema`.

`choices`

An array of schemas this one will be a union of.

## See Also

### Creating a dynamic schema

`init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`

Creates an array schema.

[`init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:))

Creates an object schema.

`init(referenceTo: String)`

Creates an refrence schema.

Creates a schema from a generable type and guides.

`struct Property`

A property that belongs to a dynamic generation schema.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/unsupportedlanguageorlocale(_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(\_:)

Case

# LanguageModelSession.GenerationError.unsupportedLanguageOrLocale(\_:)

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)

## Mentioned in

Support languages and locales with Foundation Models

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/generationschema/init(type:description:properties:)

#app-main)

- Foundation Models
- GenerationSchema
- init(type:description:properties:)

Initializer

# init(type:description:properties:)

Creates a schema by providing an array of properties.

init(
type: any Generable.Type,
description: String? = nil,
properties: [GenerationSchema.Property]
)

## Parameters

`type`

The type this schema represents.

`description`

A natural language description of this schema.

`properties`

An array of properties.

## See Also

### Creating a generation schema

[`init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws`](https://developer.apple.com/documentation/foundationmodels/generationschema/init(root:dependencies:))

Creates a schema by providing an array of dynamic schemas.

`init(type:description:anyOf:)`

Creates a schema for a string enumeration.

`struct Property`

A property that belongs to a generation schema.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror/tool

- Foundation Models
- LanguageModelSession
- LanguageModelSession.ToolCallError
- tool

Instance Property

# tool

The tool that produced the error.

var tool: any Tool

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/init(elements:id:)

#app-main)

- Foundation Models
- GeneratedContent
- init(elements:id:)

Initializer

# init(elements:id:)

Creates content representing an array of elements you specify.

elements: S,
id: GenerationID? = nil
) where S : Sequence, S.Element == any ConvertibleToGeneratedContent

## See Also

### Creating generated content

`init(_:)`

Creates generated content from another value.

`init(some ConvertibleToGeneratedContent, id: GenerationID)`

Creates content that contains a single value with a custom `GenerationID`.

`init(kind: GeneratedContent.Kind, id: GenerationID?)`

Creates a new `GeneratedContent` instance with the specified kind and `GenerationID`.

---

# https://developer.apple.com/documentation/foundationmodels/tool/description

- Foundation Models
- Tool
- description

Instance Property

# description

A natural language description of when and how to use the tool.

var description: String { get }

**Required**

## See Also

### Getting the tool properties

`var includesSchemaInInstructions: Bool`

If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

**Required** Default implementation provided.

`var name: String`

A unique name for the tool, such as “get\_weather”, “toggleDarkMode”, or “search contacts”.

`var parameters: GenerationSchema`

A schema for the parameters this tool accepts.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/guardrails/permissivecontenttransformations

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Guardrails
- permissiveContentTransformations

Type Property

# permissiveContentTransformations

Guardrails that allow for permissively transforming text input, including potentially unsafe content, to text responses, such as summarizing an article.

static let permissiveContentTransformations: SystemLanguageModel.Guardrails

## Mentioned in

Improving the safety of generative model output

## Discussion

In this mode, requests you make to the model that generate a `String` will not throw `LanguageModelSession.GenerationError.guardrailViolation` errors. However, when the purpose of your instructions and prompts is not transforming user input, the model may still refuse to respond to potentially unsafe prompts by generating an explanation.

When you generate responses other than `String`, this mode behaves the same way as `.default`.

## See Also

### Getting the guardrail types

``static let `default`: SystemLanguageModel.Guardrails``

Default guardrails. This mode ensures that unsafe content in prompts and responses will be blocked with a `LanguageModelSession.GenerationError.guardrailViolation` error.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/segment

- Foundation Models
- Transcript
- Transcript.Segment

Enumeration

# Transcript.Segment

The types of segments that may be included in a transcript entry.

enum Segment

## Topics

### Creating a segment

`case structure(Transcript.StructuredSegment)`

A segment containing structured content.

`case text(Transcript.TextSegment)`

A segment containing text.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Creating a transcript

Creates a transcript.

`enum Entry`

An entry in a transcript.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment

- Foundation Models
- LanguageModelFeedback
- LanguageModelFeedback.Sentiment

Enumeration

# LanguageModelFeedback.Sentiment

A sentiment regarding the model’s response.

enum Sentiment

## Topics

### Getting sentiment

`case negative`

A negative sentiment

`case neutral`

A neutral sentiment

`case positive`

A positive sentiment

## Relationships

### Conforms To

- `CaseIterable`
- `Copyable`
- `Equatable`
- `Hashable`
- `Sendable`
- `SendableMetatype`

## See Also

### Creating feedback

`struct Issue`

An issue with the model’s response.

Logs and serializes data that includes session information that you attach when reporting feed

---

# https://developer.apple.com/documentation/foundationmodels/promptbuilder

- Foundation Models
- PromptBuilder

Structure

# PromptBuilder

A type that represents a prompt builder.

@resultBuilder
struct PromptBuilder

## Topics

### Building a prompt

Creates a builder with the an array of prompts.

Creates a builder with the a block.

Creates a builder with the first component.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

## See Also

### Creating a prompt

`init(_:)`

`protocol PromptRepresentable`

A type whose value can represent a prompt.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/iscompatible(_:)

#app-main)

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Adapter
- isCompatible(\_:)

Type Method

# isCompatible(\_:)

Returns a Boolean value that indicates whether an asset pack is an on-device foundation model adapter and is compatible with the system base model version on the runtime device.

## Discussion

Use this check when choosing an adapter asset pack to download. This check only validates the asset pack name and metadata, so initializing the adapter with `init(name:)` — or loading the adapter onto the base model with `init(adapter:guardrails:)` — may throw errors if the adapter has a compatibility issue despite having correct metadata.

## See Also

### Checking compatibility

Get all compatible adapter identifiers compatible with current system models.

---

# https://developer.apple.com/documentation/foundationmodels/tool/includesschemaininstructions

- Foundation Models
- Tool
- includesSchemaInInstructions

Instance Property

# includesSchemaInInstructions

If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

var includesSchemaInInstructions: Bool { get }

**Required** Default implementation provided.

## Discussion

The default implementation is `true`

## Default Implementations

### Tool Implementations

`var includesSchemaInInstructions: Bool`

## See Also

### Getting the tool properties

`var description: String`

A natural language description of when and how to use the tool.

**Required**

`var name: String`

A unique name for the tool, such as “get\_weather”, “toggleDarkMode”, or “search contacts”.

`var parameters: GenerationSchema`

A schema for the parameters this tool accepts.

---

# https://developer.apple.com/documentation/foundationmodels/generationguide

- Foundation Models
- GenerationGuide

Structure

# GenerationGuide

Guides that control how values are generated.

## Mentioned in

Categorizing and organizing data with content tags

## Topics

### Getting the pattern

Enforces that the string follows the pattern.

### Getting the element

Enforces a guide on the elements within the array.

### Getting the count

`static count(_:)`

Enforces that the array has exactly a certain number elements.

### Getting the constant

Enforces that the string be precisely the given value.

Enforces that the string be one of the provided values.

### Getting a range

`static range(_:)`

Enforces values fall within a range.

### Getting the minimum value

`static minimum(_:)`

Enforces a minimum value.

Enforces a minimum number of elements in the array.

### Getting the maximum value

`static maximum(_:)`

Enforces a maximum value.

Enforces a maximum number of elements in the array.

## See Also

### Creating a guide

`macro Guide(description: String)`

Allows for influencing the allowed values of properties of a `Generable` type.

`macro Guide(description:_:)`

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/guardrailviolation(_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.guardrailViolation(\_:)

Case

# LanguageModelSession.GenerationError.guardrailViolation(\_:)

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

case guardrailViolation(LanguageModelSession.GenerationError.Context)

## Mentioned in

Improving the safety of generative model output

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/generationguide/maximumcount(_:)

#app-main)

- Foundation Models
- GenerationGuide
- maximumCount(\_:)

Type Method

# maximumCount(\_:)

Enforces a maximum number of elements in the array.

## Mentioned in

Categorizing and organizing data with content tags

## Discussion

The bounds are inclusive.

A `maximumCount` generation guide may be used when you want to ensure the model produces a number of array elements less than or equal to to some maximum value, such as the number of items in a game’s shop.

@Generable
struct struct Shop {
@Guide(description: "A creative name for a shop in a fantasy RPG"
var name: String

@Guide(description: "A list of items for sale", .maximumCount(10))
var inventory: [ShopItem]
}

## See Also

### Getting the maximum value

`static maximum(_:)`

Enforces a maximum value.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/respond(to:options:)-6a2gb

-6a2gb#app-main)

- Foundation Models
- LanguageModelSession
- respond(to:options:)

Instance Method

# respond(to:options:)

Produces a response to a prompt.

@discardableResult nonisolated(nonsending)
final func respond(
to prompt: Prompt,
options: GenerationOptions = GenerationOptions()

Show all declarations

## Parameters

`prompt`

A prompt for the model to respond to.

`options`

GenerationOptions that control how tokens are sampled from the distribution the model produces.

## Return Value

A string composed of the tokens produced by sampling model output.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/issue

- Foundation Models
- LanguageModelFeedback
- LanguageModelFeedback.Issue

Structure

# LanguageModelFeedback.Issue

An issue with the model’s response.

struct Issue

## Topics

### Initializing an issue

`init(category: LanguageModelFeedback.Issue.Category, explanation: String?)`

Creates a new issue

`enum Category`

Categories for model response issues.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Creating feedback

`enum Sentiment`

A sentiment regarding the model’s response.

Logs and serializes data that includes session information that you attach when reporting feed

---

# https://developer.apple.com/documentation/foundationmodels/guide(description:_:)

#app-main)

- Foundation Models
- Guide(description:\_:)

Macro

# Guide(description:\_:)

Allows for influencing the allowed values of properties of a `Generable` type.

@attached(peer)

description: String? = nil,

Show all declarations

## Overview

## See Also

### Creating a guide

`macro Guide(description: String)`

`struct GenerationGuide`

Guides that control how values are generated.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror/init(tool:underlyingerror:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.ToolCallError
- init(tool:underlyingError:)

Initializer

# init(tool:underlyingError:)

Creates a tool call error

init(
tool: any Tool,
underlyingError: any Error
)

## Parameters

`tool`

The tool that produced the error.

`underlyingError`

The underlying error that was thrown during a tool call.

---

# https://developer.apple.com/documentation/foundationmodels/generationschema/init(root:dependencies:)

#app-main)

- Foundation Models
- GenerationSchema
- init(root:dependencies:)

Initializer

# init(root:dependencies:)

Creates a schema by providing an array of dynamic schemas.

init(
root: DynamicGenerationSchema,
dependencies: [DynamicGenerationSchema]
) throws

## Parameters

`root`

The root schema.

`dependencies`

An array of dynamic schemas.

## Discussion

## See Also

### Creating a generation schema

`init(type:description:anyOf:)`

Creates a schema for a string enumeration.

[`init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/generationschema/init(type:description:properties:))

Creates a schema by providing an array of properties.

`struct Property`

A property that belongs to a generation schema.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/init(fileurl:)

#app-main)

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Adapter
- init(fileURL:)

Initializer

# init(fileURL:)

Creates an adapter from the file URL.

init(fileURL: URL) throws

## Discussion

## See Also

### Creating an adapter

Loading and using a custom adapter with Foundation Models

Specialize the behavior of the system language model by using a custom adapter you train.

`com.apple.developer.foundation-model-adapter`

A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

`init(name: String) throws`

Creates an adapter downloaded from the background assets framework.

---

# https://developer.apple.com/documentation/foundationmodels/instructionsrepresentable/instructionsrepresentation

- Foundation Models
- InstructionsRepresentable
- instructionsRepresentation

Instance Property

# instructionsRepresentation

An instance that represents the instructions.

@InstructionsBuilder
var instructionsRepresentation: Instructions { get }

**Required** Default implementation provided.

## Default Implementations

### InstructionsRepresentable Implementations

`var instructionsRepresentation: Instructions`

---

# https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(referenceto:)

#app-main)

- Foundation Models
- DynamicGenerationSchema
- init(referenceTo:)

Initializer

# init(referenceTo:)

Creates an refrence schema.

init(referenceTo name: String)

## Parameters

`name`

The name of the `DynamicGenerationSchema` this is a reference to.

## See Also

### Creating a dynamic schema

`init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`

Creates an array schema.

`init(name:description:anyOf:)`

Creates an any-of schema.

[`init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:))

Creates an object schema.

Creates a schema from a generable type and guides.

`struct Property`

A property that belongs to a dynamic generation schema.

---

# https://developer.apple.com/documentation/foundationmodels/generationoptions/init(sampling:temperature:maximumresponsetokens:)

#app-main)

- Foundation Models
- GenerationOptions
- init(sampling:temperature:maximumResponseTokens:)

Initializer

# init(sampling:temperature:maximumResponseTokens:)

Creates generation options that control token sampling behavior.

init(
sampling: GenerationOptions.SamplingMode? = nil,
temperature: Double? = nil,
maximumResponseTokens: Int? = nil
)

## Parameters

`sampling`

A strategy to use for sampling from a distribution.

`temperature`

Increasing temperature makes it possible for the model to produce less likely responses. Must be between `0` and `1`, inclusive.

`maximumResponseTokens`

The maximum number of tokens the model is allowed to produce before being artificially halted. Must be positive.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/init(entries:)

#app-main)

- Foundation Models
- Transcript
- init(entries:)

Initializer

# init(entries:)

Creates a transcript.

## Parameters

`entries`

An array of entries to seed the transcript.

## See Also

### Creating a transcript

`enum Entry`

An entry in a transcript.

`enum Segment`

The types of segments that may be included in a transcript entry.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/ratelimited(_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.rateLimited(\_:)

Case

# LanguageModelSession.GenerationError.rateLimited(\_:)

An error that indicates your session has been rate limited.

case rateLimited(LanguageModelSession.GenerationError.Context)

## Discussion

This error will only happen if your app is running in the background and exceeds the system defined rate limit.

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/available

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Availability
- SystemLanguageModel.Availability.available

Case

# SystemLanguageModel.Availability.available

The system is ready for making requests.

case available

## See Also

### Checking for availability

`case unavailable(SystemLanguageModel.Availability.UnavailableReason)`

Indicates that the system is not ready for requests.

`enum UnavailableReason`

The unavailable reason.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/creatordefinedmetadata

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Adapter
- creatorDefinedMetadata

Instance Property

# creatorDefinedMetadata

Values read from the creator defined field of the adapter’s metadata.

var creatorDefinedMetadata: [String : Any] { get }

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/content

- Foundation Models
- LanguageModelSession
- LanguageModelSession.Response
- content

Instance Property

# content

The response content.

let content: Content

## See Also

### Getting the response content

`let rawContent: GeneratedContent`

The raw response content.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/entry/response(_:)

#app-main)

- Foundation Models
- Transcript
- Transcript.Entry
- Transcript.Entry.response(\_:)

Case

# Transcript.Entry.response(\_:)

A response from the model.

case response(Transcript.Response)

## See Also

### Creating an entry

`case instructions(Transcript.Instructions)`

Instructions, typically provided by you, the developer.

`case prompt(Transcript.Prompt)`

A prompt, typically sourced from an end user.

`case toolCalls(Transcript.ToolCalls)`

A tool call containing a tool name and the arguments to invoke it with.

`case toolOutput(Transcript.ToolOutput)`

An tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/generationschema/init(type:description:anyof:)

#app-main)

- Foundation Models
- GenerationSchema
- init(type:description:anyOf:)

Initializer

# init(type:description:anyOf:)

Creates a schema for a string enumeration.

init(
type: any Generable.Type,
description: String? = nil,
anyOf choices: [String]
)

Show all declarations

## Parameters

`type`

The type this schema represents.

`description`

A natural language description of this schema.

## See Also

### Creating a generation schema

[`init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws`](https://developer.apple.com/documentation/foundationmodels/generationschema/init(root:dependencies:))

Creates a schema by providing an array of dynamic schemas.

[`init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/generationschema/init(type:description:properties:))

Creates a schema by providing an array of properties.

`struct Property`

A property that belongs to a generation schema.

---

# https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode/greedy

- Foundation Models
- GenerationOptions
- GenerationOptions.SamplingMode
- greedy

Type Property

# greedy

A sampling mode that always chooses the most likely token.

static var greedy: GenerationOptions.SamplingMode { get }

## Discussion

Using this mode will always result in the same output for a given input. Responses produced with greedy sampling are statistically likely, but may lack the human-like quality and variety of other sampling strategies.

## See Also

### Sampling options

A mode that considers a variable number of high-probability tokens based on the specified threshold.

A sampling mode that considers a fixed number of high-probability tokens.

---

# https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildexpression(_:)

#app-main)

- Foundation Models
- InstructionsBuilder
- buildExpression(\_:)

Type Method

# buildExpression(\_:)

Creates a builder with a prompt expression.

Show all declarations

## See Also

### Building instructions

Creates a builder with the an array of prompts.

Creates a builder with the a block.

Creates a builder with the first component.

Creates a builder with the second component.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/recoverysuggestion

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- recoverySuggestion

Instance Property

# recoverySuggestion

A string representation of the recovery suggestion.

var recoverySuggestion: String? { get }

---

# https://developer.apple.com/documentation/foundationmodels/generationguide/anyof(_:)

#app-main)

- Foundation Models
- GenerationGuide
- anyOf(\_:)

Type Method

# anyOf(\_:)

Enforces that the string be one of the provided values.

Available when `Value` is `String`.

## See Also

### Getting the constant

Enforces that the string be precisely the given value.

---

# https://developer.apple.com/documentation/foundationmodels/generationoptions/maximumresponsetokens

- Foundation Models
- GenerationOptions
- maximumResponseTokens

Instance Property

# maximumResponseTokens

The maximum number of tokens the model is allowed to produce in its response.

var maximumResponseTokens: Int?

## Discussion

If the model produce `maximumResponseTokens` before it naturally completes its response, the response will be terminated early. No error will be thrown. This property can be used to protect against unexpectedly verbose responses and runaway generations.

If no value is specified, then the model is allowed to produce the longest answer its context size supports. If the response exceeds that limit without terminating, an error will be thrown.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailablereason

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Availability
- SystemLanguageModel.Availability.UnavailableReason

Enumeration

# SystemLanguageModel.Availability.UnavailableReason

The unavailable reason.

enum UnavailableReason

## Topics

### Getting the unavailable reasons

`case appleIntelligenceNotEnabled`

Apple Intelligence is not enabled on the system.

`case deviceNotEligible`

The device does not support Apple Intelligence.

`case modelNotReady`

The model(s) aren’t available on the user’s device.

## Relationships

### Conforms To

- `Copyable`
- `Equatable`
- `Hashable`
- `Sendable`
- `SendableMetatype`

## See Also

### Checking for availability

`case available`

The system is ready for making requests.

`case unavailable(SystemLanguageModel.Availability.UnavailableReason)`

Indicates that the system is not ready for requests.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/id

- Foundation Models
- GeneratedContent
- id

Instance Property

# id

A unique id that is stable for the duration of a generated response.

var id: GenerationID?

## Discussion

A `LanguageModelSession` produces instances of `GeneratedContent` that have a non-nil `id`. When you stream a response, the `id` is the same for all partial generations in the response stream.

Instances of `GeneratedContent` that you produce manually with initializers have a nil `id` because the framework didn’t create them as part of a generation.

---

# https://developer.apple.com/documentation/foundationmodels/convertiblefromgeneratedcontent/init(_:)

#app-main)

- Foundation Models
- ConvertibleFromGeneratedContent
- init(\_:)

Initializer

# init(\_:)

Creates an instance from content generated by a model.

init(_ content: GeneratedContent) throws

**Required**

## Discussion

Conformance to this protocol is provided by the `@Generable` macro. A manual implementation may be used to map values onto properties using different names. To manually initialize your type from generated content, decode the values as shown below:

struct Person: ConvertibleFromGeneratedContent {
var name: String
var age: Int

init(_ content: GeneratedContent) {
self.name = try content.value(forProperty: "firstName")
self.age = try content.value(forProperty: "ageInYears")
}
}

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/concurrentrequests(_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.concurrentRequests(\_:)

Case

# LanguageModelSession.GenerationError.concurrentRequests(\_:)

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

case concurrentRequests(LanguageModelSession.GenerationError.Context)

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror/underlyingerror

- Foundation Models
- LanguageModelSession
- LanguageModelSession.ToolCallError
- underlyingError

Instance Property

# underlyingError

The underlying error that was thrown during a tool call.

var underlyingError: any Error

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/responsestream/snapshot

- Foundation Models
- LanguageModelSession
- LanguageModelSession.ResponseStream
- LanguageModelSession.ResponseStream.Snapshot

Structure

# LanguageModelSession.ResponseStream.Snapshot

A snapshot of partially generated content.

struct Snapshot

## Topics

### Instance Properties

`var content: Content.PartiallyGenerated`

The content of the response.

`var rawContent: GeneratedContent`

The raw content of the response.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/toolcallerror/errordescription

- Foundation Models
- LanguageModelSession
- LanguageModelSession.ToolCallError
- errorDescription

Instance Property

# errorDescription

A string representation of the error description.

var errorDescription: String? { get }

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/context

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.Context

Structure

# LanguageModelSession.GenerationError.Context

The context in which the error occurred.

struct Context

## Topics

### Creating a context

`init(debugDescription: String)`

Creates a context.

### Getting the debug description

`let debugDescription: String`

A debug description to help developers diagnose issues during development.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/decodingfailure(_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.decodingFailure(\_:)

Case

# LanguageModelSession.GenerationError.decodingFailure(\_:)

An error that indicates the session failed to deserialize a valid generable type from model output.

case decodingFailure(LanguageModelSession.GenerationError.Context)

## Discussion

This can happen if generation was terminated early.

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildarray(_:)

#app-main)

- Foundation Models
- InstructionsBuilder
- buildArray(\_:)

Type Method

# buildArray(\_:)

Creates a builder with the an array of prompts.

## See Also

### Building instructions

Creates a builder with the a block.

Creates a builder with the first component.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/rawcontent

- Foundation Models
- LanguageModelSession
- LanguageModelSession.Response
- rawContent

Instance Property

# rawContent

The raw response content.

let rawContent: GeneratedContent

## Discussion

When `Content` is `GeneratedContent`, this is the same as `content`.

## See Also

### Getting the response content

`let content: Content`

The response content.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal(_:_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.refusal(\_:\_:)

Case

# LanguageModelSession.GenerationError.refusal(\_:\_:)

An error that happens when the session refuses the request.

case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)

## Mentioned in

Improving the safety of generative model output

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither(first:)

#app-main)

- Foundation Models
- InstructionsBuilder
- buildEither(first:)

Type Method

# buildEither(first:)

Creates a builder with the first component.

## See Also

### Building instructions

Creates a builder with the an array of prompts.

Creates a builder with the a block.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/compile()

#app-main)

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Adapter
- compile()

Instance Method

# compile()

Prepares an adapter before being used with a `LanguageModelSession`. You should call this if your adapter has a draft model.

func compile() async throws

## Mentioned in

Loading and using a custom adapter with Foundation Models

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/availability-swift.enum/unavailable(_:)

#app-main)

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Availability
- SystemLanguageModel.Availability.unavailable(\_:)

Case

# SystemLanguageModel.Availability.unavailable(\_:)

Indicates that the system is not ready for requests.

case unavailable(SystemLanguageModel.Availability.UnavailableReason)

## See Also

### Checking for availability

`case available`

The system is ready for making requests.

`enum UnavailableReason`

The unavailable reason.

---

# https://developer.apple.com/documentation/foundationmodels/generationoptions/sampling

- Foundation Models
- GenerationOptions
- sampling

Instance Property

# sampling

A sampling strategy for how the model picks tokens when generating a response.

var sampling: GenerationOptions.SamplingMode?

## Discussion

When you execute a prompt on a model, the model produces a probability for every token in its vocabulary. The sampling strategy controls how the model narrows down the list of tokens to consider during that process. A strategy that picks the single most likely token yields a predictable response every time, but other strategies offer results that often sound more natural to a person.

## See Also

### Configuring the sampling mode

`struct SamplingMode`

A type that defines how values are sampled from a probability distribution.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/init(_:id:)

#app-main)

- Foundation Models
- GeneratedContent
- init(\_:id:)

Initializer

# init(\_:id:)

Creates content that contains a single value with a custom `GenerationID`.

init(
_ value: some ConvertibleToGeneratedContent,
id: GenerationID
)

## Parameters

`value`

The underlying value.

`id`

The `GenerationID` for this content.

## See Also

### Creating generated content

`init(_:)`

Creates generated content from another value.

Creates content representing an array of elements you specify.

`init(kind: GeneratedContent.Kind, id: GenerationID?)`

Creates a new `GeneratedContent` instance with the specified kind and `GenerationID`.

---

# https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:)

#app-main)

- Foundation Models
- DynamicGenerationSchema
- init(name:description:properties:)

Initializer

# init(name:description:properties:)

Creates an object schema.

init(
name: String,
description: String? = nil,
properties: [DynamicGenerationSchema.Property]
)

## Parameters

`name`

A name this dynamic schema can be referenced by.

`description`

A natural language description of this schema.

`properties`

The properties to associated with this schema.

## See Also

### Creating a dynamic schema

`init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`

Creates an array schema.

`init(name:description:anyOf:)`

Creates an any-of schema.

`init(referenceTo: String)`

Creates an refrence schema.

Creates a schema from a generable type and guides.

`struct Property`

A property that belongs to a dynamic generation schema.

---

# https://developer.apple.com/documentation/foundationmodels/convertibletogeneratedcontent/generatedcontent

- Foundation Models
- ConvertibleToGeneratedContent
- generatedContent

Instance Property

# generatedContent

This instance represented as generated content.

var generatedContent: GeneratedContent { get }

**Required**

## Discussion

Conformance to this protocol is provided by the `@Generable` macro. A manual implementation may be used to map values onto properties using different names. Use the generated content property as shown below, to manually return a new `GeneratedContent` with the properties you specify.

struct Person: ConvertibleToGeneratedContent {
var name: String
var age: Int

var generatedContent: GeneratedContent {
GeneratedContent(properties: [\
"firstName": name,\
"ageInYears": age\
])
}
}

---

# https://developer.apple.com/documentation/foundationmodels/generationguide/count(_:)

#app-main)

- Foundation Models
- GenerationGuide
- count(\_:)

Type Method

# count(\_:)

Enforces that the array has exactly a certain number elements.

Show all declarations

## Discussion

A `count` generation guide may be used when you want to ensure the model produces exactly a certain number array elements, such as the number of items in a game’s shop.

@Generable
struct struct Shop {
@Guide(description: "A creative name for a shop in a fantasy RPG"
var name: String

@Guide(description: "A list of items for sale", .count(3))
var inventory: [ShopItem]
}

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/unsupportedguide(_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.unsupportedGuide(\_:)

Case

# LanguageModelSession.GenerationError.unsupportedGuide(\_:)

An error that indicates a generation guide with an unsupported pattern was used.

case unsupportedGuide(LanguageModelSession.GenerationError.Context)

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/toolcalls

- Foundation Models
- Transcript
- Transcript.ToolCalls

Structure

# Transcript.ToolCalls

A collection tool calls generated by the model.

struct ToolCalls

## Topics

## Relationships

### Conforms To

- `BidirectionalCollection`
- `Collection`
- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `RandomAccessCollection`
- `Sendable`
- `SendableMetatype`
- `Sequence`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/init(kind:id:)

#app-main)

- Foundation Models
- GeneratedContent
- init(kind:id:)

Initializer

# init(kind:id:)

Creates a new `GeneratedContent` instance with the specified kind and `GenerationID`.

init(
kind: GeneratedContent.Kind,
id: GenerationID? = nil
)

## Parameters

`kind`

The kind of content to create.

`id`

An optional `GenerationID` to associate with this content.

## Discussion

This initializer provides a convenient way to create content from its kind representation.

## See Also

### Creating generated content

`init(_:)`

Creates generated content from another value.

`init(some ConvertibleToGeneratedContent, id: GenerationID)`

Creates content that contains a single value with a custom `GenerationID`.

Creates content representing an array of elements you specify.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/entry

- Foundation Models
- Transcript
- Transcript.Entry

Enumeration

# Transcript.Entry

An entry in a transcript.

enum Entry

## Overview

An individual entry in a transcript may represent instructions from you to the model, a prompt from a user, tool calls, or a response generated by the model.

## Topics

### Creating an entry

`case instructions(Transcript.Instructions)`

Instructions, typically provided by you, the developer.

`case prompt(Transcript.Prompt)`

A prompt, typically sourced from an end user.

`case response(Transcript.Response)`

A response from the model.

`case toolCalls(Transcript.ToolCalls)`

A tool call containing a tool name and the arguments to invoke it with.

`case toolOutput(Transcript.ToolOutput)`

An tool output provided

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Creating a transcript

Creates a transcript.

`enum Segment`

The types of segments that may be included in a transcript entry.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/init(_:)

#app-main)

- Foundation Models
- GeneratedContent
- init(\_:)

Initializer

# init(\_:)

Creates generated content from another value.

init(_ content: GeneratedContent) throws

Show all declarations

## Discussion

This is used to satisfy `Generable.init(_:)`.

## See Also

### Creating generated content

`init(some ConvertibleToGeneratedContent, id: GenerationID)`

Creates content that contains a single value with a custom `GenerationID`.

Creates content representing an array of elements you specify.

`init(kind: GeneratedContent.Kind, id: GenerationID?)`

Creates a new `GeneratedContent` instance with the specified kind and `GenerationID`.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/failurereason

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- failureReason

Instance Property

# failureReason

A string representation of the failure reason.

var failureReason: String? { get }

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.Refusal

Structure

# LanguageModelSession.GenerationError.Refusal

A refusal produced by a language model.

struct Refusal

## Overview

Refusal errors indicate that the model chose not to respond to a prompt. To make the model explain why it refused, catch the refusal error and access one of its explanation properties.

do {
let session = LanguageModelSession()
let response = try session.respond(to: "...")
} catch error as LanguageModelSession.GenerationError.refusal(let refusal, _) {
let message = try await refusal.explanation
print(message)
} catch {
print("Something went wrong: \(error)")
}

## Topics

### Creating a generation error refusal

[`init(transcriptEntries: [Transcript.Entry])`](https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/refusal/init(transcriptentries:))

### Getting the explanation

An explanation for why the model refused to respond.

A stream containing an explanation about why the model refused to respond.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Generation errors

`case assetsUnavailable(LanguageModelSession.GenerationError.Context)`

An error that indicates the assets required for the session are unavailable.

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

---

# https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildblock(_:)

#app-main)

- Foundation Models
- InstructionsBuilder
- buildBlock(\_:)

Type Method

# buildBlock(\_:)

Creates a builder with the a block.

## See Also

### Building instructions

Creates a builder with the an array of prompts.

Creates a builder with the first component.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/assetsunavailable(_:)

#app-main)

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- LanguageModelSession.GenerationError.assetsUnavailable(\_:)

Case

# LanguageModelSession.GenerationError.assetsUnavailable(\_:)

An error that indicates the assets required for the session are unavailable.

case assetsUnavailable(LanguageModelSession.GenerationError.Context)

## Discussion

This may happen if you forget to check model availability to begin with, or if the model assets are deleted. This can happen if the user disables AppleIntelligence while your app is running.

You may be able to recover from this error by retrying later after the device has freed up enough space to redownload model assets.

## See Also

### Generation errors

`case decodingFailure(LanguageModelSession.GenerationError.Context)`

An error that indicates the session failed to deserialize a valid generable type from model output.

`case exceededContextWindowSize(LanguageModelSession.GenerationError.Context)`

An error that signals the session reached its context window size limit.

`case guardrailViolation(LanguageModelSession.GenerationError.Context)`

An error that indicates the system’s safety guardrails are triggered by content in a prompt or the response generated by the model.

`case rateLimited(LanguageModelSession.GenerationError.Context)`

An error that indicates your session has been rate limited.

`case refusal(LanguageModelSession.GenerationError.Refusal, LanguageModelSession.GenerationError.Context)`

An error that happens when the session refuses the request.

`case concurrentRequests(LanguageModelSession.GenerationError.Context)`

An error that happens if you attempt to make a session respond to a second prompt while it’s still responding to the first one.

`case unsupportedGuide(LanguageModelSession.GenerationError.Context)`

An error that indicates a generation guide with an unsupported pattern was used.

`case unsupportedLanguageOrLocale(LanguageModelSession.GenerationError.Context)`

An error that indicates an error that occurs if the model is prompted to respond in a language that it does not support.

`struct Context`

The context in which the error occurred.

`struct Refusal`

A refusal produced by a language model.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/removeobsoleteadapters()

#app-main)

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Adapter
- removeObsoleteAdapters()

Type Method

# removeObsoleteAdapters()

Remove all obsolete adapters that are no longer compatible with current system models.

static func removeObsoleteAdapters() throws

---

# https://developer.apple.com/documentation/foundationmodels/generationoptions/temperature

- Foundation Models
- GenerationOptions
- temperature

Instance Property

# temperature

Temperature influences the confidence of the models response.

var temperature: Double?

## Discussion

The value of this property must be a number between `0` and `1` inclusive.

Temperature is an adjustment applied to the probability distribution prior to sampling. A value of `1` results in no adjustment. Values less than `1` will make the probability distribution sharper, with already likely tokens becoming even more likely.

The net effect is that low temperatures manifest as more stable and predictable responses, while high temperatures give the model more creative license.

---

# https://developer.apple.com/documentation/foundationmodels/generationschema/debugdescription

- Foundation Models
- GenerationSchema
- debugDescription

Instance Property

# debugDescription

A string representation of the debug description.

var debugDescription: String { get }

## Discussion

This string is not localized and is not appropriate for display to end users.

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/response/transcriptentries

- Foundation Models
- LanguageModelSession
- LanguageModelSession.Response
- transcriptEntries

Instance Property

# transcriptEntries

The list of transcript entries.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/value(_:)

#app-main)

- Foundation Models
- GeneratedContent
- value(\_:)

Instance Method

# value(\_:)

Reads a top level, concrete partially `Generable` type from a named property.

## See Also

### Reads a value from the concrete type

`func value(_:forProperty:)`

Reads a concrete `Generable` type from named property.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/textsegment

- Foundation Models
- Transcript
- Transcript.TextSegment

Structure

# Transcript.TextSegment

A segment containing text.

struct TextSegment

## Topics

### Creating a text segment

`init(id: String, content: String)`

### Inspecting a text segment

`var content: String`

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/value(_:forproperty:)

#app-main)

- Foundation Models
- GeneratedContent
- value(\_:forProperty:)

Instance Method

# value(\_:forProperty:)

Reads a concrete `Generable` type from named property.

_ type: Value.Type = Value.self,
forProperty property: String

Show all declarations

## See Also

### Reads a value from the concrete type

Reads a top level, concrete partially `Generable` type from a named property.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/init(json:)

#app-main)

- Foundation Models
- GeneratedContent
- init(json:)

Initializer

# init(json:)

Creates equivalent content from a JSON string.

init(json: String) throws

## Discussion

The JSON string you provide may be incomplete. This is useful for correctly handling partially generated responses.

@Generable struct NovelIdea {
let title: String
}

let partial = #"{"title": "A story of"#
let content = try GeneratedContent(json: partial)
let idea = try NovelIdea(content)
print(idea.title) // A story of

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/debugdescription

- Foundation Models
- GeneratedContent
- debugDescription

Instance Property

# debugDescription

A string representation for the debug description.

var debugDescription: String { get }

---

# https://developer.apple.com/documentation/foundationmodels/transcript/prompt

- Foundation Models
- Transcript
- Transcript.Prompt

Structure

# Transcript.Prompt

A prompt from the user to the model.

struct Prompt

## Overview

Prompts typically contain content sourced directly from the user, though you may choose to augment prompts by interpolating content from end users into a template that you control.

## Topics

### Creating a prompt

[`init(id: String, segments: [Transcript.Segment], options: GenerationOptions, responseFormat: Transcript.ResponseFormat?)`](https://developer.apple.com/documentation/foundationmodels/transcript/prompt/init(id:segments:options:responseformat:))

Creates a prompt.

### Inspecting a prompt

`var id: String`

The identifier of the prompt.

`var responseFormat: Transcript.ResponseFormat?`

An optional response format that describes the desired output structure.

[`var segments: [Transcript.Segment]`](https://developer.apple.com/documentation/foundationmodels/transcript/prompt/segments)

Ordered prompt segments.

`var options: GenerationOptions`

Generation options associated with the prompt.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/generatedcontent

- Foundation Models
- GeneratedContent
- generatedContent

Instance Property

# generatedContent

A representation of this instance.

var generatedContent: GeneratedContent { get }

---

# https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror

- Foundation Models
- GenerationSchema
- GenerationSchema.SchemaError

Enumeration

# GenerationSchema.SchemaError

A error that occurs when there is a problem creating a generation schema.

enum SchemaError

## Topics

### Getting schema errors

`case duplicateProperty(schema: String, property: String, context: GenerationSchema.SchemaError.Context)`

An error that represents an attempt to construct a dynamic schema with properties that have conflicting names.

`case duplicateType(schema: String?, type: String, context: GenerationSchema.SchemaError.Context)`

An error that represents an attempt to construct a schema from dynamic schemas, and two or more of the subschemas have the same type name.

`case emptyTypeChoices(schema: String, context: GenerationSchema.SchemaError.Context)`

An error that represents an attempt to construct an anyOf schema with an empty array of type choices.

[`case undefinedReferences(schema: String?, references: [String], context: GenerationSchema.SchemaError.Context)`](https://developer.apple.com/documentation/foundationmodels/generationschema/schemaerror/undefinedreferences(schema:references:context:))

An error that represents an attempt to construct a schema from dynamic schemas, and one of those schemas references an undefined schema.

`struct Context`

The context in which the error occurred.

### Getting the error description

`var errorDescription: String?`

A string representation of the error description.

### Getting the recovery suggestion

`var recoverySuggestion: String?`

A suggestion that indicates how to handle the error.

## Relationships

### Conforms To

- `Error`
- `LocalizedError`
- `Sendable`
- `SendableMetatype`

---

# https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildoptional(_:)

#app-main)

- Foundation Models
- InstructionsBuilder
- buildOptional(\_:)

Type Method

# buildOptional(\_:)

Creates a builder with an optional component.

## See Also

### Building instructions

Creates a builder with the an array of prompts.

Creates a builder with the a block.

Creates a builder with the first component.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/jsonstring

- Foundation Models
- GeneratedContent
- jsonString

Instance Property

# jsonString

Returns a JSON string representation of the generated content.

var jsonString: String { get }

## Examples

// Object with properties
let content = GeneratedContent(properties: [\
"name": "Johnny Appleseed",\
"age": 30,\
])
print(content.jsonString)
// Output: {"name": "Johnny Appleseed", "age": 30}

## See Also

### Accessing instance properties

`var kind: GeneratedContent.Kind`

The kind representation of this generated content.

`var isComplete: Bool`

A Boolean that indicates whether the generated content is completed.

---

# https://developer.apple.com/documentation/foundationmodels/generationschema/property

- Foundation Models
- GenerationSchema
- GenerationSchema.Property

Structure

# GenerationSchema.Property

A property that belongs to a generation schema.

struct Property

## Overview

Fields are named members of object types. Fields are strongly typed and have optional descriptions and guides.

## Topics

### Creating a property

`init(name:description:type:guides:)`

Create a property that contains a string type.

## Relationships

### Conforms To

- `Sendable`
- `SendableMetatype`

## See Also

### Creating a generation schema

[`init(root: DynamicGenerationSchema, dependencies: [DynamicGenerationSchema]) throws`](https://developer.apple.com/documentation/foundationmodels/generationschema/init(root:dependencies:))

Creates a schema by providing an array of dynamic schemas.

`init(type:description:anyOf:)`

Creates a schema for a string enumeration.

[`init(type: any Generable.Type, description: String?, properties: [GenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/generationschema/init(type:description:properties:))

Creates a schema by providing an array of properties.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.property

- Foundation Models
- GeneratedContent
- kind

Instance Property

# kind

The kind representation of this generated content.

var kind: GeneratedContent.Kind { get }

## Discussion

This property provides access to the content in a strongly-typed enum representation, preserving the hierarchical structure of the data and the data’s `GenerationID` ids.

## See Also

### Accessing instance properties

`var isComplete: Bool`

A Boolean that indicates whether the generated content is completed.

`var jsonString: String`

Returns a JSON string representation of the generated content.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/iscomplete

- Foundation Models
- GeneratedContent
- isComplete

Instance Property

# isComplete

A Boolean that indicates whether the generated content is completed.

var isComplete: Bool { get }

## See Also

### Accessing instance properties

`var kind: GeneratedContent.Kind`

The kind representation of this generated content.

`var jsonString: String`

Returns a JSON string representation of the generated content.

---

# https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/property

- Foundation Models
- DynamicGenerationSchema
- DynamicGenerationSchema.Property

Structure

# DynamicGenerationSchema.Property

A property that belongs to a dynamic generation schema.

struct Property

## Overview

Fields are named members of object types. Fields are strongly typed and have optional descriptions.

## Topics

### Creating a property

`init(name: String, description: String?, schema: DynamicGenerationSchema, isOptional: Bool)`

Creates a property referencing a dynamic schema.

## See Also

### Creating a dynamic schema

`init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`

Creates an array schema.

`init(name:description:anyOf:)`

Creates an any-of schema.

[`init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:))

Creates an object schema.

`init(referenceTo: String)`

Creates an refrence schema.

Creates a schema from a generable type and guides.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/tooldefinition

- Foundation Models
- Transcript
- Transcript.ToolDefinition

Structure

# Transcript.ToolDefinition

A definition of a tool.

struct ToolDefinition

## Topics

### Creating a tool definition

`init(name: String, description: String, parameters: GenerationSchema)`

`init(tool: some Tool)`

### Inspecting a tool definition

`var description: String`

A description of how and when to use the tool.

`var name: String`

The tool’s name.

## Relationships

### Conforms To

- `Equatable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/init(properties:id:)

#app-main)

- Foundation Models
- GeneratedContent
- init(properties:id:)

Initializer

# init(properties:id:)

Creates generated content representing a structure with the properties you specify.

init(

id: GenerationID? = nil
)

## Discussion

The order of properties is important. For `Generable` types, the order must match the order properties in the types `schema`.

## See Also

### Creating content from properties

Creates new generated content from the key-value pairs in the given sequence, using a combining closure to determine the value for any duplicate keys.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/init(name:)

#app-main)

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Adapter
- init(name:)

Initializer

# init(name:)

Creates an adapter downloaded from the background assets framework.

init(name: String) throws

## Discussion

## See Also

### Creating an adapter

Loading and using a custom adapter with Foundation Models

Specialize the behavior of the system language model by using a custom adapter you train.

`com.apple.developer.foundation-model-adapter`

A Boolean value that indicates whether the app can enable custom adapters for the Foundation Models framework.

`init(fileURL: URL) throws`

Creates an adapter from the file URL.

---

# https://developer.apple.com/documentation/foundationmodels/generable/aspartiallygenerated()

#app-main)

- Foundation Models
- Generable
- asPartiallyGenerated()

Instance Method

# asPartiallyGenerated()

The partially generated type of this struct.

## See Also

### Converting to partially generated

`associatedtype PartiallyGenerated : ConvertibleFromGeneratedContent = Self`

A representation of partially generated content

**Required** Default implementation provided.

---

# https://developer.apple.com/documentation/foundationmodels/systemlanguagemodel/adapter/asseterror

- Foundation Models
- SystemLanguageModel
- SystemLanguageModel.Adapter
- SystemLanguageModel.Adapter.AssetError

Enumeration

# SystemLanguageModel.Adapter.AssetError

enum AssetError

## Topics

### Getting the asset errors

`case compatibleAdapterNotFound(SystemLanguageModel.Adapter.AssetError.Context)`

An error that happens if there are no compatible adapters for the current system base model.

`case invalidAdapterName(SystemLanguageModel.Adapter.AssetError.Context)`

An error that happens if the provided adapter name is invalid.

`case invalidAsset(SystemLanguageModel.Adapter.AssetError.Context)`

An error that happens if the provided asset files are invalid.

`struct Context`

The context in which the error occurred.

### Getting the error description

`var errorDescription: String?`

A string representation of the error description.

## Relationships

### Conforms To

- `Error`
- `LocalizedError`
- `Sendable`
- `SendableMetatype`

---

# https://developer.apple.com/documentation/foundationmodels/transcript/instructions

- Foundation Models
- Transcript
- Transcript.Instructions

Structure

# Transcript.Instructions

Instructions you provide to the model that define its behavior.

struct Instructions

## Overview

Instructions are typically provided to define the role and behavior of the model. Apple trains the model to obey instructions over any commands it receives in prompts. This is a security mechanism to help mitigate prompt injection attacks.

## Topics

### Creating instructions

[`init(id: String, segments: [Transcript.Segment], toolDefinitions: [Transcript.ToolDefinition])`](https://developer.apple.com/documentation/foundationmodels/transcript/instructions/init(id:segments:tooldefinitions:))

Initialize instructions by describing how you want the model to behave using natural language.

### Inspecting instructions

[`var segments: [Transcript.Segment]`](https://developer.apple.com/documentation/foundationmodels/transcript/instructions/segments)

The content of the instructions, in natural language.

[`var toolDefinitions: [Transcript.ToolDefinition]`](https://developer.apple.com/documentation/foundationmodels/transcript/instructions/tooldefinitions)

A list of tools made available to the model.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/generationoptions/samplingmode

- Foundation Models
- GenerationOptions
- GenerationOptions.SamplingMode

Structure

# GenerationOptions.SamplingMode

A type that defines how values are sampled from a probability distribution.

struct SamplingMode

## Overview

A model builds its response to a prompt in a loop. At each iteration in the loop the model produces a probability distribution for all the tokens in its vocabulary. The sampling mode controls how a token is selected from that distribution.

## Topics

### Sampling options

`static var greedy: GenerationOptions.SamplingMode`

A sampling mode that always chooses the most likely token.

A mode that considers a variable number of high-probability tokens based on the specified threshold.

A sampling mode that considers a fixed number of high-probability tokens.

## Relationships

### Conforms To

- `Equatable`
- `Sendable`
- `SendableMetatype`

## See Also

### Configuring the sampling mode

`var sampling: GenerationOptions.SamplingMode?`

A sampling strategy for how the model picks tokens when generating a response.

---

# https://developer.apple.com/documentation/foundationmodels/generationguide/element(_:)

#app-main)

- Foundation Models
- GenerationGuide
- element(\_:)

Type Method

# element(\_:)

Enforces a guide on the elements within the array.

## Discussion

An `element` generation guide may be used when you want to apply guides to the values a model produces within an array. For example, you may want to generate an array of integers, where all the integers are in the range 0-9.

@Generable
struct struct FortuneCookie {
@Guide(description: "A fortune from a fortune cookie"
var name: String

@Guide(description: "A list lucky numbers", .element(.range(0...9)), .count(4))
var luckyNumbers: [Int]
}

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/init(properties:id:uniquingkeyswith:)

#app-main)

- Foundation Models
- GeneratedContent
- init(properties:id:uniquingKeysWith:)

Initializer

# init(properties:id:uniquingKeysWith:)

Creates new generated content from the key-value pairs in the given sequence, using a combining closure to determine the value for any duplicate keys.

properties: S,
id: GenerationID? = nil,

) rethrows where S : Sequence, S.Element == (String, any ConvertibleToGeneratedContent)

## Parameters

`properties`

A sequence of key-value pairs to use for the new content.

`id`

A unique id associated with `GeneratedContent`.

`combine`

A closure that is called with the values to resolve any duplicates keys that are encountered. The closure returns the desired value for the final content.

## Discussion

The order of properties is important. For `Generable` types, the order must match the order properties in the types `schema`.

You use this initializer to create generated content when you have a sequence of key-value tuples that might have duplicate keys. As the content is built, the initializer calls the `combine` closure with the current and new values for any duplicate keys. Pass a closure as `combine` that returns the value to use in the resulting content: The closure can choose between the two values, combine them to produce a new value, or even throw an error.

The following example shows how to choose the first and last values for any duplicate keys:

let content = GeneratedContent(
properties: [("name", "John"), ("name", "Jane"), ("married", true)],
uniquingKeysWith: { (first, _) in first }
)
// GeneratedContent(["name": "John", "married": true])

## See Also

### Creating content from properties

Creates generated content representing a structure with the properties you specify.

---

# https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum

- Foundation Models
- GeneratedContent
- GeneratedContent.Kind

Enumeration

# GeneratedContent.Kind

The representation of the generated content.

enum Kind

## Overview

This property provides access to the content in a strongly-typed enumeration representation, preserving the hierarchical structure of the data and the data’s `GenerationID` values.

## Topics

### Getting the kind of content

[`case array([GeneratedContent])`](https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/array(_:))

Represents an array of `GeneratedContent` elements.

`case bool(Bool)`

Represents a boolean value.

`case null`

Represents a null value.

`case number(Double)`

Represents a numeric value.

`case string(String)`

Represents a string value.

[`case structure(properties: [String : GeneratedContent], orderedKeys: [String])`](https://developer.apple.com/documentation/foundationmodels/generatedcontent/kind-swift.enum/structure(properties:orderedkeys:))

Represents a structured object with key-value pairs.

## Relationships

### Conforms To

- `Equatable`
- `Sendable`
- `SendableMetatype`

## See Also

### Creating content from kind

`init(kind: GeneratedContent.Kind, id: GenerationID?)`

Creates a new `GeneratedContent` instance with the specified kind and `GenerationID`.

---

# https://developer.apple.com/documentation/foundationmodels/generationguide/pattern(_:)

#app-main)

- Foundation Models
- GenerationGuide
- pattern(\_:)

Type Method

# pattern(\_:)

Enforces that the string follows the pattern.

Available when `Value` is `String`.

---

# https://developer.apple.com/documentation/foundationmodels/tool/name-6x7wj

- Foundation Models
- Tool
- name

Instance Property

# name

A unique name for the tool, such as “get\_weather”, “toggleDarkMode”, or “search contacts”.

var name: String { get }

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelfeedback/sentiment/negative

- Foundation Models
- LanguageModelFeedback
- LanguageModelFeedback.Sentiment
- LanguageModelFeedback.Sentiment.negative

Case

# LanguageModelFeedback.Sentiment.negative

A negative sentiment

case negative

## See Also

### Getting sentiment

`case neutral`

A neutral sentiment

`case positive`

A positive sentiment

---

# https://developer.apple.com/documentation/foundationmodels/promptrepresentable/promptrepresentation

- Foundation Models
- PromptRepresentable
- promptRepresentation

Instance Property

# promptRepresentation

An instance that represents a prompt.

@PromptBuilder
var promptRepresentation: Prompt { get }

**Required** Default implementation provided.

## Default Implementations

### PromptRepresentable Implementations

`var promptRepresentation: Prompt`

---

# https://developer.apple.com/documentation/foundationmodels/tool/parameters-590v0

- Foundation Models
- Tool
- parameters

Instance Property

# parameters

A schema for the parameters this tool accepts.

var parameters: GenerationSchema { get }

Available when `Arguments` conforms to `Generable`.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/segment/structure(_:)

#app-main)

- Foundation Models
- Transcript
- Transcript.Segment
- Transcript.Segment.structure(\_:)

Case

# Transcript.Segment.structure(\_:)

A segment containing structured content.

case structure(Transcript.StructuredSegment)

## See Also

### Creating a segment

`case text(Transcript.TextSegment)`

A segment containing text.

---

# https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildeither(second:)

#app-main)

- Foundation Models
- InstructionsBuilder
- buildEither(second:)

Type Method

# buildEither(second:)

Creates a builder with the second component.

## See Also

### Building instructions

Creates a builder with the an array of prompts.

Creates a builder with the a block.

Creates a builder with the first component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/tool/includesschemaininstructions-2yllg

- Foundation Models
- Tool
- includesSchemaInInstructions

Instance Property

# includesSchemaInInstructions

If true, the model’s name, description, and parameters schema will be injected into the instructions of sessions that leverage this tool.

var includesSchemaInInstructions: Bool { get }

## Discussion

The default implementation is `true`

---

# https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(type:guides:)

#app-main)

- Foundation Models
- DynamicGenerationSchema
- init(type:guides:)

Initializer

# init(type:guides:)

Creates a schema from a generable type and guides.

type: Value.Type,

) where Value : Generable

## Parameters

`type`

A `Generable` type

`guides`

Generation guides to apply to this `DynamicGenerationSchema`.

## See Also

### Creating a dynamic schema

`init(arrayOf: DynamicGenerationSchema, minimumElements: Int?, maximumElements: Int?)`

Creates an array schema.

`init(name:description:anyOf:)`

Creates an any-of schema.

[`init(name: String, description: String?, properties: [DynamicGenerationSchema.Property])`](https://developer.apple.com/documentation/foundationmodels/dynamicgenerationschema/init(name:description:properties:))

Creates an object schema.

`init(referenceTo: String)`

Creates an refrence schema.

`struct Property`

A property that belongs to a dynamic generation schema.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/structuredsegment

- Foundation Models
- Transcript
- Transcript.StructuredSegment

Structure

# Transcript.StructuredSegment

A segment containing structured content.

struct StructuredSegment

## Topics

### Creating a structured segment

`init(id: String, source: String, content: GeneratedContent)`

### Inspecting a structured segment

`var content: GeneratedContent`

The content of the segment.

`var source: String`

A source that be used to understand which type content represents.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/languagemodelsession/generationerror/errordescription

- Foundation Models
- LanguageModelSession
- LanguageModelSession.GenerationError
- errorDescription

Instance Property

# errorDescription

A string representation of the error description.

var errorDescription: String? { get }

---

# https://developer.apple.com/documentation/foundationmodels/generable/partiallygenerated-swift.typealias

- Foundation Models
- Generable
- Generable.PartiallyGenerated

Type Alias

# Generable.PartiallyGenerated

A representation of partially generated content

typealias PartiallyGenerated = Self

---

# https://developer.apple.com/documentation/foundationmodels/generationguide/range(_:)

#app-main)

- Foundation Models
- GenerationGuide
- range(\_:)

Type Method

# range(\_:)

Enforces values fall within a range.

Available when `Value` is `Decimal`.

Show all declarations

## Discussion

Use a `range` generation guide — whose bounds are inclusive — to ensure the model produces a value that falls within a range. For example, you can specify that the level of characters in your game are between 1 and 100:

@Generable
struct GameCharacter {
@Guide(description: "A creative name appropriate for a fantasy RPG character")
var name: String

@Guide(description: "A level for the character", .range(1...100))
var level: Int
}

---

# https://developer.apple.com/documentation/foundationmodels/generationguide/constant(_:)

#app-main)

- Foundation Models
- GenerationGuide
- constant(\_:)

Type Method

# constant(\_:)

Enforces that the string be precisely the given value.

Available when `Value` is `String`.

## See Also

### Getting the constant

Enforces that the string be one of the provided values.

---

# https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildeither(first:)

#app-main)

- Foundation Models
- PromptBuilder
- buildEither(first:)

Type Method

# buildEither(first:)

Creates a builder with the first component.

## See Also

### Building a prompt

Creates a builder with the an array of prompts.

Creates a builder with the a block.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/toolcall

- Foundation Models
- Transcript
- Transcript.ToolCall

Structure

# Transcript.ToolCall

A tool call generated by the model containing the name of a tool and arguments to pass to it.

struct ToolCall

## Topics

### Creating a tool call

`init(id: String, toolName: String, arguments: GeneratedContent)`

### Inspecting a tool call

`var arguments: GeneratedContent`

Arguments to pass to the invoked tool.

`var toolName: String`

The name of the tool being invoked.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/transcript/responseformat

- Foundation Models
- Transcript
- Transcript.ResponseFormat

Structure

# Transcript.ResponseFormat

Specifies a response format that the model must conform its output to.

struct ResponseFormat

## Topics

### Creating a response format

`init(schema: GenerationSchema)`

Creates a response format with a schema.

Creates a response format with type you specify.

### Inspecting a response format

`var name: String`

A name associated with the response format.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildarray(_:)

#app-main)

- Foundation Models
- PromptBuilder
- buildArray(\_:)

Type Method

# buildArray(\_:)

Creates a builder with the an array of prompts.

## See Also

### Building a prompt

Creates a builder with the a block.

Creates a builder with the first component.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/instructionsbuilder/buildlimitedavailability(_:)

#app-main)

- Foundation Models
- InstructionsBuilder
- buildLimitedAvailability(\_:)

Type Method

# buildLimitedAvailability(\_:)

Creates a builder with a limited availability prompt.

## See Also

### Building instructions

Creates a builder with the an array of prompts.

Creates a builder with the a block.

Creates a builder with the first component.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/promptbuilder/buildblock(_:)

#app-main)

- Foundation Models
- PromptBuilder
- buildBlock(\_:)

Type Method

# buildBlock(\_:)

Creates a builder with the a block.

## See Also

### Building a prompt

Creates a builder with the an array of prompts.

Creates a builder with the first component.

Creates a builder with the second component.

`static buildExpression(_:)`

Creates a builder with a prompt expression.

Creates a builder with a limited availability prompt.

Creates a builder with an optional component.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/response

- Foundation Models
- Transcript
- Transcript.Response

Structure

# Transcript.Response

A response from the model.

struct Response

## Topics

### Creating a response

[`init(id: String, assetIDs: [String], segments: [Transcript.Segment])`](https://developer.apple.com/documentation/foundationmodels/transcript/response/init(id:assetids:segments:))

### Inspecting a response

[`var segments: [Transcript.Segment]`](https://developer.apple.com/documentation/foundationmodels/transcript/response/segments)

Ordered prompt segments.

[`var assetIDs: [String]`](https://developer.apple.com/documentation/foundationmodels/transcript/response/assetids)

Version aware identifiers for all assets used to generate this response.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

`struct ToolOutput`

A tool output provided

---

# https://developer.apple.com/documentation/foundationmodels/transcript/tooloutput

- Foundation Models
- Transcript
- Transcript.ToolOutput

Structure

# Transcript.ToolOutput

A tool output provided

### Creating a tool output

[`init(id: String, toolName: String, segments: [Transcript.Segment])`](https://developer.apple.com/documentation/foundationmodels/transcript/tooloutput/init(id:toolname:segments:))

### Inspecting a tool output

`var id: String`

A unique id for this tool output.

[`var segments: [Transcript.Segment]`](https://developer.apple.com/documentation/foundationmodels/transcript/tooloutput/segments)

Segments of the tool output.

`var toolName: String`

The name of the tool that produced this output.

## Relationships

### Conforms To

- `Copyable`
- `CustomStringConvertible`
- `Equatable`
- `Identifiable`
- `Sendable`
- `SendableMetatype`

## See Also

### Getting the transcript types

`struct Instructions`

Instructions you provide to the model that define its behavior.

`struct Prompt`

A prompt from the user to the model.

`struct Response`

A response from the model.

`struct ResponseFormat`

Specifies a response format that the model must conform its output to.

`struct StructuredSegment`

A segment containing structured content.

`struct TextSegment`

A segment containing text.

`struct ToolCall`

A tool call generated by the model containing the name of a tool and arguments to pass to it.

`struct ToolCalls`

A collection tool calls generated by the model.

`struct ToolDefinition`

A definition of a tool.

---

# https://developer.apple.com/documentation/foundationmodels/generationid/init()

#app-main)

- Foundation Models
- GenerationID
- init()

Initializer

# init()

Create a new, unique `GenerationID`.

init()

---

# https://developer.apple.com/documentation/foundationmodels/transcript/segment/text(_:)

#app-main)

- Foundation Models
- Transcript
- Transcript.Segment
- Transcript.Segment.text(\_:)

Case

# Transcript.Segment.text(\_:)

A segment containing text.

case text(Transcript.TextSegment)

## See Also

### Creating a segment

`case structure(Transcript.StructuredSegment)`

A segment containing structured content.

---

# https://developer.apple.com/documentation/foundationmodels/transcript/instructions/init(id:segments:tooldefinitions:)

#app-main)

- Foundation Models
- Transcript
- Transcript.Instructions
- init(id:segments:toolDefinitions:)

Initializer

# init(id:segments:toolDefinitions:)

Initialize instructions by describing how you want the model to behave using natural language.

init(
id: String = UUID().uuidString,
segments: [Transcript.Segment],
toolDefinitions: [Transcript.ToolDefinition]
)

## Parameters

`id`

A unique identifier for this instructions segment.

`segments`

An array of segments that make up the instructions.

`toolDefinitions`

Tools that the model should be allowed to call.

---

