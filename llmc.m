function responseText = llmc(prompt, varargin)
%LLMC Context-aware local Ollama chat helper.
%
%   resp = llmc("first message")
%   resp = llmc("follow-up message")
%   llmreset

responseText = llm_chat(prompt, varargin{:});

if nargout == 0
    disp(responseText)
end

end
