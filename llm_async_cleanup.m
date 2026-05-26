function llm_async_cleanup(job)
%LLM_ASYNC_CLEANUP Remove temp files for a background Ollama request.

if nargin == 0 || isempty(job)
    return;
end

fields = {'JobFile', 'ResultFile', 'ErrorFile', 'LogFile'};
for index = 1:numel(fields)
    fieldName = fields{index};
    if ~isfield(job, fieldName)
        continue;
    end

    filePath = char(job.(fieldName));
    if exist(filePath, 'file') ~= 2
        continue;
    end

    try
        delete(filePath);
    catch
    end
end

if isfield(job, 'BaseDir')
    baseDir = char(job.BaseDir);
    if exist(baseDir, 'dir') == 7
        try
            entries = dir(baseDir);
            entries = entries(~ismember({entries.name}, {'.', '..'}));
            if isempty(entries)
                rmdir(baseDir);
            end
        catch
        end
    end
end

end
