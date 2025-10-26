let claude = OpenRouterManager(apiKey: "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")

Task {
    let response = try await claude.sendMessage(
        "Suppose you are a squirrel. Give a quick, one-sentence reaction to this image. Give a squirrel happiness percentage. Your response should be in the form:" + "\n" + "\n" + "[reaction text (string)] + ",\n," + ",\n," + [squirrel happiness percentage]",
        imagePaths: ["images/test_img1.jpg"]
    )
    print(response)
}
