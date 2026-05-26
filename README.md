# MATLAB Ollama Helpers

Local MATLAB helpers for sending prompts to Ollama and receiving responses without leaving MATLAB.

## Quick start

```matlab
addpath('C:\Users\Thinh Phan\.gemini\antigravity\scratch\matlab_ollama_panel')
llmsetup
```

## Main commands

```matlab
llm help
llm("single prompt")
llmp("print response")
llmc("context chat")
llm session
llmreset
llmdock
llmhide
llmclean
```

## Recommended usage

### One-shot response

```matlab
resp = llm("Write a MATLAB function for DFT")
```

### Print directly to Command Window

```matlab
llmp("Explain this MATLAB code")
```

### Context-aware chat

```matlab
llmc("I am writing FFT code")
llmc("Now add plotting")
llm session
llmreset
```

### Helper window

```matlab
llmdock
```

Keyboard in helper window:
- `Ctrl+Enter` = send
- `Enter` = newline
- `Esc` = hide

Helper window behavior:
- It is still a MATLAB window, not a separate app.
- It stays separate from normal plotting figures instead of sharing the docked `Figures` area.
- `Single` mode sends a one-shot request.
- `Chat` mode uses the same persistent context model as `llmc`.
- Requests run in a background MATLAB worker, so the main MATLAB session should remain usable while waiting.
- Output stays editable so you can trim and copy only the lines you want.
- `Reset Chat` clears the saved chat context used by `Chat` mode and `llmc`.

## Notes

- `llm` and `llmp` are stateless.
- `llmc` keeps local context until `llmreset`.
- `llmhide` hides the helper window and clears active polling state.
- `llmclean` runs `clc`, resets context, and hides the helper window.
- All requests go directly to local Ollama.
