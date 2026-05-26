# MATLAB Ollama Helpers

Local MATLAB helpers for sending prompts to Ollama and receiving responses without leaving MATLAB.

## Quick start

```matlab
addpath('...\matlab_ollama_panel')
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

### Docked helper panel

```matlab
llmdock
```

Keyboard in dock panel:
- `Ctrl+Enter` = send
- `Enter` = newline
- `Esc` = hide

## Notes

- `llm` and `llmp` are stateless.
- `llmc` keeps local context until `llmreset`.
- `llmclean` runs `clc`, resets context, and hides the dock panel.
- Output areas in the MATLAB panels are editable so you can trim and copy only the text you need.
- All requests go directly to local Ollama.
