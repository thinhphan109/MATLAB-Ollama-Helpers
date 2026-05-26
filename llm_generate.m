function responseText = llm_generate(prompt, varargin)
%LLM_GENERATE Stateless local Ollama generate helper.

responseText = askllm_core(prompt, varargin{:});

end
