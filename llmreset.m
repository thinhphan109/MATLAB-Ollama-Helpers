function message = llmreset()
%LLMRESET Clear saved context used by llmc.

llm_state_clear();
message = "Chat context cleared.";

if nargout == 0
    disp(message)
end

end
