function llm_state_clear()
%LLM_STATE_CLEAR Clear saved llmc session messages.

key = 'llm_session_messages';
if isappdata(0, key)
    rmappdata(0, key);
end

end
