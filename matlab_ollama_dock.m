function matlab_ollama_dock()
%MATLAB_OLLAMA_DOCK Standalone local Ollama helper window for MATLAB.
%   Keyboard:
%   - Ctrl+Enter: send
%   - Enter in prompt: newline
%   - Escape: hide

fig = figure( ...
    'Name', 'LLM Helper', ...
    'NumberTitle', 'off', ...
    'MenuBar', 'none', ...
    'ToolBar', 'none', ...
    'DockControls', 'off', ...
    'WindowStyle', 'normal', ...
    'HandleVisibility', 'callback', ...
    'IntegerHandle', 'off', ...
    'Color', [0.97 0.97 0.98], ...
    'Position', [120 120 430 520], ...
    'Resize', 'on', ...
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
    'Callback', @hideDock);

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
        if ~isDockAlive()
            return;
        end

        modifiers = string(event.Modifier);

        if strcmp(event.Key, 'escape')
            hideDock();
            return;
        end

        if any(modifiers == "control") && (strcmp(event.Key, 'return') || strcmp(event.Key, 'enter'))
            sendPrompt();
        end
    end

    function sendPrompt(~, ~)
        if ~isDockAlive()
            return;
        end

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
            safeSetString(outputEdit, err.message);
            return;
        end

        pollTimer = timer( ...
            'ExecutionMode', 'fixedSpacing', ...
            'Period', 0.4, ...
            'BusyMode', 'drop', ...
            'TimerFcn', @pollRequest);

        dockState.Job = job;
        dockState.Timer = pollTimer;
        dockState.Busy = true;
        setDockState(dockState);

        setBusy(true);
        safeSetString(outputEdit, '');
        setStatus(sprintf('Running %s...', char(requestMode)));
        start(pollTimer);
    end

    function pollRequest(~, ~)
        if ~isDockAlive()
            stopTimerFromState();
            return;
        end

        dockState = getDockState();
        if ~dockState.Busy || isempty(dockState.Job)
            stopTimerFromState();
            return;
        end

        status = llm_async_poll(dockState.Job);
        if ~status.IsFinished
            return;
        end

        if status.State == "done"
            safeSetString(outputEdit, cellstr(splitlines(status.ResponseText)));
            if ~isempty(status.SessionMessages)
                llm_state_set(status.SessionMessages);
            end
            if isgraphics(promptEdit)
                set(promptEdit, 'String', '');
            end
            setStatus('Done');
        else
            safeSetString(outputEdit, cellstr(splitlines(status.ErrorText)));
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
        if isgraphics(promptEdit)
            uicontrol(promptEdit);
        end
    end

    function resetChatState(~, ~)
        if ~isDockAlive()
            return;
        end

        if getDockState().Busy
            setStatus('Wait for the current request to finish.');
            return;
        end

        llm_state_clear();
        setStatus('Chat state reset');
    end

    function hideDock(~, ~)
        dockState = getDockState();
        if ~isempty(dockState.Timer)
            stopAndDeleteTimer(dockState.Timer);
        end
        if ~isempty(dockState.Job)
            llm_async_cleanup(dockState.Job);
        end
        dockState.Timer = [];
        dockState.Job = [];
        dockState.Busy = false;
        setDockState(dockState);
        if isgraphics(fig)
            set(fig, 'Visible', 'off');
        end
    end

    function handleFigureDelete(~, ~)
        hideDock();
        if isappdata(0, 'llm_dock_state')
            rmappdata(0, 'llm_dock_state');
        end
        if isappdata(0, 'llm_dock_figure')
            rmappdata(0, 'llm_dock_figure');
        end
    end

    function tf = isDockAlive()
        tf = isgraphics(fig) && isgraphics(promptEdit) && isgraphics(outputEdit) ...
            && isgraphics(statusText) && isgraphics(sendButton) && isgraphics(resetButton) ...
            && isgraphics(modePopup);
    end

    function setBusy(isBusy)
        if ~isDockAlive()
            return;
        end

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
        if isgraphics(statusText)
            set(statusText, 'String', char(message));
            drawnow limitrate;
        end
    end

    function safeSetString(handleObj, value)
        if isgraphics(handleObj)
            set(handleObj, 'String', value);
        end
    end

    function stopTimerFromState()
        dockState = getDockState();
        if isfield(dockState, 'Timer') && ~isempty(dockState.Timer)
            stopAndDeleteTimer(dockState.Timer);
            dockState.Timer = [];
            dockState.Busy = false;
            dockState.Job = [];
            setDockState(dockState);
        end
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
