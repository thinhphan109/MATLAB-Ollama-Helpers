function info = llm_session()
%LLM_SESSION Show current context message count for llmc.

messages = llm_state_get();
info = struct('message_count', numel(messages));

if nargout == 0
    disp(info)
end

end
