function responseText = llm(prompt, varargin)
%LLM Short local Ollama helper.
%
%   resp = llm("prompt")
%   txt = llm("help")
%
% Commands:
%   llm("help")
%   llm("session")
%   llm("reset")

promptText = string(prompt);
commandText = lower(strtrim(promptText));

if commandText == "help"
    responseText = llm_core("help");
    disp(responseText)
    return;
elseif commandText == "reset"
    responseText = llmreset();
    return;
elseif commandText == "session"
    responseText = llm_session();
    if nargout == 0
        disp(responseText)
    end
    return;
end

responseText = llm_generate(promptText, varargin{:});

if nargout == 0
    disp(responseText)
end

end
