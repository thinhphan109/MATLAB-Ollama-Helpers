function job = llm_async_start(promptText, varargin)
%LLM_ASYNC_START Start a background Ollama request for llmdock.

arguments
    promptText {mustBeTextScalar}
end

arguments (Repeating)
    varargin
end

opts = parseOptions(varargin{:});
jobId = char(string(java.util.UUID.randomUUID()));
baseDir = fullfile(tempdir, 'matlab_ollama_jobs', jobId);
if ~exist(baseDir, 'dir')
    mkdir(baseDir);
end

jobFile = fullfile(baseDir, 'job.mat');
resultFile = fullfile(baseDir, 'result.mat');
errorFile = fullfile(baseDir, 'error.mat');
logFile = fullfile(baseDir, 'worker.log');
projectDir = fileparts(mfilename('fullpath'));

job = struct( ...
    'Id', string(jobId), ...
    'BaseDir', string(baseDir), ...
    'JobFile', string(jobFile), ...
    'ResultFile', string(resultFile), ...
    'ErrorFile', string(errorFile), ...
    'LogFile', string(logFile), ...
    'Mode', opts.Mode, ...
    'Prompt', string(promptText), ...
    'Model', opts.Model, ...
    'Timeout', opts.Timeout, ...
    'GenerateUrl', opts.GenerateUrl, ...
    'ChatUrl', opts.ChatUrl, ...
    'SessionMessages', {opts.SessionMessages});

save(jobFile, 'job', '-mat');

matlabExe = findMatlabExecutable();
workerCommand = sprintf('addpath(''%s''); llm_async_worker(''%s''); exit', ...
    escapeSingleQuotes(projectDir), escapeSingleQuotes(jobFile));
command = sprintf('start "" /B "%s" -batch "%s" > "%s" 2>&1', ...
    matlabExe, workerCommand, char(job.LogFile));
status = system(command);

if status ~= 0
    error('llm:AsyncStartFailed', 'Failed to start background MATLAB worker.');
end

end

function opts = parseOptions(varargin)
parser = inputParser;
parser.FunctionName = 'llm_async_start';
addParameter(parser, 'Mode', "single", @isTextScalarLike);
addParameter(parser, 'Model', "qwen2.5-coder:7b", @isTextScalarLike);
addParameter(parser, 'Timeout', 180, @(x) validateattributes(x, {'numeric'}, {'scalar', 'positive'}));
addParameter(parser, 'GenerateUrl', "http://localhost:11434/api/generate", @isTextScalarLike);
addParameter(parser, 'ChatUrl', "http://localhost:11434/api/chat", @isTextScalarLike);
addParameter(parser, 'SessionMessages', {}, @iscell);
parse(parser, varargin{:});

opts = struct( ...
    'Mode', string(parser.Results.Mode), ...
    'Model', string(parser.Results.Model), ...
    'Timeout', parser.Results.Timeout, ...
    'GenerateUrl', string(parser.Results.GenerateUrl), ...
    'ChatUrl', string(parser.Results.ChatUrl), ...
    'SessionMessages', {parser.Results.SessionMessages});
end

function matlabExe = findMatlabExecutable()
matlabExe = '';
[candidateStatus, candidatePath] = system('where matlab');
if candidateStatus == 0
    parts = regexp(strtrim(candidatePath), '[\r\n]+', 'split');
    if ~isempty(parts)
        matlabExe = parts{1};
    end
end

if isempty(matlabExe)
    fallback = 'D:\MATLAB\R2024a\bin\matlab.exe';
    if exist(fallback, 'file')
        matlabExe = fallback;
    end
end

if isempty(matlabExe)
    error('llm:MatlabNotFound', 'Could not locate matlab.exe for background worker.');
end
end

function text = escapeSingleQuotes(text)
text = strrep(char(text), '''', '''''');
end

function tf = isTextScalarLike(value)
tf = ischar(value) || (isstring(value) && isscalar(value));
end

function mustBeTextScalar(value)
if ~(ischar(value) || (isstring(value) && isscalar(value)))
    error('llm:InvalidPromptType', 'Prompt must be a char vector or string scalar.');
end
end
