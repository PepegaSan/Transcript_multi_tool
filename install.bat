@echo off
setlocal EnableExtensions
cd /d "%~dp0"

echo [1/6] Choose environment type
echo   0^) System Python ^(no env^)
echo   1^) Python venv ^(recommended^)
echo   2^) Conda env
set /p ENV_MODE=Select 0, 1 or 2 [default 1]: 
if not defined ENV_MODE set "ENV_MODE=1"

if "%ENV_MODE%"=="2" goto conda_mode
if "%ENV_MODE%"=="0" goto system_mode
goto venv_mode

:system_mode
echo [2/6] Using system Python...
set "PY_EXE=python"
"%PY_EXE%" -c "import sys; print(sys.version)"
if errorlevel 1 (
  echo ERROR: System Python not found in PATH.
  goto fail
)
set "START_MODE=SYSTEM"
goto install_requirements

:venv_mode
echo [2/6] Find compatible Python...
set "PY_ARG="
set "PY_VER="
py -3.11 -c "import sys" >nul 2>&1
if not errorlevel 1 set "PY_ARG=-3.11" & set "PY_VER=3.11"
if defined PY_ARG goto py_ok
py -3.10 -c "import sys" >nul 2>&1
if not errorlevel 1 set "PY_ARG=-3.10" & set "PY_VER=3.10"
if defined PY_ARG goto py_ok
py -3.9 -c "import sys" >nul 2>&1
if not errorlevel 1 set "PY_ARG=-3.9" & set "PY_VER=3.9"
if defined PY_ARG goto py_ok
echo ERROR: No compatible Python found.
echo Please install Python 3.9, 3.10, or 3.11 ^(with launcher^).
goto fail

:py_ok
echo Using Python %PY_VER%
echo.
echo [3/6] Select venv...
if exist ".venv\Scripts\python.exe" echo  - found .venv
if exist ".venv_py311\Scripts\python.exe" echo  - found .venv_py311
if exist ".venv_py310\Scripts\python.exe" echo  - found .venv_py310
if exist ".venv_py39\Scripts\python.exe" echo  - found .venv_py39
echo.

set "USE_EXISTING="
set /p USE_EXISTING=Use existing venv path? y/N: 
if /I "%USE_EXISTING%"=="y" goto use_existing_venv
goto create_new_venv

:use_existing_venv
set "VENV_DIR="
set /p VENV_DIR=Enter existing venv folder path (example .venv): 
if not defined VENV_DIR echo ERROR: No path entered.& goto fail
if not exist "%VENV_DIR%\Scripts\python.exe" echo ERROR: Not a valid venv: %VENV_DIR%& goto fail
goto venv_ready

:create_new_venv
set "VENV_NAME_INPUT="
set /p VENV_NAME_INPUT=Optional new venv name (Enter for auto): 
if not defined VENV_NAME_INPUT set "VENV_NAME_INPUT=.venv_py%PY_VER:.=%"
set "VENV_NAME_INPUT=%VENV_NAME_INPUT: =_%"
set "VENV_DIR=%VENV_NAME_INPUT%"
if exist "%VENV_DIR%\Scripts\python.exe" set "VENV_DIR=%VENV_DIR%_%RANDOM%"
echo Creating venv: %VENV_DIR%
py %PY_ARG% -m venv "%VENV_DIR%"
if errorlevel 1 echo ERROR: Could not create venv.& goto fail

:venv_ready
set "PY_EXE=%VENV_DIR%\Scripts\python.exe"
if not exist "%PY_EXE%" echo ERROR: Python executable not found in venv.& goto fail
set "START_MODE=PYTHON"
goto install_requirements

:conda_mode
echo [2/6] Find conda...
set "CONDA_CMD="
if defined CONDA_EXE set "CONDA_CMD=%CONDA_EXE%"
if not defined CONDA_CMD (
  where conda >nul 2>&1
  if not errorlevel 1 set "CONDA_CMD=conda"
)
if not defined CONDA_CMD if exist "%USERPROFILE%\miniconda3\Scripts\conda.exe" set "CONDA_CMD=%USERPROFILE%\miniconda3\Scripts\conda.exe"
if not defined CONDA_CMD if exist "%USERPROFILE%\MiniConda3\Scripts\conda.exe" set "CONDA_CMD=%USERPROFILE%\MiniConda3\Scripts\conda.exe"
if not defined CONDA_CMD if exist "%USERPROFILE%\anaconda3\Scripts\conda.exe" set "CONDA_CMD=%USERPROFILE%\anaconda3\Scripts\conda.exe"
if not defined CONDA_CMD if exist "%ProgramData%\miniconda3\Scripts\conda.exe" set "CONDA_CMD=%ProgramData%\miniconda3\Scripts\conda.exe"
if not defined CONDA_CMD if exist "%ProgramData%\MiniConda3\Scripts\conda.exe" set "CONDA_CMD=%ProgramData%\MiniConda3\Scripts\conda.exe"
if not defined CONDA_CMD if exist "%ProgramData%\anaconda3\Scripts\conda.exe" set "CONDA_CMD=%ProgramData%\anaconda3\Scripts\conda.exe"
if not defined CONDA_CMD (
  echo ERROR: Conda not found.
  echo Install Miniconda/Anaconda or add conda to PATH.
  goto fail
)
echo Using conda: %CONDA_CMD%
echo.
echo [3/6] Available conda envs:
"%CONDA_CMD%" env list
echo.
set /p CONDA_ENV_NAME=Enter existing env name to use (or press Enter to create new): 
if defined CONDA_ENV_NAME goto conda_env_selected

set "CONDA_ENV_NAME=transcript_py311"
set /p CONDA_ENV_NAME=New env name [default transcript_py311]: 
if not defined CONDA_ENV_NAME set "CONDA_ENV_NAME=transcript_py311"
echo Creating conda env %CONDA_ENV_NAME% with Python 3.11...
"%CONDA_CMD%" create -y -n "%CONDA_ENV_NAME%" python=3.11
if errorlevel 1 (
  echo Python 3.11 create failed. Trying Python 3.10...
  "%CONDA_CMD%" create -y -n "%CONDA_ENV_NAME%" python=3.10
  if errorlevel 1 (
    echo ERROR: Could not create conda env.
    goto fail
  )
)

:conda_env_selected
set "START_MODE=CONDA"
set "PY_EXE="
echo [4/6] Upgrade pip in conda env...
"%CONDA_CMD%" run -n "%CONDA_ENV_NAME%" python -m pip install --upgrade pip
if errorlevel 1 echo ERROR: pip upgrade failed in conda env.& goto fail
goto conda_install_requirements

:install_requirements
echo [4/6] Upgrade pip...
"%PY_EXE%" -m pip install --upgrade pip
if errorlevel 1 echo ERROR: pip upgrade failed.& goto fail

echo [5/6] Install requirements...
"%PY_EXE%" -m pip install -r requirements.txt
if errorlevel 1 echo ERROR: requirements install failed.& goto fail
goto save_config

:conda_install_requirements
echo [5/6] Install requirements...
"%CONDA_CMD%" run -n "%CONDA_ENV_NAME%" python -m pip install -r requirements.txt
if errorlevel 1 echo ERROR: requirements install failed in conda env.& goto fail

:save_config
echo [6/6] Save start config...
if /I "%START_MODE%"=="CONDA" (
  > ".python_for_start_gui.txt" echo conda:%CONDA_ENV_NAME%
) else (
  > ".python_for_start_gui.txt" echo %PY_EXE%
)

echo Save app defaults...
if /I "%START_MODE%"=="CONDA" (
  py -3 -c "import json, os; p='ui_settings.json'; d=json.load(open(p,'r',encoding='utf-8')) if os.path.exists(p) else {}; d['tts_runtime_mode']='conda_env'; d['tts_conda_env']=r'%CONDA_ENV_NAME%'; d['tts_python_path']=''; d['tts_enabled']=False; open(p,'w',encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=2))"
) else (
  "%PY_EXE%" -c "import json, os; p='ui_settings.json'; d=json.load(open(p,'r',encoding='utf-8')) if os.path.exists(p) else {}; d['tts_runtime_mode']='python_path'; d['tts_python_path']=r'%PY_EXE%'; d['tts_conda_env']=''; d['tts_enabled']=False; open(p,'w',encoding='utf-8').write(json.dumps(d, ensure_ascii=False, indent=2))"
)

echo.
echo Install complete.
if /I "%START_MODE%"=="CONDA" (
  echo Conda env: %CONDA_ENV_NAME%
) else (
  echo Venv: %VENV_DIR%
  echo Python: %PY_EXE%
)
echo Start with: start_gui.bat
goto end

:fail
echo.
echo Install failed.

:end
echo.
pause
endlocal
