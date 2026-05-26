function varargout = llm_core(command, varargin)
%LLM_CORE Shared local Ollama helper with optional chat context.

commandText = string(command);
commandText = strtrim(commandText);

if strlength(commandText) == 0
    error('llm:EmptyCommand', 'Command must not be empty.');
end

switch lower(commandText)
    case "help"
        helpText = join([
            "llm help",
            "  Show usage.",
            "llm(""prompt"")",
            "  Return one response without context.",
            "llmp(""prompt"")",
            "  Print one response without context.",
            "llmc(""prompt"")",
            "  Continue chat with saved context.",
            "llmreset",
            "  Clear saved chat context.",
            "llm('session')",
            "  Show current saved messages count."
        ], newline);
        varargout{1} = helpText;
    case "reset"
        setSessionMessages({});
        varargout{1} = "Chat context cleared.";
    case "session"
        currentMessages = getSessionMessages();
        varargout{1} = struct('message_count', numel(currentMessages));
    otherwise
        error('llm:UnknownCommand', 'Unknown llm command: %s', commandText);
end
end

function responseText = llm_generate(prompt, varargin)
responseText = askllm_core(prompt, varargin{:});
end

function responseText = llm_chat(prompt, varargin)
promptText = string(prompt);

if strlength(strtrim(promptText)) == 0
    error('llm:EmptyPrompt', 'Prompt must not be empty.');
end

opts = parseChatOptions(varargin{:});
messages = getSessionMessages();
messages{end + 1} = struct('role', 'user', 'content', char(promptText));

payload = struct( ...
    'model', char(opts.Model), ...
    'messages', {messages}, ...
    'stream', false);

requestOptions = weboptions( ...
    'MediaType', 'application/json', ...
    'Timeout', opts.Timeout);

try
    result = webwrite(char(opts.Url), payload, requestOptions);
catch err
    error('llm:RequestFailed', 'Ollama chat request failed: %s', err.message);
end

responseText = extractChatText(result);
messages{end + 1} = struct('role', 'assistant', 'content', char(responseText));
setSessionMessages(messages);
end

function opts = parseChatOptions(varargin)
parser = inputParser;
parser.FunctionName = 'llm_chat';
addParameter(parser, 'Model', "qwen2.5-coder:7b", @isTextScalarLike);
addParameter(parser, 'Url', "http://localhost:11434/api/chat", @isTextScalarLike);
addParameter(parser, 'Timeout', 180, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
parse(parser, varargin{:});

opts = struct( ...
    'Model', string(parser.Results.Model), ...
    'Url', string(parser.Results.Url), ...
    'Timeout', parser.Results.Timeout);
end

function text = extractChatText(result)
if isstruct(result) && isfield(result, 'message') && isstruct(result.message) && isfield(result.message, 'content')
    text = string(result.message.content);
else
    text = string(jsonencode(result));
end
end

function messages = getSessionMessages()
persistent sessionMessages
if isempty(sessionMessages)
    sessionMessages = {};
end
messages = sessionMessages;
end

function setSessionMessages(messages)
persistent sessionMessages
sessionMessages = messages;
end

function tf = isTextScalarLike(value)
tf = ischar(value) || (isstring(value) && isscalar(value));
end
