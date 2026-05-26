function matlab_ollama_panel()
%MATLAB_OLLAMA_PANEL Minimal in-MATLAB utility panel for local Ollama.

fig = uifigure( ...
    'Name', 'Panel', ...
    'Position', [120 120 320 300], ...
    'Resize', 'off', ...
    'Color', [0.97 0.97 0.98], ...
    'KeyPressFcn', @handleFigureKeyPress);

grid = uigridlayout(fig, [4 1]);
grid.Padding = [8 8 8 8];
grid.RowHeight = {80, 30, '1x', 28};
grid.RowSpacing = 6;

promptBox = uitextarea(grid, ...
    'Placeholder', 'Nhập nội dung...', ...
    'FontName', 'Consolas', ...
    'FontSize', 11, ...
    'ValueChangedFcn', @handlePromptChanged);
promptBox.Layout.Row = 1;

sendButton = uibutton(grid, ...
    'Text', 'Send', ...
    'ButtonPushedFcn', @sendPrompt);
sendButton.Layout.Row = 2;

outputBox = uitextarea(grid, ...
    'Editable', 'on', ...
    'FontName', 'Consolas', ...
    'FontSize', 11, ...
    'Value', "");
outputBox.Layout.Row = 3;

statusLabel = uilabel(grid, ...
    'Text', 'Sẵn sàng', ...
    'FontSize', 11, ...
    'HorizontalAlignment', 'left', ...
    'FontColor', [0.35 0.38 0.42]);
statusLabel.Layout.Row = 4;

lastPromptValue = "";

    function handlePromptChanged(~, ~)
        currentValue = string(promptBox.Value);
        if numel(currentValue) < numel(lastPromptValue)
            lastPromptValue = currentValue;
            return;
        end

        if numel(currentValue) >= 2
            if currentValue(end) == "" && currentValue(end - 1) == ""
                sendPrompt();
                lastPromptValue = string(promptBox.Value);
                return;
            end
        end

        lastPromptValue = currentValue;
    end

    function handleFigureKeyPress(~, event)
        if strcmp(event.Key, 'escape')
            fig.Visible = 'off';
        end
    end

    function sendPrompt(~, ~)
        promptText = strtrim(join(string(promptBox.Value), newline));

        if strlength(promptText) == 0
            setStatus('Nhập nội dung trước khi gửi.');
            return;
        end

        setBusy(true);
        setStatus('Đang gửi...');
        outputBox.Value = "";
        drawnow;

        try
            responseText = askllm_core(promptText);
            outputBox.Value = splitlines(responseText);
            promptBox.Value = "";
            lastPromptValue = "";
            setStatus('Xong');
        catch err
            outputBox.Value = splitlines(string(err.message));
            setStatus('Lỗi');
        end

        setBusy(false);
        focus(promptBox);
    end

    function setBusy(isBusy)
        if isBusy
            sendButton.Enable = 'off';
        else
            sendButton.Enable = 'on';
        end
    end

    function setStatus(message)
        statusLabel.Text = char(message);
        drawnow limitrate;
    end
end
