function responseText = askllm_core(prompt, varargin)
%ASKLLM_CORE Send a prompt to local Ollama and return response text.
%
%   responseText = ASKLLM_CORE(prompt)
%   responseText = ASKLLM_CORE(prompt, 'Model', 'qwen2.5-coder:7b', 'Timeout', 180)

arguments
    prompt {mustBeTextScalar}
end

arguments (Repeating)
    varargin
end

opts = parseOptions(varargin{:});
promptText = string(prompt);

if strlength(strtrim(promptText)) == 0
    error('askllm:EmptyPrompt', 'Prompt must not be empty.');
end

payload = struct( ...
    'model', char(opts.Model), ...
    'prompt', char(promptText), ...
    'stream', false);

requestOptions = weboptions( ...
    'MediaType', 'application/json', ...
    'Timeout', opts.Timeout);

try
    result = webwrite(char(opts.Url), payload, requestOptions);
catch err
    error('askllm:RequestFailed', 'Ollama request failed: %s', err.message);
end

if isstruct(result) && isfield(result, 'response')
    responseText = string(result.response);
else
    responseText = string(jsonencode(result));
end

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'askllm_core';
addParameter(parser, 'Model', "qwen2.5-coder:7b", @isTextScalarLike);
addParameter(parser, 'Url', "http://localhost:11434/api/generate", @isTextScalarLike);
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

function mustBeTextScalar(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error('askllm:InvalidPromptType', 'Prompt must be a char vector or string scalar.');
end
end
