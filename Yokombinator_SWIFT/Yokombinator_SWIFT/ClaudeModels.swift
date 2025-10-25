import ClaudeCodeSDK

// Create a custom configuration
var configuration = ClaudeCodeConfiguration(
    command: "claude",                    // Command to execute (default: "claude")
    workingDirectory: "/path/to/project", // Set working directory
    environment: ["API_KEY": "value"],    // Additional environment variables
    enableDebugLogging: true,             // Enable debug logs
    additionalPaths: ["/custom/bin"],     // Additional PATH directories
    commandSuffix: "--"                   // Optional suffix after command (e.g., "claude --")
)

// Initialize client with custom configuration
let client = ClaudeCodeClient(configuration: configuration)

var options = ClaudeCodeOptions()
options.verbose = true
options.maxTurns = 5
options.systemPrompt = "You are a senior backend engineer specializing in Swift."
options.appendSystemPrompt = "After writing code, add comprehensive comments."
options.timeout = 300 // 5 minute timeout
options.model = "claude-3-sonnet-20240229"
options.permissionMode = .acceptEdits
options.maxThinkingTokens = 10000

// Tool configuration
options.allowedTools = ["Read", "Write", "Bash"]
options.disallowedTools = ["Delete"]

let result = try await client.runSinglePrompt(
    prompt: "Create a REST API in Swift",
    outputFormat: .text,
    options: options
)
