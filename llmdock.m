function llmdock()
%LLMDOCK Show or create the MATLAB Ollama helper window.
%   Requests are executed in a background MATLAB worker so the main
%   MATLAB session remains responsive while waiting for Ollama.

if isappdata(0, 'llm_dock_figure')
    fig = getappdata(0, 'llm_dock_figure');
    if isvalid(fig)
        set(fig, 'Visible', 'on');
        drawnow;
        return;
    end
end

matlab_ollama_dock();

end
