
import Foundation

let claude = OpenRouterManager(apiKey: "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")

Task {
    do {
        let response = try await claude.sendMessage(
            "You are a squirrel. Give a short, direct, one-sentence (less than 15 words) reaction to this image. Give a squirrel happiness percentage. Your response should be in the form:" + "\n" + "\n" + "[reaction text (string)]" + "\n" + "\n" + "[squirrel happiness percentage]",
            /*"You are a squirrel with the following personality: [direct, honest, energetic]. You like the sun, are active during the day, like trees and bushes, are paranoid of predators, are scared of environments where it is diffucult for you to survive, and get easily over-stimulated." + "\n" + "\n" + "Respond to the image in this format: '<reaction to image, incredibly casual wording, 10 words maximum> <happiness score: float in [0, 1]>'",*/


            imagePaths: ["images/IMG_5025.jpeg"]
        )
        print(response)
        exit(0)
    } catch {
        print("Error:", error)
        exit(1)
    }
}

RunLoop.main.run()

/*
 from openai import OpenAI
 
 client = OpenAI(
 base_url="https://openrouter.ai/api/v1",
 api_key="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",
 )
 
 completion = client.chat.completions.create(
 extra_headers={},
 extra_body={},
 model="anthropic/claude-haiku-4.5",
 messages=[
 {
 "role": "user",
 "content": [
 {
 "type": "text",
 "text": "Suppose you are a squirrel. Give a quick, one-sentence reaction to this image. Give a squirrel happiness percentage. Your response should be in the form:" + "\n" + "\n" + "[reaction text (string)]" + "\n" + "\n" + "[squirrel happiness percentage]"
 },
 {
 "type": "image_url",
 "image_url": {
 "url": "https://upload.wikimedia.org/wikipedia/commons/thumb/d/dd/Gfp-wisconsin-madison-the-nature-boardwalk.jpg/2560px-Gfp-wisconsin-madison-the-nature-boardwalk.jpg"
 }
 }
 ]
 }
 ]
 )
 print(completion.choices[0].message.content)
 */
