function matlab_ollama_dock()
%MATLAB_OLLAMA_DOCK Prototype dock-style local Ollama helper.
%   Keyboard:
%   - Ctrl+Enter: send
%   - Enter in prompt: newline
%   - Escape: hide

fig = figure( ...
    'Name', 'Utility', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'DockControls', 'on', ...
    'WindowStyle', 'docked', ...
    'Color', [0.97 0.97 0.98], ...
    'WindowKeyPressFcn', @handleFigureKeyPress, ...
    'DeleteFcn', @handleFigureDelete);

panel = uipanel( ...
    'Parent', fig, ...
    'Units', 'normalized', ...
    'Position', [0 0 1 1], ...
    'BorderType', 'none', ...
    'BackgroundColor', [0.97 0.97 0.98]);

promptEdit = uicontrol( ...
    'Parent', panel, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'Position', [0.03 0.72 0.94 0.25], ...
    'Max', 2, ...
    'Min', 0, ...
    'HorizontalAlignment', 'left', ...
    'FontName', 'Consolas', ...
    'FontSize', 10, ...
    'String', '');

modePopup = uicontrol( ...
    'Parent', panel, ...
    'Style', 'popupmenu', ...
    'Units', 'normalized', ...
    'Position', [0.03 0.67 0.28 0.04], ...
    'String', {'Single', 'Chat'}, ...
    'Value', 1, ...
    'BackgroundColor', [1 1 1]);

hintText = uicontrol( ...
    'Parent', panel, ...
    'Style', 'text', ...
    'Units', 'normalized', ...
    'Position', [0.33 0.67 0.64 0.04], ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', [0.97 0.97 0.98], ...
    'ForegroundColor', [0.45 0.47 0.50], ...
    'FontSize', 8, ...
    'String', 'Ctrl+Enter = Send | Enter = newline | Esc = hide');

sendButton = uicontrol( ...
    'Parent', panel, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [0.03 0.58 0.30 0.08], ...
    'String', 'Send', ...
    'Callback', @sendPrompt);

resetButton = uicontrol( ...
    'Parent', panel, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [0.35 0.58 0.30 0.08], ...
    'String', 'Reset Chat', ...
    'Callback', @resetChatState);

hideButton = uicontrol( ...
    'Parent', panel, ...
    'Style', 'pushbutton', ...
    'Units', 'normalized', ...
    'Position', [0.67 0.58 0.30 0.08], ...
    'String', 'Hide', ...
    'Callback', @(~, ~) set(fig, 'Visible', 'off'));

outputEdit = uicontrol( ...
    'Parent', panel, ...
    'Style', 'edit', ...
    'Units', 'normalized', ...
    'Position', [0.03 0.10 0.94 0.45], ...
    'Max', 2, ...
    'Min', 0, ...
    'HorizontalAlignment', 'left', ...
    'FontName', 'Consolas', ...
    'FontSize', 10, ...
    'Enable', 'on', ...
    'String', '');

statusText = uicontrol( ...
    'Parent', panel, ...
    'Style', 'text', ...
    'Units', 'normalized', ...
    'Position', [0.03 0.02 0.94 0.06], ...
    'HorizontalAlignment', 'left', ...
    'BackgroundColor', [0.97 0.97 0.98], ...
    'ForegroundColor', [0.35 0.38 0.42], ...
    'FontSize', 9, ...
    'String', 'Ready');

state = struct('Job', [], 'Timer', [], 'Busy', false);
setappdata(0, 'llm_dock_figure', fig);
setappdata(0, 'llm_dock_state', state);

    function handleFigureKeyPress(~, event)
        modifiers = string(event.Modifier);

        if strcmp(event.Key, 'escape')
            set(fig, 'Visible', 'off');
            return;
        end

        if any(modifiers == "control") && (strcmp(event.Key, 'return') || strcmp(event.Key, 'enter'))
            sendPrompt();
        end
    end

    function sendPrompt(~, ~)
        dockState = getDockState();
        if dockState.Busy
            setStatus('A request is already running...');
            return;
        end

        rawPrompt = string(get(promptEdit, 'String'));
        promptText = strtrim(join(rawPrompt, newline));

        if strlength(promptText) == 0
            setStatus('Empty prompt');
            return;
        end

        modeOptions = string(get(modePopup, 'String'));
        selectedMode = lower(modeOptions(get(modePopup, 'Value')));
        requestMode = "single";
        sessionMessages = {};
        if selectedMode == "chat"
            requestMode = "chat";
            sessionMessages = llm_state_get();
        end

        try
            job = llm_async_start(promptText, ...
                'Mode', requestMode, ...
                'SessionMessages', sessionMessages);
        catch err
            setStatus('Failed to launch worker');
            set(outputEdit, 'String', err.message);
            return;
        end

        pollTimer = timer( ...
            'ExecutionMode', 'fixedSpacing', ...
            'Period', 0.4, ...
            'BusyMode', 'drop', ...
            'TimerFcn', @pollRequest, ...
            'StopFcn', @cleanupTimer);

        dockState.Job = job;
        dockState.Timer = pollTimer;
        dockState.Busy = true;
        setDockState(dockState);

        setBusy(true);
        set(outputEdit, 'String', '');
        setStatus(sprintf('Running %s...', char(requestMode)));
        start(pollTimer);
    end

    function pollRequest(~, ~)
        dockState = getDockState();
        if ~dockState.Busy || isempty(dockState.Job)
            return;
        end

        status = llm_async_poll(dockState.Job);
        if ~status.IsFinished
            return;
        end

        if status.State == "done"
            set(outputEdit, 'String', cellstr(splitlines(status.ResponseText)));
            if ~isempty(status.SessionMessages)
                llm_state_set(status.SessionMessages);
            end
            set(promptEdit, 'String', '');
            setStatus('Done');
        else
            set(outputEdit, 'String', cellstr(splitlines(status.ErrorText)));
            setStatus('Error');
        end

        llm_async_cleanup(dockState.Job);
        dockState.Busy = false;
        dockState.Job = [];
        setDockState(dockState);
        stopAndDeleteTimer(dockState.Timer);
        dockState.Timer = [];
        setDockState(dockState);
        setBusy(false);
        uicontrol(promptEdit);
    end

    function resetChatState(~, ~)
        if getDockState().Busy
            setStatus('Wait for the current request to finish.');
            return;
        end

        llm_state_clear();
        setStatus('Chat state reset');
    end

    function cleanupTimer(timerObj, ~)
        if isempty(timerObj) || ~isvalid(timerObj)
            return;
        end
    end

    function handleFigureDelete(~, ~)
        dockState = getDockState();
        if ~isempty(dockState.Timer)
            stopAndDeleteTimer(dockState.Timer);
        end
        if ~isempty(dockState.Job)
            llm_async_cleanup(dockState.Job);
        end
        if isappdata(0, 'llm_dock_state')
            rmappdata(0, 'llm_dock_state');
        end
        if isappdata(0, 'llm_dock_figure')
            rmappdata(0, 'llm_dock_figure');
        end
    end

    function setBusy(isBusy)
        if isBusy
            set(sendButton, 'Enable', 'off');
            set(resetButton, 'Enable', 'off');
            set(modePopup, 'Enable', 'off');
        else
            set(sendButton, 'Enable', 'on');
            set(resetButton, 'Enable', 'on');
            set(modePopup, 'Enable', 'on');
        end
    end

    function setStatus(message)
        set(statusText, 'String', char(message));
        drawnow limitrate;
    end

    function dockState = getDockState()
        if isappdata(0, 'llm_dock_state')
            dockState = getappdata(0, 'llm_dock_state');
        else
            dockState = struct('Job', [], 'Timer', [], 'Busy', false);
        end
    end

    function setDockState(dockState)
        setappdata(0, 'llm_dock_state', dockState);
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
