//import Foundation
//
//public class SquirrelHandler {
//    private var apiKey: String
//    private var OpenRouter: OpenRouterManager
//    private let setup: bool = false
//    private var
//    
//    public init(apiKey: String = "", OpenRouter: OpenRouterManager = None) {
//        if apiKey:
//            self.apiKey = apiKey
//            self.OpenRouter = OpenRouterManager(apiKey = self.apiKey)
//        else if OpenRouter:
//            self.OpenRouter = OpenRouter
//    }
//    
//    public func setapiKey(apiKey: String) {
//        self.apiKey = apiKey
//        self.OpenRouter = OpenRouterManager(apiKey: apiKey = self.apiKey)
//    }
//    
//    public func getImageResponse(base64ImgURL: String) -> String {
//        return try await OpenRouter.sendMessage(
//            "You are a squirrel. Give a short, direct, one-sentence (less than 15 words) reaction to this image. Give a squirrel happiness level. Your response should be in the form:" + "\n" + "\n" + "\"<reaction text (string)>" + "\n" + "\n" + "<squirrel happiness level (float in [0, 1])>\"",
//            imagePaths: [], base64ImgURLs: base64ImgURLs: [base64ImgURL]
//        )
//    }
//    
//}
