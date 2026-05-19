@echo off
setlocal
title GardenSnap Prototype

set "ROOT=%~dp0"
set "NODE_EXE=C:\Program Files\nodejs\node.exe"

where node >nul 2>nul
if %ERRORLEVEL%==0 set "NODE_EXE=node"

if not exist "%ROOT%prototype\index.html" (
  echo Could not find the prototype files.
  pause
  exit /b 1
)

if not exist "%NODE_EXE%" if not "%NODE_EXE%"=="node" (
  echo Could not find Node.js on this machine.
  pause
  exit /b 1
)

for /f "tokens=5" %%P in ('netstat -ano ^| findstr /R /C:":5173 .*LISTENING"') do (
  echo Stopping old GardenSnap server on port 5173...
  taskkill /PID %%P /F >nul 2>nul
)

start "" "http://127.0.0.1:5173"
"%NODE_EXE%" "%ROOT%scripts\serve-prototype.js"

endlocal
