function llm_async_worker(jobFile)
%LLM_ASYNC_WORKER Background worker for llmdock requests.

job = load(jobFile, 'job');
jobData = job.job;

try
    mode = string(jobData.Mode);
    promptText = string(jobData.Prompt);

    if mode == "chat"
        sessionMessages = jobData.SessionMessages;
        sessionMessages{end + 1} = struct('role', 'user', char(promptText));

        payload = struct( ...
            'model', char(jobData.Model), ...
            'messages', {sessionMessages}, ...
            'stream', false);

        requestOptions = weboptions( ...
            'MediaType', 'application/json', ...
            'Timeout', jobData.Timeout);

        result = webwrite(char(jobData.ChatUrl), payload, requestOptions);

        if isstruct(result) && isfield(result, 'message') && isstruct(result.message) && isfield(result.message, 'content')
            responseText = string(result.message.content);
        else
            responseText = string(jsonencode(result));
        end

        sessionMessages{end + 1} = struct('role', 'assistant', char(responseText));
        sessionState = sessionMessages;
    else
        responseText = askllm_core(promptText, ...
            'Model', jobData.Model, ...
            'Url', jobData.GenerateUrl, ...
            'Timeout', jobData.Timeout);
        sessionState = {};
    end

    save(jobData.ResultFile, 'responseText', 'sessionState', '-mat');
catch err
    errorMessage = string(getReport(err, 'basic', 'hyperlinks', 'off'));
    save(jobData.ErrorFile, 'errorMessage', '-mat');
end

end
