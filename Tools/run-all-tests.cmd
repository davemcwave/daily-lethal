@echo off
rem Every test suite, one after another, with one summary at the end.
rem
rem   Tools\run-all-tests.cmd                     everything except card pairs (~10 min)
rem   Tools\run-all-tests.cmd --pairs             also every card followed by every card (+~18 min)
rem   Tools\run-all-tests.cmd --only=content,lab  just some suites: content, lab, effects, puzzles, pairs
rem
rem Exit code 0 = everything passed, 1 = something failed.
rem Works from cmd, PowerShell and Git Bash. Override the Godot folder with GODOT_DIR.
python "%~dp0run_all_tests.py" %*
exit /b %ERRORLEVEL%
