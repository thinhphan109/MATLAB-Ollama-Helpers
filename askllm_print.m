function responseText = askllm_print(prompt, varargin)
%ASKLLM_PRINT Ask local Ollama and print the response to Command Window.
%
%   askllm_print(prompt)
%   resp = askllm_print(prompt)
%
% Example:
%   askllm_print("Explain this MATLAB code");

responseText = askllm_core(prompt, varargin{:});

fprintf('\n%s\n\n', char(responseText));

end
