function llmhide()
%LLMHIDE Hide the dock-style local Ollama utility panel.

if isappdata(0, 'llm_dock_figure')
    fig = getappdata(0, 'llm_dock_figure');
    if isvalid(fig)
        set(fig, 'Visible', 'off');
    end
end

end
