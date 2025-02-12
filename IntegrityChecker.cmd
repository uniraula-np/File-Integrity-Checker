@echo off
REM Get the directory where the .cmd file is located
set "SCRIPT_DIR=%~dp0"
REM Run the PowerShell script located in the same folder
powershell -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\Scripts\RunMe.ps1"