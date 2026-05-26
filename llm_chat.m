function responseText = llm_chat(prompt, varargin)
%LLM_CHAT Context-aware local Ollama chat helper implementation.

promptText = string(prompt);

if strlength(strtrim(promptText)) == 0
    error('llm:EmptyPrompt', 'Prompt must not be empty.');
end

opts = parseChatOptions(varargin{:});
sessionMessages = llm_state_get();
sessionMessages{end + 1} = struct('role', 'user', 'content', char(promptText));

payload = struct( ...
    'model', char(opts.Model), ...
    'messages', {sessionMessages}, ...
    'stream', false);

requestOptions = weboptions( ...
    'MediaType', 'application/json', ...
    'Timeout', opts.Timeout);

try
    result = webwrite(char(opts.Url), payload, requestOptions);
catch err
    error('llm:RequestFailed', 'Ollama chat request failed: %s', err.message);
end

if isstruct(result) && isfield(result, 'message') && isstruct(result.message) && isfield(result.message, 'content')
    responseText = string(result.message.content);
else
    responseText = string(jsonencode(result));
end

sessionMessages{end + 1} = struct('role', 'assistant', 'content', char(responseText));
llm_state_set(sessionMessages);

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

function tf = isTextScalarLike(value)
tf = ischar(value) || (isstring(value) && isscalar(value));
end
