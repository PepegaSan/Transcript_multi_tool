@echo off
setlocal

echo [1/4] Check workspace...
if not exist "transcript.py" (
  echo ERROR: transcript.py not found in current folder.
  echo Please run this script from the github folder.
  exit /b 1
)

echo [2/4] Install/update dependencies...
python -m pip install -U pip
python -m pip install -r requirements.txt
python -m pip install pyinstaller

echo [3/4] Build onefile EXE...
pyinstaller --noconfirm --clean --onefile --windowed --name transcript ^
  --collect-all tkinterdnd2 ^
  --collect-all customtkinter ^
  --collect-data whisper ^
  --collect-submodules whisper ^
  transcript.py

if errorlevel 1 (
  echo ERROR: Build failed.
  exit /b 1
)

echo [4/4] Done.
echo Output: dist\transcript.exe
endlocal
