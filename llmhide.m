function llmhide()
%LLMHIDE Hide the dock-style local Ollama utility panel.

if isappdata(0, 'llm_dock_state')
    dockState = getappdata(0, 'llm_dock_state');
    if isfield(dockState, 'Timer') && ~isempty(dockState.Timer)
        stopAndDeleteTimer(dockState.Timer);
    end
    if isfield(dockState, 'Job') && ~isempty(dockState.Job)
        llm_async_cleanup(dockState.Job);
    end
    rmappdata(0, 'llm_dock_state');
end

if isappdata(0, 'llm_dock_figure')
    fig = getappdata(0, 'llm_dock_figure');
    if isvalid(fig)
        set(fig, 'Visible', 'off');
    end
end

end

function stopAndDeleteTimer(timerObj)
if isempty(timerObj)
    return;
end

try
    if isvalid(timerObj) && strcmp(timerObj.Running, 'on')
        stop(timerObj);
    end
catch
end

try
    if isvalid(timerObj)
        delete(timerObj);
    end
catch
end
end
