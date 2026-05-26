function responseText = askllm(prompt, varargin)
%ASKLLM Ask local Ollama for a response and return it as text.
%
%   responseText = ASKLLM(prompt)
%   responseText = ASKLLM(prompt, 'Model', 'qwen2.5-coder:7b')
%   responseText = ASKLLM(prompt, 'Timeout', 240)
%
% Example:
%   resp = askllm("Write a MATLAB function for DFT");

responseText = askllm_core(prompt, varargin{:});

end
