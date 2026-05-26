function status = llm_async_poll(job)
%LLM_ASYNC_POLL Poll a background Ollama request.

status = struct( ...
    'State', "running", ...
    'ResponseText', "", ...
    'ErrorText', "", ...
    'SessionMessages', {{}}, ...
    'IsFinished', false);

resultFile = char(job.ResultFile);
errorFile = char(job.ErrorFile);

if exist(resultFile, 'file')
    data = load(resultFile, 'responseText', 'sessionState');
    status.State = "done";
    status.ResponseText = string(data.responseText);
    if isfield(data, 'sessionState')
        status.SessionMessages = data.sessionState;
    end
    status.IsFinished = true;
    return;
end

if exist(errorFile, 'file')
    data = load(errorFile, 'errorMessage');
    status.State = "error";
    status.ErrorText = string(data.errorMessage);
    status.IsFinished = true;
end

end
