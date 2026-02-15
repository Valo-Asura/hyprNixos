import QtQuick
import "../AiModel.qml"

ApiStrategy {
    function getEndpoint(modelObj, apiKey) {
        return modelObj.endpoint + modelObj.model + ":generateContent?key=" + apiKey;
    }

    function getHeaders(apiKey) {
        return ["Content-Type: application/json"];
    }

    function getBody(messages, model, tools) {
        // Convert messages to Gemini format
        let contents = messages.map(msg => {
            if (msg.role === "assistant") {
                // If we preserved raw Gemini parts (e.g. thought + function call), use them
                if (msg.geminiParts) {
                    return {
                        role: "model",
                        parts: msg.geminiParts
                    };
                }
                
                if (msg.functionCall) {
                    return {
                        role: "model",
                        parts: [{ functionCall: msg.functionCall }]
                    };
                }
                return {
                    role: "model",
                    parts: [{ text: msg.content }]
                };
            } else if (msg.role === "function") {
                return {
                    role: "function",
                    parts: [{
                        functionResponse: {
                            name: msg.name,
                            response: {
                                name: msg.name,
                                content: msg.content
                            }
                        }
                    }]
                };
            } else {
                return {
                    role: "user",
                    parts: [{ text: msg.content }]
                };
            }
        });
        
        // ... (rest of body construction)
        let body = {
            contents: contents,
            generationConfig: {
                temperature: 0.7,
                maxOutputTokens: 2048
            }
        };

        if (tools && tools.length > 0) {
            body.tools = [{ function_declarations: tools }];
        }

        return body;
    }
    
    function parseResponse(response) {
        try {
            if (!response || response.trim() === "") return { content: "Error: Empty response from API" };
            
            let json = JSON.parse(response);
            
            if (json.error) {
                return { content: "API Error (" + json.error.code + "): " + json.error.message };
            }
            
            if (json.candidates && json.candidates.length > 0) {
                let content = json.candidates[0].content;
                if (content && content.parts && content.parts.length > 0) {
                    
                    // Look for function calls and thoughts
                    let hasFunctionCall = false;
                    let textContent = "";
                    let funcCall = null;
                    
                    // We must preserve specific structure for Gemini if tool calls are involved
                    // We'll store the raw parts to send back in history
                    let rawParts = content.parts;
                    
                    for (let i = 0; i < content.parts.length; i++) {
                        let part = content.parts[i];
                        if (part.functionCall) {
                            hasFunctionCall = true;
                            funcCall = part.functionCall;
                        } else if (part.text) {
                            textContent += part.text + "\n";
                        }
                    }
                    
                    if (hasFunctionCall) {
                        return {
                            functionCall: funcCall,
                            content: textContent.trim(), // Optional thought text
                            geminiParts: rawParts // Store raw parts for history
                        };
                    }
                    
                    return { content: textContent.trim() || "Empty response" };
                }
                
                if (json.candidates[0].finishReason) {
                    return { content: "Response finished with reason: " + json.candidates[0].finishReason };
                }
            }
            
            return { content: "Error: Unexpected response format. Raw: " + response };
        } catch (e) {
            return { content: "Error parsing response: " + e.message + ". Raw: " + response };
        }
    }
}
