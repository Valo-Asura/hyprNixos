import QtQuick
import "../AiModel.qml"

ApiStrategy {
    function parseRetryAfterSeconds(err) {
        let maxDelay = 0;
        if (!err || typeof err !== "object")
            return 0;

        if (err.details && err.details.length) {
            for (let i = 0; i < err.details.length; i++) {
                let detail = err.details[i];
                if (detail && detail.retryDelay) {
                    let match = /([0-9.]+)s/.exec(detail.retryDelay);
                    if (match)
                        maxDelay = Math.max(maxDelay, parseFloat(match[1]));
                }
            }
        }

        if (err.retryAfter) {
            let match = /([0-9.]+)s/.exec(err.retryAfter);
            if (match)
                maxDelay = Math.max(maxDelay, parseFloat(match[1]));
        }

        if (err.message && typeof err.message === "string") {
            let msgMatch = /retry in\s+([0-9.]+)s/i.exec(err.message);
            if (msgMatch)
                maxDelay = Math.max(maxDelay, parseFloat(msgMatch[1]));
        }

        return maxDelay;
    }

    function getEndpoint(modelObj, apiKey) {
        return modelObj.endpoint + "/chat/completions";
    }

    function getHeaders(apiKey) {
        return [
            "Content-Type: application/json",
            "Authorization: Bearer " + apiKey
        ];
    }

    function getBody(messages, model, tools) {
        return {
            model: model.model,
            messages: messages,
            temperature: 0.7
        };
    }
    
    function parseResponse(response) {
        try {
            let json = JSON.parse(response);
            if (json.choices && json.choices.length > 0) {
                return { content: json.choices[0].message.content };
            }
            if (json.error) {
                let msg = "";
                if (typeof json.error === "string") {
                    msg = json.error;
                } else if (json.error.message) {
                    msg = json.error.message;
                } else {
                    msg = JSON.stringify(json.error);
                }

                return {
                    content: "API Error: " + msg,
                    error: true,
                    errorCode: json.error.code,
                    errorStatus: json.error.status,
                    errorMessage: msg,
                    retryAfter: parseRetryAfterSeconds(json.error)
                };
            }
            return { content: "Error: No content in response. Raw: " + JSON.stringify(json) };
        } catch (e) {
            return { content: "Error parsing response: " + e.message };
        }
    }
}
