function llmsetup()
%LLMSETUP Prepare MATLAB path and function resolution for local LLM helpers.

rootDir = fileparts(mfilename('fullpath'));
addpath(rootDir);
rehash;
clear functions;

fprintf('LLM helpers ready.\n');
fprintf('Path: %s\n', rootDir);
fprintf('Commands: llm help | llm("prompt") | llmp("prompt") | llmc("prompt") | llmdock\n');

end
