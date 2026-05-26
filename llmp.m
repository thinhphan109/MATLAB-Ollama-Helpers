function responseText = llmp(prompt, varargin)
%LLMP Print local Ollama response directly to Command Window.

responseText = llm(prompt, varargin{:});

if nargout == 0
    return;
end

end
