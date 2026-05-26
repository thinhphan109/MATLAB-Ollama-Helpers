function messages = llm_state_get()
%LLM_STATE_GET Return saved llmc session messages.

key = 'llm_session_messages';

if isappdata(0, key)
    messages = getappdata(0, key);
else
    messages = {};
end

end
