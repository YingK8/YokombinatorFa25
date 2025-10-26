////
////  main.swift
////  Yokombinator_SWIFT
////
////  Created by Kakala on 26/10/2025.
////
//
//
//import Foundation
//
//let claude = OpenRouterManager(apiKey: "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")
//
//Task {
//    do {
//        let response = try await claude.sendMessage(
//            "You are a squirrel. Give a short, direct, one-sentence (less than 15 words) reaction to this image. Give a squirrel happiness level. Your response should be in the form:" + "\n" + "\n" + "\"<reaction text (string)>" + "\n" + "\n" + "<squirrel happiness level (float in [0, 1])>\"",
//            imagePaths: ["images/sq-min.jpeg"]
//        )
//        print(response)
//        exit(0)
//    } catch {
//        print("Error:", error)
//        exit(1)
//    }
//}
//
//RunLoop.main.run()
