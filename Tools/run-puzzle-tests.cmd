@echo off
rem Puzzle test runner: replays every puzzle's known solution and checks it wins.
rem
rem   Tools\run-puzzle-tests.cmd                      all puzzles, headless (~6 min)
rem   Tools\run-puzzle-tests.cmd --only=kraken        only matching puzzles (name or date)
rem   Tools\run-puzzle-tests.cmd --cards=scorch       only puzzles using a card
rem   Tools\run-puzzle-tests.cmd --report=out.json    also write a JSON report
rem   Tools\run-puzzle-tests.cmd watch --only=kraken  play it in a game window you can watch
rem
rem Exit code 0 = everything passed, 1 = at least one FAIL.
rem Works from cmd, PowerShell and Git Bash. Override the Godot folder with GODOT_DIR.
setlocal
set "ROOT=%~dp0.."
if "%GODOT_DIR%"=="" set "GODOT_DIR=C:\Tools\Godot"
set "GODOT=%GODOT_DIR%\Godot_v4.4.1-stable_win64_console.exe"
if not exist "%GODOT%" (
	echo Godot not found at "%GODOT%". Set GODOT_DIR to the folder containing it.
	exit /b 2
)

set "ARGS=%*"
if /i "%~1"=="watch" goto watch

"%GODOT%" --headless --path "%ROOT%" --fixed-fps 60 -- --puzzle-tests %ARGS%
exit /b %ERRORLEVEL%

:watch
rem Drop the leading "watch". (%1/shift would split "--only=x" at the "=".)
set "ARGS=%ARGS:*watch=%"
"%GODOT%" --path "%ROOT%" -- --puzzle-tests --speed=2 %ARGS%
exit /b %ERRORLEVEL%
