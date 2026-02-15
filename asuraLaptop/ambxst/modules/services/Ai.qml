pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import qs.config
import qs.modules.services
import "ai"
import "ai/strategies"

Singleton {
    id: root

    // ============================================
    // PROPERTIES
    // ============================================

    property string dataDir: (Quickshell.env("XDG_DATA_HOME") || (Quickshell.env("HOME") + "/.local/share")) + "/Ambxst"
    property string chatDir: dataDir + "/chats"
    property string tmpDir: "/tmp/ambxst-ai"

    property list<AiModel> models: []

    property AiModel currentModel: models.length > 0 ? models[0] : null
    property bool persistenceReady: false
    property string savedModelId: ""
    property bool isRestored: false
    property bool suppressModelPersist: false

    onCurrentModelChanged: {
        if (persistenceReady && currentModel && isRestored && !suppressModelPersist) {
            StateService.set("lastAiModel", currentModel.model);
        }
    }

    function getDefaultModelId() {
        if (Config.ai && Config.ai.defaultModel && Config.ai.defaultModel.length > 0)
            return Config.ai.defaultModel;
        return "gpt-4o-mini";
    }

    function restoreModel() {
        const lastModelId = StateService.get("lastAiModel", getDefaultModelId());
        savedModelId = lastModelId;

        // Attempt immediate restoration if models are already loaded
        tryRestore();

        persistenceReady = true;
    }

    function tryRestore() {
        if (isRestored || models.length === 0)
            return;

        let found = false;

        // 1. Exact match
        for (let i = 0; i < models.length; i++) {
            if (models[i].model === savedModelId) {
                currentModel = models[i];
                found = true;
                break;
            }
        }

        // 2. Fuzzy/Migration match (e.g. "gemini-pro" -> "gemini/gemini-pro")
        if (!found && savedModelId) {
            for (let i = 0; i < models.length; i++) {
                if (models[i].model.endsWith(savedModelId) || models[i].model.endsWith("/" + savedModelId)) {
                    currentModel = models[i];
                    found = true;
                    break;
                }
            }
        }

        if (found) {
            isRestored = true;
        }
    }

    Connections {
        target: StateService
        function onStateLoaded() {
            restoreModel();
            syncApiKeysFromState();
        }
    }

    Component.onCompleted: {
        // Ensure ai.json has apiKeys even if older config existed
        if (Config.ai && Config.ai.apiKeys === undefined) {
            Config.ai.apiKeys = {};
            Config.saveAi();
        }

        // Ensure built-in OpenAI models are always present
        addBuiltInModels();

        // If state already loaded, sync any stored keys into config
        syncApiKeysFromState();

        // Try restoration immediately if possible, or wait for signal
        if (StateService.initialized) {
            restoreModel();
        }

        // Light model refresh (local/LiteLLM) without heavy remote calls
        fetchAvailableModels();

        // Initialize chat
        reloadHistory();
        createNewChat();
    }

    // Strategies
    // We only need OpenAI strategy now since LiteLLM standardizes everything to it
    property OpenAiApiStrategy openaiStrategy: OpenAiApiStrategy {}

    // Kept for compatibility if strategy switching logic is still used elsewhere, but they are unused now
    property GeminiApiStrategy geminiStrategy: GeminiApiStrategy {}
    property MistralApiStrategy mistralStrategy: MistralApiStrategy {}

    // Always use OpenAI strategy
    property ApiStrategy currentStrategy: openaiStrategy

    function updateStrategy() {
        // No-op: LiteLLM handles the differences
        currentStrategy = openaiStrategy;
    }

    // State
    property bool isLoading: false
    property string lastError: ""
    property string responseBuffer: ""
    property int requestSerial: 0
    property int retryAttempt: 0
    property int maxRetryAttempts: 3
    property int defaultRetryDelayMs: 15000
    property int pendingRetrySerial: -1
    property bool fallbackUsed: false
    property double lastModelFetchMs: 0
    property int minFetchIntervalMs: 300000

    // Current Chat
    property var currentChat: [] // Array of { role: "user"|"assistant", content: "..." }
    property string currentChatId: ""

    // Chat History List (files)
    // Chat History List (files)
    property var chatHistory: []

    // ============================================
    // TOOLS
    // ============================================
    function regenerateResponse(index) {
        if (index < 0 || index >= currentChat.length)
            return;

        // Remove this message and everything after it
        let newChat = currentChat.slice(0, index);
        currentChat = newChat;

        isLoading = true;
        lastError = "";

        makeRequest();
    }

    function updateMessage(index, newContent) {
        if (index < 0 || index >= currentChat.length)
            return;

        let newChat = Array.from(currentChat);
        let msg = newChat[index];
        msg.content = newContent;
        newChat[index] = msg;

        currentChat = newChat;
        saveCurrentChat();
    }

    property var systemTools: [
        {
            name: "run_shell_command",
            description: "Execute a shell command on the user's system (Linux/Hyprland). Use this to list files, control the system, or run utilities. Output will be returned.",
            parameters: {
                type: "OBJECT",
                properties: {
                    command: {
                        type: "STRING",
                        description: "The shell command to run (e.g. 'ls -la', 'ip addr', 'hyprctl clients')"
                    }
                },
                required: ["command"]
            }
        }
    ]

    // ============================================
    // INIT
    // ============================================
    function deleteChat(id) {
        if (id === currentChatId) {
            createNewChat();
        }

        let filename = chatDir + "/" + id + ".json";
        deleteChatProcess.command = ["rm", filename];
        deleteChatProcess.running = true;
    }

    // ============================================
    // LOGIC
    // ============================================

    function setModel(modelName) {
        for (let i = 0; i < models.length; i++) {
            if (models[i].name === modelName) {
                currentModel = models[i];
                updateStrategy();
                return;
            }
        }
    }

    function ensureOpenAiModel(modelId, name) {
        let id = modelId || "gpt-4o-mini";
        for (let i = 0; i < models.length; i++) {
            if (models[i].model === id)
                return models[i];
        }

        let m = aiModelFactory.createObject(root, {
            name: name || id,
            icon: Qt.resolvedUrl("../../../assets/aiproviders/openai.svg"),
            description: "OpenAI Model",
            endpoint: "https://api.openai.com/v1",
            model: id,
            api_format: "OpenAI",
            requires_key: true,
            key_id: "OPENAI_API_KEY",
            key_get_link: "https://platform.openai.com/api-keys",
            key_get_description: "Create an OpenAI API key"
        });
        if (m) {
            mergeModels([m]);
            return m;
        }
        return null;
    }

    function ensureGeminiModel(modelId, name) {
        let id = modelId || "gemini-2.5-flash";
        if (id.startsWith("gemini/"))
            id = id.slice("gemini/".length);
        let liteId = "gemini/" + id;
        for (let i = 0; i < models.length; i++) {
            if (models[i].model === liteId)
                return models[i];
        }

        let m = aiModelFactory.createObject(root, {
            name: name || id,
            icon: Qt.resolvedUrl("../../../assets/aiproviders/google.svg"),
            description: "Google Gemini Model",
            endpoint: "http://127.0.0.1:4000/v1",
            model: liteId,
            api_format: "Google",
            requires_key: false
        });
        if (m) {
            mergeModels([m]);
            return m;
        }
        return null;
    }

    function normalizeKeyId(input) {
        if (!input)
            return "";
        let trimmed = input.trim();
        if (trimmed.length === 0)
            return "";

        let lower = trimmed.toLowerCase();
        if (lower.includes("_"))
            return trimmed.toUpperCase();

        switch (lower) {
        case "openai":
            return "OPENAI_API_KEY";
        case "gemini":
        case "google":
            return "GEMINI_API_KEY";
        case "mistral":
            return "MISTRAL_API_KEY";
        case "openrouter":
            return "OPENROUTER_API_KEY";
        case "github":
            return "GITHUB_TOKEN";
        case "anthropic":
            return "ANTHROPIC_API_KEY";
        case "groq":
            return "GROQ_API_KEY";
        case "deepseek":
            return "DEEPSEEK_API_KEY";
        default:
            return trimmed.toUpperCase();
        }
    }

    function getStoredApiKey(keyId) {
        if (!keyId)
            return "";

        let envKey = Quickshell.env(keyId);
        if (envKey && envKey.length > 0)
            return envKey;

        if (Config.ai && Config.ai.apiKeys) {
            if (Config.ai.apiKeys[keyId])
                return Config.ai.apiKeys[keyId];
            let upper = keyId.toUpperCase();
            if (Config.ai.apiKeys[upper])
                return Config.ai.apiKeys[upper];
        }

        let stateKeys = getStateApiKeys();
        if (stateKeys[keyId])
            return stateKeys[keyId];
        let upperState = keyId.toUpperCase();
        if (stateKeys[upperState])
            return stateKeys[upperState];

        return "";
    }

    function getApiKey(model) {
        if (!model.requires_key)
            return "";
        return getStoredApiKey(model.key_id);
    }

    function processCommand(text) {
        let cmd = text.trim();
        if (!cmd.startsWith("/"))
            return false;

        let parts = cmd.split(" ");
        let command = parts[0].toLowerCase();
        let args = parts.slice(1).join(" ");

        switch (command) {
        case "/new":
            createNewChat();
            return true;
        case "/model":
            if (args) {
                let target = args.trim();
                if (!target) {
                    pushSystemMessage("Usage: **`/model <name>`**");
                    return true;
                }

                let foundModel = findModelByQuery(target);
                if (!foundModel) {
                    let lower = target.toLowerCase();
                    if (lower.startsWith("gpt") || lower.startsWith("o") || lower.includes("openai")) {
                        foundModel = ensureOpenAiModel(target, target);
                    } else if (lower.includes("gemini") || lower.includes("flash") || lower.includes("pro")) {
                        foundModel = ensureGeminiModel(target, target);
                    }
                }

                if (!foundModel) {
                    pushSystemMessage("Model '" + target + "' not found. Refreshing models...");
                    fetchAvailableModels(true);
                } else {
                    currentModel = foundModel;
                    updateStrategy();
                    pushSystemMessage("Switched to model: " + currentModel.name);
                }
            } else {
                // Request UI to show selection popup
                modelSelectionRequested();
            }
            return true;
        case "/key": {
            let rawArgs = args.trim();
            if (!rawArgs) {
                pushSystemMessage("Usage: **`/key openai sk-...`** or **`/key OPENAI_API_KEY=sk-...`**");
                return true;
            }

            let keyId = "";
            let keyValue = "";
            if (rawArgs.includes("=")) {
                let idx = rawArgs.indexOf("=");
                keyId = rawArgs.slice(0, idx).trim();
                keyValue = rawArgs.slice(idx + 1).trim();
            } else {
                let parts = rawArgs.split(" ");
                keyId = parts.shift();
                keyValue = parts.join(" ").trim();
            }

            keyId = normalizeKeyId(keyId);
            if (!keyId || !keyValue) {
                pushSystemMessage("Usage: **`/key openai sk-...`** or **`/key OPENAI_API_KEY=sk-...`**");
                return true;
            }

            let updated = Config.ai && Config.ai.apiKeys ? JSON.parse(JSON.stringify(Config.ai.apiKeys)) : ({});
            updated[keyId] = keyValue;
            if (Config.ai) {
                Config.ai.apiKeys = updated;
                Config.saveAi();
            }
            if (StateService.initialized) {
                StateService.set("aiApiKeys", updated);
            }

            pushSystemMessage("Saved API key for **" + keyId + "**. Refreshing models...");
            fetchAvailableModels(true);
            return true;
        }
        case "/help":
            pushSystemMessage("🤖 **Assistant Commands**\n\n" + "**`/new`**\n" + "Starts a fresh conversation context.\n\n" + "**`/model [name]`**\n" + "Switches the active AI model.\n" + "• **List models:** Type `/model` without arguments.\n" + "• **Switch:** Type `/model gemini` or `/model mistral`.\n\n" + "**`/key <provider> <key>`**\n" + "Saves an API key (e.g. `/key openai sk-...`).\n\n" + "**`/help`**\n" + "Shows this help message.\n\n" + "💡 **Tips:**\n" + "• **Edit:** Click the pen icon on any message to modify it.\n" + "• **Regenerate:** Click the refresh icon to get a new response.\n" + "• **Copy:** Use the copy button to grab code or text.");
            return true;
        }

        return false;
    }

    function pushSystemMessage(text) {
        let newChat = Array.from(currentChat);
        newChat.push({
            role: "system",
            content: text
        });
        currentChat = newChat;
    }

    // Function Call Handling
    function approveCommand(index) {
        let msg = currentChat[index];
        if (!msg.functionCall)
            return;

        // Update message state
        let newChat = Array.from(currentChat);
        newChat[index].functionPending = false;
        newChat[index].functionApproved = true;
        currentChat = newChat;
        saveCurrentChat();

        // Execute
        let args = msg.functionCall.args;
        if (msg.functionCall.name === "run_shell_command") {
            commandExecutionProc.command = ["bash", "-c", args.command];
            commandExecutionProc.targetIndex = index;
            commandExecutionProc.running = true;
        }
    }

    function rejectCommand(index) {
        let newChat = Array.from(currentChat);
        newChat[index].functionPending = false;
        newChat[index].functionApproved = false;

        // Add system message indicating rejection
        newChat.push({
            role: "function",
            name: newChat[index].functionCall.name,
            content: "User rejected the command execution."
        });

        currentChat = newChat;
        saveCurrentChat();

        // Continue conversation
        makeRequest();
    }

    function sendMessage(text) {
        if (text.trim() === "")
            return;

        if (processCommand(text))
            return;

        isLoading = true;
        lastError = "";

        // Add user message to UI immediately
        let userMsg = {
            role: "user",
            content: text
        };
        let newChat = Array.from(currentChat);
        newChat.push(userMsg);
        currentChat = newChat;

        makeRequest();
    }

    function makeRequest(resetRetry) {
        if (resetRetry === undefined)
            resetRetry = true;

        if (resetRetry) {
            requestSerial++;
            retryAttempt = 0;
            pendingRetrySerial = -1;
            fallbackUsed = false;
            retryTimer.stop();
        }

        if (!currentModel) {
            let fallback = findOpenAiFallbackModel();
            if (!fallback)
                fallback = findGeminiFallbackModel();
            if (fallback) {
                currentModel = fallback;
                updateStrategy();
            } else {
                lastError = "No AI model available. Add a model or set an API key.";
                isLoading = false;
                let errChat = Array.from(currentChat);
                errChat.push({
                    role: "assistant",
                    content: "Error: " + lastError
                });
                currentChat = errChat;
                return;
            }
        }

        // Prepare Request
        let apiKey = getApiKey(currentModel);
        if (!apiKey && currentModel.requires_key) {
            let keyId = currentModel.key_id || "API key";
            let hint = "Set " + keyId + " with /key or as an environment variable.";
            if (currentModel.key_get_link && currentModel.key_get_link.length > 0) {
                hint += " Get a key at " + currentModel.key_get_link;
            }
            lastError = "API Key missing for " + currentModel.name + ". " + hint;
            isLoading = false;

            let errChat = Array.from(currentChat);
            errChat.push({
                role: "assistant",
                content: "Error: " + lastError
            });
            currentChat = errChat;
            return;
        }

        let endpoint = currentStrategy.getEndpoint(currentModel, apiKey);
        let headers = currentStrategy.getHeaders(apiKey);

        // Include system prompt
        let messages = [];
        if (Config.ai.systemPrompt) {
            messages.push({
                role: "system",
                content: Config.ai.systemPrompt
            });
        }
        // Add history (simple version: all messages)
        // Note: Gemini doesn't support 'system' role in messages list the same way, handled in strategy
        for (let i = 0; i < currentChat.length; i++) {
            let msg = currentChat[i];
            // Sanitize message object for strict APIs
            let apiMsg = {
                role: msg.role,
                content: msg.content
            };

            // Only include function call info if relevant and supported (though currently strategies might ignore)
            if (msg.functionCall)
                apiMsg.functionCall = msg.functionCall;
            if (msg.geminiParts)
                apiMsg.geminiParts = msg.geminiParts; // Preserve Gemini parts
            if (msg.name)
                apiMsg.name = msg.name; // For function role

            messages.push(apiMsg);
        }

        // Pass tools
        let body = currentStrategy.getBody(messages, currentModel, systemTools);

        // Write body to temp file
        writeTempBody(JSON.stringify(body), headers, endpoint);
    }

    function shouldRetry(reply) {
        if (!reply || !reply.error)
            return false;

        if (retryAttempt >= maxRetryAttempts)
            return false;

        if (reply.errorCode !== undefined && reply.errorCode !== null) {
            let codeNum = parseInt(reply.errorCode, 10);
            if (!isNaN(codeNum) && codeNum === 429)
                return true;
            if (reply.errorCode === "429")
                return true;
            if (typeof reply.errorCode === "string" && /rate|limit/i.test(reply.errorCode))
                return true;
        }

        if (reply.errorStatus === "RESOURCE_EXHAUSTED")
            return true;

        let msg = (reply.errorMessage || reply.content || "");
        if (/rate limit|quota|too many requests|resource_exhausted/i.test(msg))
            return true;

        return false;
    }

    function scheduleRetry(delayMs) {
        let safeDelay = delayMs;
        if (!safeDelay || safeDelay < 1000)
            safeDelay = 1000;
        safeDelay += 500;

        retryAttempt++;
        pendingRetrySerial = requestSerial;
        retryTimer.interval = safeDelay;
        retryTimer.stop();
        retryTimer.start();

        let seconds = Math.round(safeDelay / 1000);
        lastError = "Rate limited. Retrying in " + seconds + "s (" + retryAttempt + "/" + maxRetryAttempts + ")";
    }

    function isModelNotFound(reply) {
        if (!reply || !reply.error)
            return false;

        if (reply.errorCode === "model_not_found")
            return true;

        let msg = (reply.errorMessage || reply.content || "");
        return /model.*not found|model_not_found|unknown model/i.test(msg);
    }

    function isOpenAiModel(model) {
        if (!model)
            return false;
        let provider = (model.api_format || "").toLowerCase();
        if (provider.includes("openai"))
            return true;
        return false;
    }

    function isGeminiModel(model) {
        if (!model)
            return false;
        let provider = (model.api_format || "").toLowerCase();
        let id = (model.model || "").toLowerCase();
        return provider.includes("google") || id.includes("gemini");
    }

    function findGeminiFallbackModel() {
        for (let i = 0; i < models.length; i++) {
            let m = models[i];
            let provider = (m.api_format || "").toLowerCase();
            let id = (m.model || "").toLowerCase();
            if (provider.includes("google") || id.includes("gemini"))
                return m;
        }
        let geminiKey = getStoredApiKey("GEMINI_API_KEY");
        if (!geminiKey)
            return null;
        return ensureGeminiModel("gemini-2.5-flash", "Gemini 2.5 Flash");
    }

    function findOpenAiFallbackModel() {
        let openAiKey = getStoredApiKey("OPENAI_API_KEY");
        if (!openAiKey)
            return null;
        for (let i = 0; i < models.length; i++) {
            let m = models[i];
            if (isOpenAiModel(m))
                return m;
        }
        return ensureOpenAiModel(getDefaultModelId(), "GPT-4o Mini");
    }

    function getStateApiKeys() {
        if (!StateService.initialized)
            return ({});
        let stored = StateService.get("aiApiKeys", ({}));
        if (!stored || typeof stored !== "object")
            return ({});
        return stored;
    }

    function syncApiKeysFromState() {
        if (!StateService.initialized || !Config.ai)
            return;
        let stateKeys = getStateApiKeys();
        if (!stateKeys || Object.keys(stateKeys).length === 0)
            return;

        let configKeys = Config.ai.apiKeys || ({});
        if (!configKeys || Object.keys(configKeys).length === 0) {
            Config.ai.apiKeys = stateKeys;
            Config.saveAi();
        }
    }

    function findModelByQuery(query) {
        if (!query)
            return null;
        let q = query.toLowerCase();
        for (let i = 0; i < models.length; i++) {
            let m = models[i];
            let name = (m.name || "").toLowerCase();
            let id = (m.model || "").toLowerCase();
            if (name.includes(q) || id === q || id.endsWith("/" + q))
                return m;
        }
        return null;
    }

    function writeTempBody(jsonBody, headers, endpoint) {
        // Create tmp dir
        requestProcess.command = ["mkdir", "-p", tmpDir];
        requestProcess.step = "mkdir";
        requestProcess.payload = {
            body: jsonBody,
            headers: headers,
            endpoint: endpoint
        };
        requestProcess.running = true;
    }

    function executeRequest(payload) {
        let bodyPath = tmpDir + "/body.json";

        // Write body.json
        // We use a separate process call for writing to avoid command line length limits
        writeBodyProcess.command = ["sh", "-c", "echo '" + payload.body.replace(/'/g, "'\\''") + "' > " + bodyPath];
        writeBodyProcess.payload = payload; // pass through
        writeBodyProcess.running = true;
    }

    function runCurl(payload) {
        let bodyPath = tmpDir + "/body.json";
        let headerArgs = payload.headers.map(h => "-H \"" + h + "\"").join(" ");

        let curlCmd = "curl -s -X POST \"" + payload.endpoint + "\" " + headerArgs + " -d @" + bodyPath;

        curlProcess.command = ["bash", "-c", curlCmd];
        curlProcess.running = true;
    }

    // ============================================
    // PROCESSES
    // ============================================

    Process {
        id: requestProcess
        property string step: ""
        property var payload: ({})

        onExited: exitCode => {
            if (exitCode === 0 && step === "mkdir") {
                executeRequest(payload);
            } else {
                root.lastError = "Failed to create temp directory (mkdir exited with " + exitCode + ")";
                root.isLoading = false;
                let errChat = Array.from(root.currentChat);
                errChat.push({
                    role: "assistant",
                    content: "Error: " + root.lastError
                });
                root.currentChat = errChat;
            }
        }
    }

    Process {
        id: writeBodyProcess
        property var payload: ({})
        stderr: StdioCollector {
            id: writeBodyStderr
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                runCurl(payload);
            } else {
                root.lastError = "Failed to write request body: " + writeBodyStderr.text;
                root.isLoading = false;
                let errChat = Array.from(root.currentChat);
                errChat.push({
                    role: "assistant",
                    content: "Error: " + root.lastError
                });
                root.currentChat = errChat;
            }
        }
    }

    Process {
        id: curlProcess

        stdout: StdioCollector {
            id: curlStdout
        }
        stderr: StdioCollector {
            id: curlStderr
        }

        onExited: exitCode => {
            if (exitCode === 0) {
                let responseText = curlStdout.text;
                let reply = root.currentStrategy.parseResponse(responseText);

                if (root.isModelNotFound(reply) && !root.fallbackUsed) {
                    let fallback = root.findOpenAiFallbackModel();
                    if (!fallback)
                        fallback = root.findGeminiFallbackModel();
                    if (fallback && root.currentModel && fallback.model !== root.currentModel.model) {
                        root.fallbackUsed = true;
                        root.suppressModelPersist = true;
                        root.currentModel = fallback;
                        root.suppressModelPersist = false;
                        root.updateStrategy();
                        root.pushSystemMessage("Model not found. Switching to **" + fallback.name + "** and retrying...");
                        root.makeRequest(true);
                        return;
                    }
                }

                if (root.shouldRetry(reply)) {
                    if (!root.fallbackUsed && root.isOpenAiModel(root.currentModel)) {
                        let fallback = root.findGeminiFallbackModel();
                        if (fallback && fallback.model !== root.currentModel.model) {
                            root.fallbackUsed = true;
                            root.suppressModelPersist = true;
                            root.currentModel = fallback;
                            root.suppressModelPersist = false;
                            root.updateStrategy();
                            root.pushSystemMessage("OpenAI rate limit hit. Switching to **" + fallback.name + "** and retrying...");
                            root.makeRequest(true);
                            return;
                        }
                    }
                    if (!root.fallbackUsed && root.isGeminiModel(root.currentModel)) {
                        let fallback = root.findOpenAiFallbackModel();
                        if (fallback && fallback.model !== root.currentModel.model) {
                            root.fallbackUsed = true;
                            root.suppressModelPersist = true;
                            root.currentModel = fallback;
                            root.suppressModelPersist = false;
                            root.updateStrategy();
                            root.pushSystemMessage("Gemini rate limit hit. Switching to **" + fallback.name + "** and retrying...");
                            root.makeRequest(true);
                            return;
                        }
                    }

                    let delayMs = root.defaultRetryDelayMs;
                    if (reply.retryAfter && reply.retryAfter > 0)
                        delayMs = Math.ceil(reply.retryAfter * 1000);
                    root.scheduleRetry(delayMs);
                    return;
                }

                root.isLoading = false;
                if (reply.error) {
                    root.lastError = reply.errorMessage || reply.content || "Unknown API error";
                } else {
                    root.lastError = "";
                }

                let newChat = Array.from(root.currentChat);

                if (reply.content) {
                    newChat.push({
                        role: "assistant",
                        content: reply.content,
                        model: root.currentModel ? root.currentModel.name : "Unknown"
                    });
                }

                if (reply.functionCall) {
                    // It's a tool call
                    let funcMsg = {
                        role: "assistant",
                        content: "I want to run a command: `" + reply.functionCall.name + "`",
                        functionCall: reply.functionCall,
                        functionPending: true // UI will show Approve/Reject
                        ,
                        geminiParts: reply.geminiParts // Store raw parts (thoughts) for API history
                    };
                    newChat.push(funcMsg);
                }

                root.currentChat = newChat;
                root.saveCurrentChat();

                // If it was just a text reply, stop loading. If it's a function, we wait for user.
                if (!reply.functionCall) {
                    root.isLoading = false;
                }
            } else {
                root.isLoading = false;
                root.lastError = "Network Request Failed: " + curlStderr.text;

                let errChat = Array.from(root.currentChat);
                errChat.push({
                    role: "assistant",
                    content: "Error: " + root.lastError
                });
                root.currentChat = errChat;
            }
        }
    }

    Timer {
        id: retryTimer
        repeat: false
        onTriggered: {
            if (pendingRetrySerial !== requestSerial)
                return;
            // Keep isLoading true and retry the same request.
            makeRequest(false);
        }
    }

    Process {
        id: commandExecutionProc
        property int targetIndex: -1

        stdout: StdioCollector {
            id: cmdStdout
        }
        stderr: StdioCollector {
            id: cmdStderr
        }

        onExited: exitCode => {
            let output = cmdStdout.text + "\n" + cmdStderr.text;
            if (output.trim() === "")
                output = "Command executed successfully (no output).";

            // Add function response
            let msg = currentChat[targetIndex];
            let newChat = Array.from(currentChat);

            newChat.push({
                role: "function",
                name: msg.functionCall.name,
                content: output
            });

            root.currentChat = newChat;
            root.saveCurrentChat();

            // Continue conversation
            root.makeRequest();
        }
    }

    // ============================================
    // CHAT STORAGE
    // ============================================

    function createNewChat() {
        currentChat = [];
        currentChatId = Date.now().toString();
        chatModelChanged();
    }

    function saveCurrentChat() {
        if (currentChat.length === 0)
            return;

        let filename = chatDir + "/" + currentChatId + ".json";
        let data = JSON.stringify(currentChat, null, 2);

        saveChatProcess.command = ["sh", "-c", "mkdir -p " + chatDir + " && echo '" + data.replace(/'/g, "'\\''") + "' > " + filename];
        saveChatProcess.running = true;
    }

    function reloadHistory() {
        // List files in chatDir
        listHistoryProcess.command = ["sh", "-c", "mkdir -p " + chatDir + " && ls -t " + chatDir + "/*.json"];
        listHistoryProcess.running = true;
    }

    function loadChat(id) {
        let filename = chatDir + "/" + id + ".json";
        loadChatProcess.targetId = id;
        loadChatProcess.command = ["cat", filename];
        loadChatProcess.running = true;
    }

    Process {
        id: saveChatProcess
        onExited: reloadHistory()
    }

    Process {
        id: deleteChatProcess
        onExited: reloadHistory()
    }

    Process {
        id: listHistoryProcess
        stdout: StdioCollector {
            id: listHistoryStdout
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                let lines = listHistoryStdout.text.trim().split("\n");
                let history = [];
                for (let i = 0; i < lines.length; i++) {
                    let path = lines[i];
                    if (path === "")
                        continue;
                    let filename = path.split("/").pop();
                    let id = filename.replace(".json", "");
                    history.push({
                        id: id,
                        path: path
                    });
                }
                root.chatHistory = history;
                root.historyModelChanged();
            }
        }
    }

    Process {
        id: loadChatProcess
        property string targetId: ""
        stdout: StdioCollector {
            id: loadChatStdout
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    root.currentChat = JSON.parse(loadChatStdout.text);
                    root.currentChatId = targetId;
                    root.chatModelChanged();
                } catch (e) {
                    console.log("Error loading chat: " + e);
                }
            }
        }
    }

    // ============================================
    // DYNAMIC MODEL FETCHING
    // ============================================

    property bool fetchingModels: false
    property int pendingFetches: 0

    function addBuiltInModels() {
        let newModels = [];
        let openAiModels = [
            {
                name: "GPT-4o Mini",
                model: "gpt-4o-mini"
            },
            {
                name: "GPT-4o",
                model: "gpt-4o"
            }
        ];

        for (let i = 0; i < openAiModels.length; i++) {
            let item = openAiModels[i];
            let m = aiModelFactory.createObject(root, {
                name: item.name,
                icon: Qt.resolvedUrl("../../../assets/aiproviders/openai.svg"),
                description: "OpenAI Model",
                endpoint: "https://api.openai.com/v1",
                model: item.model,
                api_format: "OpenAI",
                requires_key: true,
                key_id: "OPENAI_API_KEY",
                key_get_link: "https://platform.openai.com/api-keys",
                key_get_description: "Create an OpenAI API key"
            });
            if (m)
                newModels.push(m);
        }

        if (newModels.length > 0)
            mergeModels(newModels);
    }

    function addExtraModels() {
        if (!Config.ai || !Config.ai.extraModels || Config.ai.extraModels.length === 0)
            return;

        let newModels = [];
        for (let i = 0; i < Config.ai.extraModels.length; i++) {
            let item = Config.ai.extraModels[i];
            if (!item || !item.model || !item.endpoint || !item.api_format)
                continue;

            let m = aiModelFactory.createObject(root, {
                name: item.name || item.model,
                icon: item.icon || "",
                description: item.description || "",
                endpoint: item.endpoint,
                model: item.model,
                api_format: item.api_format,
                requires_key: item.requires_key === true,
                key_id: item.key_id || "",
                key_get_link: item.key_get_link || "",
                key_get_description: item.key_get_description || ""
            });
            if (m)
                newModels.push(m);
        }

        if (newModels.length > 0)
            mergeModels(newModels);
    }

    function fetchAvailableModels(force) {
        if (force === undefined)
            force = false;
        if (fetchingModels)
            return;

        addBuiltInModels();
        addExtraModels();

        let now = Date.now();
        if (!force && lastModelFetchMs > 0 && (now - lastModelFetchMs) < minFetchIntervalMs) {
            return;
        }

        lastModelFetchMs = now;
        fetchingModels = true;
        // We'll fetch from multiple sources again to populate the list dynamically
        // but point them all to the local LiteLLM proxy for execution.
        pendingFetches = 0;

        if (force) {
            // Gemini
            let geminiKey = getStoredApiKey("GEMINI_API_KEY");
            if (geminiKey) {
                pendingFetches++;
                fetchProcessGemini.command = ["bash", "-c", "curl -s 'https://generativelanguage.googleapis.com/v1beta/models?key=" + geminiKey + "'"];
                fetchProcessGemini.running = true;
            }

            // OpenAI (direct)
            let openAiKey = getStoredApiKey("OPENAI_API_KEY");
            if (openAiKey) {
                pendingFetches++;
                fetchProcessOpenAi.command = ["bash", "-c", "curl -s https://api.openai.com/v1/models -H 'Authorization: Bearer " + openAiKey + "'"];
                fetchProcessOpenAi.running = true;
            }

            // Mistral
            let mistralKey = getStoredApiKey("MISTRAL_API_KEY");
            if (mistralKey) {
                pendingFetches++;
                fetchProcessMistral.command = ["bash", "-c", "curl -s https://api.mistral.ai/v1/models -H 'Authorization: Bearer " + mistralKey + "'"];
                fetchProcessMistral.running = true;
            }

            // OpenRouter
            let openRouterKey = getStoredApiKey("OPENROUTER_API_KEY");
            if (openRouterKey) {
                pendingFetches++;
                fetchProcessOpenRouter.command = ["bash", "-c", "curl -s https://openrouter.ai/api/v1/models -H 'Authorization: Bearer " + openRouterKey + "'"];
                fetchProcessOpenRouter.running = true;
            }

            // GitHub Models (Static fallback/simulation as before since listing is complex)
            if (getStoredApiKey("GITHUB_TOKEN")) {
                pendingFetches++;
                fetchProcessGithub.command = ["echo", '{"data": [{"id": "gpt-4o"}, {"id": "gpt-4o-mini"}]}'];
                fetchProcessGithub.running = true;
            }
        }

        // Ollama (Local)
        pendingFetches++;
        fetchProcessOllama.command = ["bash", "-c", "curl -s --max-time 1 http://127.0.0.1:11434/api/tags"];
        fetchProcessOllama.running = true;

        // Check LiteLLM for locally configured models
        pendingFetches++;
        fetchProcessLiteLLM.command = ["bash", "-c", "curl -s --max-time 1 http://127.0.0.1:4000/v1/models"];
        fetchProcessLiteLLM.running = true;

        if (pendingFetches === 0) {
            fetchingModels = false;
            tryRestore();
            if (!currentModel && models.length > 0) {
                currentModel = models[0];
                isRestored = true;
            } else if (!isRestored && currentModel) {
                isRestored = true;
            }
        }
    }

    // We keep this generic LiteLLM fetcher as a fallback or for models defined strictly in config
    Process {
        id: fetchProcessLiteLLM
        stdout: StdioCollector {
            id: fetchLiteLLMOut
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    let data = JSON.parse(fetchLiteLLMOut.text);
                    if (data.data) {
                        let newModels = [];
                        for (let i = 0; i < data.data.length; i++) {
                            let item = data.data[i];
                            let id = item.id;

                            // Determine icon based on name
                            let iconPath = "robot";
                            let provider = "OpenAI";

                            if (id.includes("gemini")) {
                                iconPath = Qt.resolvedUrl("../../../assets/aiproviders/google.svg");
                                provider = "Google";
                            } else if (id.includes("gpt")) {
                                iconPath = Qt.resolvedUrl("../../../assets/aiproviders/openai.svg");
                                provider = "OpenAI";
                            } else if (id.includes("mistral")) {
                                iconPath = Qt.resolvedUrl("../../../assets/aiproviders/mistral.svg");
                                provider = "Mistral";
                            } else if (id.includes("claude")) {
                                iconPath = Qt.resolvedUrl("../../../assets/aiproviders/anthropic.svg");
                                provider = "Anthropic";
                            } else if (id.includes("deepseek")) {
                                iconPath = Qt.resolvedUrl("../../../assets/aiproviders/deepseek.svg");
                                provider = "DeepSeek";
                            }

                            let m = aiModelFactory.createObject(root, {
                                name: id,
                                icon: iconPath,
                                description: "LiteLLM Model: " + id,
                                endpoint: "http://127.0.0.1:4000/v1",
                                model: id,
                                api_format: provider,
                                requires_key: false
                            });
                            if (m)
                                newModels.push(m);
                        }
                        mergeModels(newModels);
                    }
                } catch (e) {
                    console.log("LiteLLM fetch error: " + e);
                }
            }
            checkFetchCompletion();
        }
    }

    Process {
        id: fetchProcessGemini
        stdout: StdioCollector {
            id: fetchGeminiOut
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    let data = JSON.parse(fetchGeminiOut.text);
                    if (data.models) {
                        let newModels = [];
                        for (let i = 0; i < data.models.length; i++) {
                            let item = data.models[i];
                            let id = item.name.replace("models/", "");
                            // Filter for generative models
                            if (id.includes("gemini") || id.includes("flash") || id.includes("pro")) {
                                let m = aiModelFactory.createObject(root, {
                                    name: item.displayName || id,
                                    icon: Qt.resolvedUrl("../../../assets/aiproviders/google.svg"),
                                    description: item.description || "Google Gemini Model",
                                    endpoint: "http://127.0.0.1:4000/v1" // Point to LiteLLM
                                    ,
                                    model: "gemini/" + id // Prefix for LiteLLM
                                    ,
                                    api_format: "Google",
                                    requires_key: false // Auth handled by LiteLLM environment
                                });
                                if (m)
                                    newModels.push(m);
                            }
                        }
                        mergeModels(newModels);
                    }
                } catch (e) {
                    console.log("Gemini fetch error: " + e);
                }
            }
            checkFetchCompletion();
        }
    }

    Process {
        id: fetchProcessOpenAi
        stdout: StdioCollector {
            id: fetchOpenAiOut
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    let data = JSON.parse(fetchOpenAiOut.text);
                    if (data.data) {
                        let newModels = [];
                        for (let i = 0; i < data.data.length; i++) {
                            let item = data.data[i];
                            let id = item.id;
                            let lower = id.toLowerCase();

                            if (!(lower.startsWith("gpt") || lower.startsWith("o")))
                                continue;

                            let m = aiModelFactory.createObject(root, {
                                name: id,
                                icon: Qt.resolvedUrl("../../../assets/aiproviders/openai.svg"),
                                description: "OpenAI Model",
                                endpoint: "https://api.openai.com/v1",
                                model: id,
                                api_format: "OpenAI",
                                requires_key: true,
                                key_id: "OPENAI_API_KEY",
                                key_get_link: "https://platform.openai.com/api-keys",
                                key_get_description: "Create an OpenAI API key"
                            });
                            if (m)
                                newModels.push(m);
                        }
                        mergeModels(newModels);
                    }
                } catch (e) {
                    console.log("OpenAI fetch error: " + e);
                }
            }
            checkFetchCompletion();
        }
    }

    Process {
        id: fetchProcessMistral
        stdout: StdioCollector {
            id: fetchMistralOut
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    let data = JSON.parse(fetchMistralOut.text);
                    if (data.data) {
                        let newModels = [];
                        for (let i = 0; i < data.data.length; i++) {
                            let item = data.data[i];
                            let id = item.id;
                            let m = aiModelFactory.createObject(root, {
                                name: id,
                                icon: Qt.resolvedUrl("../../../assets/aiproviders/mistral.svg"),
                                description: "Mistral Model",
                                endpoint: "http://127.0.0.1:4000/v1" // Point to LiteLLM
                                ,
                                model: "mistral/" + id // Prefix for LiteLLM
                                ,
                                api_format: "Mistral",
                                requires_key: false
                            });
                            if (m)
                                newModels.push(m);
                        }
                        mergeModels(newModels);
                    }
                } catch (e) {
                    console.log("Mistral fetch error: " + e);
                }
            }
            checkFetchCompletion();
        }
    }

    Process {
        id: fetchProcessOpenRouter
        stdout: StdioCollector {
            id: fetchOpenRouterOut
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    let data = JSON.parse(fetchOpenRouterOut.text);
                    if (data.data) {
                        let newModels = [];
                        let limit = 30; // Increased limit
                        for (let i = 0; i < Math.min(data.data.length, limit); i++) {
                            let item = data.data[i];
                            let id = item.id;
                            let m = aiModelFactory.createObject(root, {
                                name: item.name || id,
                                icon: id.includes("deepseek") ? Qt.resolvedUrl("../../../assets/aiproviders/deepseek.svg") : (id.includes("anthropic") ? Qt.resolvedUrl("../../../assets/aiproviders/anthropic.svg") : (id.includes("perplexity") ? Qt.resolvedUrl("../../../assets/aiproviders/perplexity.svg") : Qt.resolvedUrl("../../../assets/aiproviders/openrouter.svg"))),
                                description: "OpenRouter: " + id,
                                endpoint: "http://127.0.0.1:4000/v1" // Point to LiteLLM
                                ,
                                model: "openrouter/" + id // Prefix for LiteLLM
                                ,
                                api_format: "OpenRouter",
                                requires_key: false
                            });
                            if (m)
                                newModels.push(m);
                        }
                        mergeModels(newModels);
                    }
                } catch (e) {
                    console.log("OpenRouter fetch error: " + e);
                }
            }
            checkFetchCompletion();
        }
    }

    Process {
        id: fetchProcessOllama
        stdout: StdioCollector {
            id: fetchOllamaOut
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    let data = JSON.parse(fetchOllamaOut.text);
                    if (data.models) {
                        let newModels = [];
                        for (let i = 0; i < data.models.length; i++) {
                            let item = data.models[i];
                            let m = aiModelFactory.createObject(root, {
                                name: item.name,
                                icon: Qt.resolvedUrl("../../../assets/aiproviders/ollama.svg"),
                                description: "Local Ollama Model",
                                endpoint: "http://127.0.0.1:4000/v1" // Point to LiteLLM
                                ,
                                model: "ollama/" + item.name // Prefix for LiteLLM
                                ,
                                api_format: "Ollama",
                                requires_key: false
                            });
                            if (m)
                                newModels.push(m);
                        }
                        mergeModels(newModels);
                    }
                } catch (e) {
                    console.log("Ollama fetch error: " + e);
                }
            }
            checkFetchCompletion();
        }
    }

    Process {
        id: fetchProcessGithub
        stdout: StdioCollector {
            id: fetchGithubOut
        }
        onExited: exitCode => {
            if (exitCode === 0) {
                try {
                    let data = JSON.parse(fetchGithubOut.text);
                    if (data.data) {
                        let newModels = [];
                        for (let i = 0; i < data.data.length; i++) {
                            let item = data.data[i];
                            let id = item.id;
                            let m = aiModelFactory.createObject(root, {
                                name: id + " (GitHub)",
                                icon: Qt.resolvedUrl("../../../assets/aiproviders/github.svg"),
                                description: "GitHub Model via Azure",
                                endpoint: "http://127.0.0.1:4000/v1" // Point to LiteLLM
                                ,
                                model: "azure/" + id // Prefix for LiteLLM (GitHub models usually use azure provider in LiteLLM)
                                ,
                                api_format: "GitHub",
                                requires_key: false
                            });
                            if (m)
                                newModels.push(m);
                        }
                        mergeModels(newModels);
                    }
                } catch (e) {
                    console.log("GitHub fetch error: " + e);
                }
            }
            checkFetchCompletion();
        }
    }

    function checkFetchCompletion() {
        pendingFetches--;
        if (pendingFetches <= 0) {
            fetchingModels = false;
            pendingFetches = 0;

            // Try to restore user preference one last time with full list
            tryRestore();

            // Auto-select first model if restoration failed and nothing is selected
            if (!currentModel && models.length > 0) {
                currentModel = models[0];
                isRestored = true; // Mark as settled so future changes are saved
            } else if (!isRestored && currentModel) {
                // Current model exists (maybe default) but restoration wasn't explicit match
                isRestored = true;
            }
        }
    }

    function mergeModels(newModels) {
        // Create a map of existing models by name to avoid duplicates
        let existingMap = {};
        for (let i = 0; i < models.length; i++) {
            existingMap[models[i].name] = true;
        }

        let updatedList = [];
        // Keep hardcoded/existing models first? Or allow overwriting?
        // Let's keep existing ones and append new ones.
        for (let i = 0; i < models.length; i++) {
            updatedList.push(models[i]);
        }

        for (let i = 0; i < newModels.length; i++) {
            let m = newModels[i];
            // Simple duplicate check by name or model ID
            let isDuplicate = false;
            for (let j = 0; j < updatedList.length; j++) {
                if (updatedList[j].model === m.model) {
                    isDuplicate = true;
                    break;
                }
            }

            if (!isDuplicate) {
                updatedList.push(m);
            }
        }

        models = updatedList;

        // Try to restore as soon as new models arrive
        if (!isRestored)
            tryRestore();
    }

    // Signals
    signal chatModelChanged
    signal historyModelChanged
    signal modelSelectionRequested

    Component {
        id: aiModelFactory
        AiModel {}
    }
}
