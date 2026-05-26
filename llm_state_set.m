function llm_state_set(messages)
%LLM_STATE_SET Save llmc session messages.

setappdata(0, 'llm_session_messages', messages);

end
