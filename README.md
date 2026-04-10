# Smart Transcript & DaVinci Cutter

Desktop app for:
- Whisper transcription
- text filtering/replacement
- text export/translation
- DaVinci Resolve export (cut timeline/render)
- FFmpeg export (silence/beep replacement)
- local TTS MP3 export

## UI

![App UI](UI.png)

## Files in this folder

- `transcript.py` - main app
- `requirements.txt` - Python dependencies
- `LICENSE` - GNU GPL v3

## Install

```bash
python -m venv .venv
.venv\Scripts\activate
pip install -r requirements.txt
python transcript.py
```

### Build on Windows with batch scripts

Run these files in this folder:

- `build_onefile.bat` -> creates `dist\transcript.exe`
- `build_onedir.bat` -> creates `dist\transcript\`

Why both options:

- `onefile`: single EXE, easiest to share/download
- `onedir`: usually more stable for large ML stacks and often faster startup

## Notes

- FFmpeg/ffprobe should be available in `PATH`.
- DaVinci Resolve API export requires Resolve running with an open project.
- Optional: set a custom `DaVinciResolveScript.py` path in Tab 4 if auto-import fails.
- CUDA is optional. If unavailable, app falls back to CPU.

## Build as EXE (PyInstaller)

Example (PowerShell):

```bash
pip install pyinstaller
pyinstaller --onefile --noconsole transcript.py
```

For large ML dependencies, `--onedir` is often more stable and starts faster than `--onefile`.

Both batch scripts include:
- `--collect-all tkinterdnd2`
- `--collect-all customtkinter`
- `--collect-data whisper`
- `--collect-submodules whisper`

This avoids common EXE runtime issues like missing `whisper/assets/mel_filters.npz`.

