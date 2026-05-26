function llmdock()
%LLMDOCK Show or create the dock-style local Ollama utility panel.

if isappdata(0, 'llm_dock_figure')
    fig = getappdata(0, 'llm_dock_figure');
    if isvalid(fig)
        set(fig, 'Visible', 'on');
        figure(fig);
        return;
    end
end

matlab_ollama_dock();

end
